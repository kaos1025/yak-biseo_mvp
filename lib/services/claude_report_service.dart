import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/supplecut_analysis_result.dart';

/// API 에러 (4xx/5xx)
class ClaudeApiException implements Exception {
  final int statusCode;
  final String message;
  ClaudeApiException(this.statusCode, this.message);
  @override
  String toString() => 'ClaudeApiException($statusCode): $message';
}

/// 네트워크 연결 에러
class ClaudeNetworkException implements Exception {
  final String message;
  ClaudeNetworkException(this.message);
  @override
  String toString() => 'ClaudeNetworkException: $message';
}

/// 타임아웃 에러
class ClaudeTimeoutException implements Exception {
  @override
  String toString() => 'ClaudeTimeoutException: Request timed out';
}

/// Claude 유료 상세 리포트 서비스
///
/// Gemini 1차 분석 결과를 기반으로 Claude에게 심층 분석 리포트를 요청한다.
/// IAP 결제 완료 후에만 호출.
class ClaudeReportService {
  late final String _apiKey;
  final String _model = 'claude-sonnet-4-5';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const int _maxImageBytes = 3700000; // base64 후 ~5MB

  ClaudeReportService() {
    final key = dotenv.env['CLAUDE_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception('CLAUDE_API_KEY not found in .env');
    }
    _apiKey = key;
  }

  /// 상세 리포트 스트리밍 생성
  ///
  /// SSE 청크 단위로 텍스트를 yield한다.
  /// [result] Gemini 1차 분석 결과
  /// [imageBytes] 원본 이미지 (선택 — 있으면 Claude에 전달)
  /// [locale] "ko" 또는 "en"
  Stream<String> generateReportStream(
    SuppleCutAnalysisResult result, {
    Uint8List? imageBytes,
    String locale = 'ko',
  }) async* {
    final analysisJson = jsonEncode(result.toJson());
    final exclusionContext = _buildExclusionContext(result);
    final prompt = _buildPrompt(analysisJson, locale, exclusionContext);

    final content = <Map<String, dynamic>>[];

    if (imageBytes != null) {
      final resized = _resizeIfNeeded(imageBytes);
      final base64Data = base64Encode(resized);
      content.add({
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/jpeg',
          'data': base64Data,
        },
      });
    }

    content.add({
      'type': 'text',
      'text': prompt,
    });

