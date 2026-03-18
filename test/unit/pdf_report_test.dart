import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF 리포트 자동화 테스트
///
/// 커버리지:
/// 1. 마크다운 인라인 포맷 제거 (replaceAllMapped 회귀 방지)
/// 2. 한글 제품명 포함 PDF 생성
/// 3. 한글 JSON 파싱
void main() {
  // ── 1. 마크다운 스트리핑 테스트 ($1 버그 회귀 방지) ──

  group('Markdown inline stripping', () {
    // PdfReportService._stripMarkdownFormatting 과 동일한 로직
    String stripMarkdownFormatting(String text) {
      var result = text;
      result = result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
      result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);
      result = result.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m[1]!);
      return result;
    }

    test('**bold** → bold (리터럴 \$1 출력 금지)', () {
      expect(stripMarkdownFormatting('**bold text**'), 'bold text');
    });

    test('*italic* → italic', () {
      expect(stripMarkdownFormatting('*italic text*'), 'italic text');
    });

    test('`code` → code', () {
      expect(stripMarkdownFormatting('`some code`'), 'some code');
    });

    test('**Omega**-3 → Omega-3 (제품명 보존)', () {
      expect(stripMarkdownFormatting('**Omega**-3'), 'Omega-3');
    });

    test('Cenovis, *Omega*-3 → Cenovis, Omega-3', () {
      expect(stripMarkdownFormatting('Cenovis, *Omega*-3'), 'Cenovis, Omega-3');
    });

    test('한글 볼드: **비타민D** 과다 → 비타민D 과다', () {
      expect(stripMarkdownFormatting('**비타민D** 과다'), '비타민D 과다');
    });

    test('혼합 포맷: **bold** and *italic* and `code`', () {
      expect(
        stripMarkdownFormatting('**bold** and *italic* and `code`'),
        'bold and italic and code',
      );
    });

    test('포맷 없는 텍스트는 그대로 통과', () {
      expect(stripMarkdownFormatting('plain text 123'), 'plain text 123');
    });

    test('빈 문자열 처리', () {
      expect(stripMarkdownFormatting(''), '');
    });
  });

  // ── 1-2. 이모지 제거 테스트 ──

  group('Emoji removal', () {
    String removeEmojis(String text) {
      return text
          .replaceAll(
            RegExp(
              r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|'
              r'[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|'
              r'[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|'
              r'[\u{FE00}-\u{FE0F}]|[\u{1F900}-\u{1F9FF}]|'
              r'[\u{200D}]|[\u{20E3}]|[\u{E0020}-\u{E007F}]',
              unicode: true,
            ),
            '',
          )
          .trim();
    }

    test('⚠️ 제거', () {
      expect(removeEmojis('⚠️ 경고 메시지'), '경고 메시지');
    });

    test('💰 제거', () {
      expect(removeEmojis('💰 예상 절감액'), '예상 절감액');
    });

    test('📋 제거', () {
      expect(removeEmojis('📋 분석 리포트'), '분석 리포트');
    });

    test('복합 이모지 제거: ✅🔍❌', () {
      expect(removeEmojis('✅ 안전 🔍 확인 ❌ 위험'), '안전  확인  위험');
    });

    test('이모지 없는 텍스트는 그대로', () {
      expect(removeEmojis('비타민D 50mcg'), '비타민D 50mcg');
    });

    test('영문+이모지 혼합', () {
      expect(removeEmojis('🎯 Omega-3 EPA 360mg'), 'Omega-3 EPA 360mg');
    });
  });

  // ── 2. PDF 생성 테스트 (한글 폰트 포함) ──

  group('PDF generation with Korean font', () {
    late pw.Font koreanFont;
    late SuppleCutAnalysisResult testResult;

    setUpAll(() {
      // 프로젝트 루트 기준 폰트 파일 직접 로드 (rootBundle 대신)
      final fontFile = File('assets/fonts/NotoSansKR-Regular.ttf');
      if (!fontFile.existsSync()) {
        fail('NotoSansKR-Regular.ttf not found in assets/fonts/');
      }
      final fontData = fontFile.readAsBytesSync();
      koreanFont = pw.Font.ttf(fontData.buffer.asByteData());

      testResult = const SuppleCutAnalysisResult(
        products: [
          AnalyzedProduct(
            name: 'CENOVIS, Triplus Omega-3 Immune Men',
            source: 'ai_estimated',
            nameKo: '세노비스, 트리플러스 오메가-3 이뮨 맨',
            ingredients: [
              AnalyzedIngredient(name: 'EPA', amount: 360, unit: 'mg'),
              AnalyzedIngredient(name: 'DHA', amount: 240, unit: 'mg'),
              AnalyzedIngredient(name: '비타민D', amount: 25, unit: 'mcg'),
            ],
            confidence: 'medium',
            estimatedMonthlyPrice: 28000,
          ),
          AnalyzedProduct(
            name: 'NOW Foods, Vitamin D-3, 5000 IU',
            source: 'local_db',
            nameKo: 'NOW Foods, 비타민 D-3, 5000 IU',
            ingredients: [
              AnalyzedIngredient(name: 'Vitamin D3', amount: 125, unit: 'mcg'),
            ],
            estimatedMonthlyPrice: 8500,
          ),
        ],
        duplicates: [
          DuplicateIngredient(
            ingredient: '비타민D (Vitamin D)',
            products: [
              '세노비스, 트리플러스 오메가-3 이뮨 맨',
              'NOW Foods, 비타민 D-3',
            ],
            totalAmount: '150mcg',
            dailyLimit: '100mcg',
            riskLevel: 'danger',
            advice: '비타민D 합산 150mcg로 상한 섭취량(100mcg)을 초과합니다.',
          ),
        ],
        overallRisk: 'danger',
        summary: '비타민D가 상한 섭취량을 초과하여 위험합니다.',
        recommendations: [
          '비타민D 단독 제품을 중단하세요.',
          '세노비스 오메가-3만으로 충분합니다.',
        ],
        monthlySavings: 8500,
        yearlySavings: 102000,
        excludedProduct: 'NOW Foods, 비타민 D-3, 5000 IU',
      );
    });

    test('한글 제품명 포함 PDF 바이트 생성 성공', () async {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: koreanFont,
          bold: koreanFont,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text('SuppleCut 분석 리포트',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            // 한글 제품명
            ...testResult.products.map((p) => pw.Text(
                  '${p.nameKo ?? p.name} - ${p.source}',
                  style: const pw.TextStyle(fontSize: 12),
                )),
            pw.SizedBox(height: 16),
            // 한글 중복 성분
            ...testResult.duplicates.map((d) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(d.ingredient,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('합산: ${d.totalAmount} / 상한: ${d.dailyLimit}'),
                    pw.Text(d.advice),
                    pw.Text('포함 제품: ${d.products.join(", ")}'),
                  ],
                )),
            pw.SizedBox(height: 16),
            // 절감 정보
            pw.Text('월 절감액: ${testResult.monthlySavings}원'),
            pw.Text('연 절감액: ${testResult.yearlySavings}원'),
            pw.Text('제외 권장: ${testResult.excludedProduct}'),
            pw.SizedBox(height: 16),
            // 한글 마크다운 컨텐츠
            pw.Text('비타민D(비타민D3)가 과다 섭취 상태입니다.'),
            pw.Text('세노비스, 트리플러스 오메가-3 이뮨 맨에 이미 포함되어 있습니다.'),
          ],
        ),
      );

      final Uint8List bytes = await pdf.save();

      // PDF 유효성 검증
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000)); // 최소 크기

      // PDF 매직 넘버 (%PDF)
      final header = String.fromCharCodes(bytes.sublist(0, 5));
      expect(header, startsWith('%PDF'));
    });

    test('한글 + 영문 혼합 테이블 렌더링', () async {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: koreanFont,
          bold: koreanFont,
        ),
      );

      pdf.addPage(
        pw.Page(
          build: (context) => pw.TableHelper.fromTextArray(
            headers: ['제품명', 'Source', '주요 성분', '월 가격'],
            data: testResult.products.map((p) {
              final displayName = p.nameKo ?? p.name;
              final source = p.isEstimated ? 'AI 추정' : 'DB 매칭';
              final ingredients = p.ingredients
                  .take(3)
                  .map((i) => '${i.name} ${i.amount}${i.unit}')
                  .join(', ');
              final price = '${p.estimatedMonthlyPrice}원';
              return [displayName, source, ingredients, price];
            }).toList(),
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), startsWith('%PDF'));
    });

    test('마크다운 불릿/헤딩 처리 (빈 리포트)', () async {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: koreanFont,
          bold: koreanFont,
        ),
      );

      // 실제 AI 리포트 형태의 마크다운
      const markdown = '''## 분석 결과 요약
비타민D가 과다합니다.

### 중복 성분 상세
- **비타민D**: 합산 150mcg (상한 100mcg 초과)
- *EPA/DHA*: 정상 범위

### 권장사항
- 비타민D 단독 제품 중단
- `세노비스 오메가-3`만 유지

---
[!] 본 분석은 참고용입니다.''';

      // _buildMarkdownContent 로직 재현
      String stripFormatting(String text) {
        var result = text;
        result =
            result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
        result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);
        result = result.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m[1]!);
        return result;
      }

      final lines = markdown.split('\n');
      final widgets = <pw.Widget>[];

      for (final line in lines) {
        final trimmed = line.trimLeft();
        if (trimmed.isEmpty) {
          widgets.add(pw.SizedBox(height: 4));
          continue;
        }
        if (trimmed.startsWith('## ')) {
          widgets.add(pw.Text(trimmed.substring(3),
              style:
                  pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)));
          continue;
        }
        if (trimmed.startsWith('### ')) {
          widgets.add(pw.Text(trimmed.substring(4),
              style:
                  pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
          continue;
        }
        if (trimmed == '---' || trimmed == '***') {
          widgets.add(pw.Divider());
          continue;
        }
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          final content = stripFormatting(trimmed.substring(2));
          // $1이 포함되지 않는지 검증
          expect(content, isNot(contains(r'$1')),
              reason: 'regex \$1 리터럴이 출력되면 안 됨: "$content"');
          widgets.add(pw.Text('- $content'));
          continue;
        }
        widgets.add(pw.Text(stripFormatting(trimmed)));
      }

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          ),
        ),
      );

      final bytes = await pdf.save();
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 5)), startsWith('%PDF'));
    });
  });

  // ── 3. 한글 제품명 JSON 파싱 테스트 ──

  group('Korean product name JSON parsing', () {
    test('한글 제품명이 포함된 분석 결과 파싱', () {
      final json = {
        'products': [
          {
            'name': 'CENOVIS, Triplus Omega-3 Immune Men',
            'source': 'ai_estimated',
            'name_ko': '세노비스, 트리플러스 오메가-3 이뮨 맨',
            'ingredients': [
              {'name': 'EPA', 'amount': 360, 'unit': 'mg'},
              {'name': 'DHA', 'amount': 240, 'unit': 'mg'},
            ],
            'confidence': 'medium',
            'estimatedMonthlyPrice': 28000,
          },
          {
            'name': '종근당, 비타민D 1000IU',
            'source': 'ai_estimated',
            'name_ko': '종근당, 비타민D 1000IU',
            'ingredients': [
              {'name': '비타민D3(콜레칼시페롤)', 'amount': 25, 'unit': 'mcg'},
            ],
            'confidence': 'high',
            'estimatedMonthlyPrice': 12000,
          },
        ],
        'duplicates': [
          {
            'ingredient': '비타민D (Vitamin D)',
            'products': ['세노비스, 트리플러스 오메가-3', '종근당, 비타민D'],
            'totalAmount': '50mcg',
            'dailyLimit': '100mcg',
            'riskLevel': 'warning',
            'advice': '비타민D 합산 50mcg로 상한 범위 이내이나 모니터링이 필요합니다.',
          },
        ],
        'overallRisk': 'warning',
        'summary': '비타민D 중복 섭취가 확인되었습니다.',
        'recommendations': ['비타민D 단독 제품 용량을 줄이세요.'],
        'monthlySavings': 12000,
        'yearlySavings': 144000,
        'excludedProduct': '종근당, 비타민D 1000IU',
      };

      final result = SuppleCutAnalysisResult.fromJson(json);

      // 제품 파싱
      expect(result.products.length, 2);
      expect(result.products[0].nameKo, '세노비스, 트리플러스 오메가-3 이뮨 맨');
      expect(result.products[1].name, '종근당, 비타민D 1000IU');
      expect(result.products[1].ingredients[0].name, '비타민D3(콜레칼시페롤)');

      // 중복 성분 파싱
      expect(result.duplicates.length, 1);
      expect(result.duplicates[0].ingredient, '비타민D (Vitamin D)');
      expect(result.duplicates[0].advice, contains('비타민D'));

      // 절감 정보
      expect(result.monthlySavings, 12000);
      expect(result.yearlySavings, 144000);
      expect(result.excludedProduct, '종근당, 비타민D 1000IU');
      expect(result.hasSavings, isTrue);
    });

    test('Omega-3 제품명이 잘리지 않는지 확인', () {
      final json = {
        'products': [
          {
            'name': 'Cenovis, Omega-3',
            'source': 'ai_estimated',
            'ingredients': [],
          },
        ],
        'duplicates': [],
        'overallRisk': 'safe',
        'summary': '',
        'recommendations': [],
      };

      final result = SuppleCutAnalysisResult.fromJson(json);
      expect(result.products[0].name, 'Cenovis, Omega-3');
      expect(result.products[0].name, contains('Omega'));
    });

    test('올리브영 국내 제품 한글 전용 이름 파싱', () {
      final json = {
        'products': [
          {
            'name': '얼라이브 원스데일리 포맨 멀티비타민',
            'source': 'ai_estimated',
            'name_ko': '얼라이브 원스데일리 포맨 멀티비타민',
            'ingredients': [
              {'name': '비타민A(레티닐아세테이트)', 'amount': 750, 'unit': 'mcg'},
              {'name': '비타민C(아스코르브산)', 'amount': 100, 'unit': 'mg'},
            ],
            'estimatedMonthlyPrice': 15000,
          },
        ],
        'duplicates': [],
        'overallRisk': 'safe',
        'summary': '중복 성분이 없습니다.',
        'recommendations': [],
      };

      final result = SuppleCutAnalysisResult.fromJson(json);
      expect(result.products[0].name, '얼라이브 원스데일리 포맨 멀티비타민');
      expect(result.products[0].ingredients[0].name, '비타민A(레티닐아세테이트)');
      expect(result.products[0].estimatedMonthlyPrice, 15000);
    });
  });
}