    final request = http.Request('POST', Uri.parse(_apiUrl));
    request.headers.addAll({
      'x-api-key': _apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    });
    request.body = jsonEncode({
      'model': _model,
      'max_tokens': 3000,
      'stream': true,
      'messages': [
        {'role': 'user', 'content': content},
      ],
    });

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request).timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw ClaudeTimeoutException());

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw ClaudeApiException(streamedResponse.statusCode,
            errorBody.substring(0, 200.clamp(0, errorBody.length)));
      }

      String lineBuf = '';
      final sseStream = streamedResponse.stream.transform(utf8.decoder).timeout(
          const Duration(seconds: 60),
          onTimeout: (sink) => throw ClaudeTimeoutException());

      await for (final chunk in sseStream) {
        lineBuf += chunk;
        final lines = lineBuf.split('\n');
        lineBuf = lines.removeLast();

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') continue;

          try {
            final event = jsonDecode(data) as Map<String, dynamic>;
            final type = event['type'] as String? ?? '';

            if (type == 'content_block_delta') {
              final delta = event['delta'] as Map<String, dynamic>?;
              final text = delta?['text'] as String? ?? '';
              if (text.isNotEmpty) yield text;
            } else if (type == 'message_stop') {
              return;
            }
          } catch (_) {
            // JSON 파싱 실패한 라인은 무시
          }
        }
      }
    } on ClaudeApiException {
      rethrow;
    } on ClaudeTimeoutException {
      rethrow;
    } on SocketException catch (e) {
      throw ClaudeNetworkException(e.message);
    } on http.ClientException catch (e) {
      throw ClaudeNetworkException(e.message);
    } finally {
      client.close();
    }
  }

  /// 이미지 리사이즈 (base64 후 5MB 제한 대응)
  Uint8List _resizeIfNeeded(Uint8List imageBytes) {
    if (imageBytes.length <= _maxImageBytes) return imageBytes;

    // 간단한 JPEG quality 축소 — image 패키지 없이 원본 크기 기준으로 판단
    // 실제로는 이미지 디코딩/인코딩이 필요하지만,
    // Flutter에서는 무거운 작업이므로 원본이 큰 경우 경고만 하고 전송
    // TODO: image 패키지 추가 시 실제 리사이즈 구현
    return imageBytes;
  }

  /// 가격표 + 제외 권장 정보를 프롬프트 컨텍스트로 변환
  String _buildExclusionContext(SuppleCutAnalysisResult result) {
    final buffer = StringBuffer();

    // ── 제품별 월비용 가격표 (항상 삽입) ──
    buffer.writeln('\n## Product Monthly Costs (USD)');
    for (final p in result.products) {
      final shortName = p.name.split(',').take(2).join(',').trim();
      buffer
          .writeln('- $shortName: \$${p.monthlyCostUsd.toStringAsFixed(2)}/mo');
    }

    // ── 제외 추천 (있을 때만) ──
    final ex = result.exclusionResult;
    if (ex != null && ex.hasExclusion) {
      // Critical Safety — 즉시 중단 (절감액 무관)
      final critical = ex.criticalStopItems;
      if (critical.isNotEmpty) {
        buffer.writeln('\n## Critical Safety — Discontinue Immediately');
        buffer.writeln(
            'These products must be discontinued for safety reasons. They are NOT included in savings calculations.');
        for (final item in critical) {
          final shortName = item.product.split(',').take(2).join(',').trim();
          buffer.writeln('- $shortName: ${item.reason}');
        }
      }

      // Medical Supervision — 치료제 (절감액 무관)
      final medical = ex.medicalSupervisionItems;
      if (medical.isNotEmpty) {
        buffer.writeln('\n## Medical Supervision Required');
        buffer.writeln(
            'These therapeutic-dose products require physician oversight. Do NOT recommend discontinuation. They are NOT included in savings calculations.');
        for (final item in medical) {
          final shortName = item.product.split(',').take(2).join(',').trim();
          buffer.writeln('- $shortName: ${item.reason}');
        }
      }

      // Recommended Removal — 절감 대상
      final savings = ex.savingsItems;
      if (savings.isNotEmpty) {
        buffer.writeln('\n## Pre-determined Removal Recommendation');
        buffer.writeln('Products to remove (cost savings):');
        for (final item in savings) {
          final shortName = item.product.split(',').take(2).join(',').trim();
          buffer.writeln('- $shortName');
        }
        buffer.writeln(
            'Monthly savings: \$${ex.monthlySavings.toStringAsFixed(2)}');
        buffer.writeln(
            'Annual savings: \$${ex.annualSavings.toStringAsFixed(2)}');
        buffer.writeln(
            'NOTE: These savings already exclude critical safety items. Use these exact amounts — do NOT recalculate.');
      }
    }

    return buffer.toString();
  }

  String _buildPrompt(
      String analysisJson, String locale, String exclusionContext) {
    return '''
You are a licensed pharmacist and supplement cost analyst.
Analyze the data below and produce a concise **Premium Report**.

## Analysis Data (JSON)
$analysisJson
$exclusionContext

## Report Structure (5 sections only)

### 1. Stack Overview
One Markdown table with EXACTLY 3 columns: Product | Key Ingredients | Price
- Do NOT add Src, Source, or any other columns

### 2. Overlap & UL Check
- For each overlapping ingredient: combined daily intake vs UL, verdict (SAFE / CAUTION / WARNING)
- If no overlaps: "No concerning overlaps detected." — one line, move on

### 3. Safety Alerts
- Only include this section if there are real risks
- Combine mechanism overlaps (blood clotting, serotonin, etc.) and drug interactions here
- For potential prescription drug interactions (e.g., 5-HTP + SSRIs), use conditional language: "If you are NOT taking [drug class], [supplement] can be continued safely. If you are taking [drug class], discontinue immediately."
- If nothing to flag, skip this section entirely

### 4. What to Cut
- Use ONLY the pre-determined exclusion list provided above
- Explain WHY those products should be excluded (3-line reason per product)
- Show the exact monthly and yearly savings from the provided data
- Remaining stack summary after removal
- If a removed product is the ONLY source of a nutrient, add a one-line note: "Note: Removing [Product] also removes your only source of [Nutrient] ([dose]). Consider dietary sources or a standalone supplement if needed."
- If no products are flagged for exclusion, state: "No products flagged for removal. Your current stack is well-optimized."

### 5. How to Take
- Morning vs evening timing only, keep it brief

## Rules
- Language: English only
- Format: pure Markdown text, NOT JSON
- Start directly with `## AI Detailed Analysis Report` — no greetings
- Number sections: `### 1.`, `### 2.`, etc.
- Use specific figures (mg, IU, UL values)
- Use bullet points, not paragraphs
- Total response under 1500 words
- Do NOT include dietary alternatives, recipes, or exercise advice
- Do NOT repeat the same risk across multiple sections
- Do NOT use academic tone like "Evidence shows..." or "Studies suggest..."
- Be direct and concise
- Always use USD (\$) for all prices

## Severity Rules
- Respect the overall_status from the analysis data — if "warning", maintain HIGH RISK tone throughout
- For any ingredient exceeding 200% of UL, use "WARNING" label (not "CAUTION") in Section 2
- Always express UL comparisons as "X% of UL" (e.g., "126mg is 280% of the 45mg UL"), never as "exceeds UL by X%" which is ambiguous
- If critical_stop items exist, mention them prominently as "Discontinue Immediately" — separate from cost savings

## Pricing Rules (CRITICAL)
- Use EXACTLY the prices provided in "Product Monthly Costs" above — copy dollar amounts verbatim
- Do NOT estimate, round, or recalculate any prices — use the exact decimal values given
- Section 1 Price column must match the provided values to the cent (e.g., if given \$10.08, write \$10.08 not \$10.00)
- Monthly/annual savings must match the provided figures exactly — do NOT recalculate

## Exclusion Rules
- Section 4 must ONLY reference the pre-determined exclusion list
- Do NOT suggest alternative products, substitutions, or brand switches
- Do NOT recommend independent cost-saving measures

## Tone Guidelines
- Never use "overdose", "overdosing", or "mimics overdose" — instead say "creates dangerously excessive" or "exceeds reasonable safety standards"
- Never use "opioid-like" for botanical/herbal ingredients — instead say "mild sedative activity via alkaloid pathways"
- Never use "comparable to [prescription drug] overdose" — instead describe the actual risks directly (e.g. excessive sedation, fall risk, cognitive impairment)
- Avoid clinical diagnosis language: no "serotonin syndrome", "respiratory failure", "organ failure" as definitive outcomes — use "risk of" or "potential for" instead
- Keep warnings firm but factual, not fear-inducing
- Frame risks as actionable: tell users what to DO, not just what to fear
- OK to use: "dangerous", "unsafe", "high risk", "discontinue", "consult your doctor"
- NOT OK: "fatal", "deadly", "life-threatening", "you could die" unless genuinely immediate danger (e.g. MAOI + serotonergic combo)

## Exclusion Logic Rules
- When ALL products share the same pharmacological mechanism (e.g., all GABAergic, all serotonergic), recommend keeping only 1-2 products maximum, not the entire stack minus one
- "Functional overlap" across the entire stack is MORE dangerous than a single ingredient safety issue — prioritize mechanism-level risk over individual product risk
- If 4+ products share the same mechanism, the default recommendation must be "keep 1-2, remove the rest" — not "remove the worst one"
- The What to Cut section must reflect the FULL recommended reduction, not just the single most dangerous product
- It is OK to firmly recommend major stack reduction — strong safety recommendations are not the same as fear-inducing language
''';
  }
}
