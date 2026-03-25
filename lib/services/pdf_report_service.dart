import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/supplecut_analysis_result.dart';

/// PDF 리포트 생성 서비스
///
/// [SuppleCutAnalysisResult] + 상세 마크다운 리포트를 A4 PDF로 변환한다.
/// Share sheet를 통한 내보내기 기능을 제공한다.
class PdfReportService {
  /// PDF 생성 후 바이트 반환
  ///
  /// [result] 분석 결과 데이터
  /// [detailedReport] AI 생성 상세 리포트 (마크다운 텍스트)
  /// [locale] "ko" 또는 "en"
  Future<Uint8List> generatePdf({
    required SuppleCutAnalysisResult result,
    required String detailedReport,
    String locale = 'ko',
  }) async {
    final isKo = locale == 'ko';

    // 한글 지원 폰트 로드
    final fontData =
        await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
    final koreanFont = pw.Font.ttf(fontData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: koreanFont,
        bold: koreanFont,
      ),
    );
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy.MM.dd HH:mm').format(now);

    // 테마 색상
    const primaryColor = PdfColor.fromInt(0xFF7B1FA2);
    const dangerColor = PdfColor.fromInt(0xFFE53935);
    const warningColor = PdfColor.fromInt(0xFFF57C00);
    const safeColor = PdfColor.fromInt(0xFF2E7D32);
    const grey600 = PdfColor.fromInt(0xFF757575);
    const grey300 = PdfColor.fromInt(0xFFE0E0E0);

    // 중복 성분 분류
    final dangerDups =
        result.duplicates.where((d) => d.riskLevel == 'danger').toList();
    final warningDups =
        result.duplicates.where((d) => d.riskLevel == 'warning').toList();
    final safeDups =
        result.duplicates.where((d) => d.riskLevel == 'safe').toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(dateStr, isKo, primaryColor),
        footer: (context) => _buildFooter(context, isKo, grey600),
        build: (context) => [
          // ── Disclaimer 배너 ──
          _buildDisclaimerBanner(isKo),
          pw.SizedBox(height: 16),

          // ── 제품 테이블 ──
          _buildSectionTitle(
            isKo ? '분석 제품 목록' : 'Analyzed Products',
            primaryColor,
          ),
          pw.SizedBox(height: 8),
          _buildProductTable(result, isKo, grey300),
          pw.SizedBox(height: 20),

          // ── 중복 성분 섹션 ──
          if (result.hasDuplicates) ...[
            _buildSectionTitle(
              isKo ? '중복 성분 분석' : 'Duplicate Ingredient Analysis',
              primaryColor,
            ),
            pw.SizedBox(height: 8),

            // Danger
            if (dangerDups.isNotEmpty) ...[
              _buildRiskGroupHeader(
                isKo ? '위험 (과다 섭취 주의)' : 'Danger (Excessive Intake)',
                dangerColor,
              ),
              ...dangerDups
                  .map((d) => _buildDuplicateItem(d, dangerColor, isKo)),
              pw.SizedBox(height: 12),
            ],

            // Warning
            if (warningDups.isNotEmpty) ...[
              _buildRiskGroupHeader(
                isKo ? '주의 (모니터링 필요)' : 'Warning (Monitor Intake)',
                warningColor,
              ),
              ...warningDups
                  .map((d) => _buildDuplicateItem(d, warningColor, isKo)),
              pw.SizedBox(height: 12),
            ],

            // Safe
            if (safeDups.isNotEmpty) ...[
              _buildRiskGroupHeader(
                isKo ? '안전 (허용 범위)' : 'Safe (Within Limits)',
                safeColor,
              ),
              ...safeDups.map((d) => _buildDuplicateItem(d, safeColor, isKo)),
              pw.SizedBox(height: 12),
            ],
            pw.SizedBox(height: 8),
          ],

          // ── 절감 정보 ──
          if (result.hasSavings) ...[
            _buildSavingsSection(result, isKo, primaryColor),
            pw.SizedBox(height: 20),
          ],

          // ── AI 상세 분석 ──
          _buildSectionTitle(
            isKo ? 'AI 상세 분석 리포트' : 'AI Detailed Analysis Report',
            primaryColor,
          ),
          pw.SizedBox(height: 8),
          _buildMarkdownContent(detailedReport),
        ],
      ),
    );

    return pdf.save();
  }

  /// PDF 내보내기 (시스템 공유 시트)
  Future<void> sharePdf({
    required Uint8List pdfBytes,
    String? fileName,
  }) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = fileName ?? 'SuppleCut_Report_$timestamp.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: name.replaceAll('.pdf', ''),
    );
  }

  // ── Private: 헤더/푸터 ──

  pw.Widget _buildHeader(String dateStr, bool isKo, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE0E0E0), width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'SuppleCut',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.Text(
            dateStr,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromInt(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, bool isKo, PdfColor greyColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isKo
                ? '본 리포트는 참고용이며 의료 조언이 아닙니다.'
                : 'This report is for reference only, not medical advice.',
            style: pw.TextStyle(fontSize: 8, color: greyColor),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: greyColor),
          ),
        ],
      ),
    );
  }

  // ── Private: Disclaimer ──

  pw.Widget _buildDisclaimerBanner(bool isKo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFE082)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        isKo
            ? '[!] 본 분석은 AI 기반 참고 자료이며, 전문 의료 상담을 대체하지 않습니다. '
                '정확한 복용 지침은 의사 또는 약사와 상담하세요.'
            : '[!] This analysis is AI-generated reference material and does not '
                'replace professional medical advice. Consult a doctor or pharmacist '
                'for accurate dosage guidance.',
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColor.fromInt(0xFF795548),
        ),
      ),
    );
  }

  // ── Private: 섹션 제목 ──

  pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: color, width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ── Private: 제품 테이블 ──

  pw.Widget _buildProductTable(
      SuppleCutAnalysisResult result, bool isKo, PdfColor borderColor) {
    // A4 기준 가용폭 = 595 - 40*2 = 515pt
    // 제품명 20% | 소스 8% | 주요성분 60% | 월가격 12%
    final columnWidths = {
      0: const pw.FlexColumnWidth(20),
      1: const pw.FlexColumnWidth(8),
      2: const pw.FlexColumnWidth(60),
      3: const pw.FlexColumnWidth(12),
    };

    return pw.TableHelper.fromTextArray(
      columnWidths: columnWidths,
      headerStyle: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF7B1FA2),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headers: [
        isKo ? '제품명' : 'Product',
        isKo ? '소스' : 'Src',
        isKo ? '주요 성분' : 'Key Ingredients',
        isKo ? '월 가격' : 'Price',
      ],
      data: result.products.map((p) {
        final displayName = isKo ? (p.nameKo ?? p.name) : p.name;
        final source = p.isEstimated
            ? (isKo ? 'AI 추정' : 'AI Est.')
            : (isKo ? 'DB 매칭' : 'DB');
        final ingredients = p.ingredients
            .take(3)
            .map(
                (i) => i.amount > 0 ? '${i.name} ${i.amount}${i.unit}' : i.name)
            .join(', ');
        final price = p.estimatedMonthlyPrice > 0
            ? (isKo
                ? '${NumberFormat('#,###').format(p.estimatedMonthlyPrice)}원'
                : '\$${(p.estimatedMonthlyPrice / 1300).toStringAsFixed(1)}')
            : '-';
        return [displayName, source, ingredients, price];
      }).toList(),
    );
  }

  // ── Private: 중복 성분 ──

  pw.Widget _buildRiskGroupHeader(String label, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _buildDuplicateItem(
      DuplicateIngredient dup, PdfColor accentColor, bool isKo) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: accentColor, width: 3),
        ),
        color: const PdfColor.fromInt(0xFFFAFAFA),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                dup.ingredient,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${isKo ? '합산' : 'Total'}: ${dup.totalAmount}'
                '${dup.dailyLimit != null ? ' / ${isKo ? '상한' : 'Limit'}: ${dup.dailyLimit}' : ''}',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF616161),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '${isKo ? '포함 제품' : 'Found in'}: ${dup.products.join(', ')}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF757575),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            dup.advice,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  // ── Private: 절감 섹션 ──

  pw.Widget _buildSavingsSection(
      SuppleCutAnalysisResult result, bool isKo, PdfColor color) {
    final monthlyStr = isKo
        ? '${NumberFormat('#,###').format(result.monthlySavings)}원'
        : '\$${(result.monthlySavings / 1300).toStringAsFixed(0)}';
    final yearlyStr = isKo
        ? '${NumberFormat('#,###').format(result.yearlySavings)}원'
        : '\$${(result.yearlySavings / 1300).toStringAsFixed(0)}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF3E5F5),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCE93D8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isKo ? '예상 절감액' : 'Estimated Savings',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${isKo ? '월' : 'Monthly'}: $monthlyStr  |  '
            '${isKo ? '연' : 'Yearly'}: $yearlyStr',
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (result.excludedProduct != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '${isKo ? '제외 권장 제품' : 'Recommended to exclude'}: ${result.excludedProduct}',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromInt(0xFF757575),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Private: 마크다운 → 텍스트 변환 ──

  pw.Widget _buildMarkdownContent(String markdown) {
    // AI 응답에 포함된 이모지 일괄 제거
    final cleanedMarkdown = _removeEmojis(markdown);
    final lines = cleanedMarkdown.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // H2: ##
      if (trimmed.startsWith('## ')) {
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(pw.Text(
          trimmed.substring(3),
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF424242),
          ),
        ));
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // H3: ###
      if (trimmed.startsWith('### ')) {
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text(
          trimmed.substring(4),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF616161),
          ),
        ));
        widgets.add(pw.SizedBox(height: 3));
        continue;
      }

      // H4: ####
      if (trimmed.startsWith('#### ')) {
        widgets.add(pw.Text(
          trimmed.substring(5),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF757575),
          ),
        ));
        continue;
      }

      // Horizontal rule: ---
      if (trimmed == '---' || trimmed == '***') {
        widgets.add(pw.Divider(
          color: const PdfColor.fromInt(0xFFE0E0E0),
          thickness: 0.5,
        ));
        continue;
      }

      // Bullet: - or *
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, bottom: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: const pw.TextStyle(fontSize: 9)),
              pw.Expanded(
                child: pw.Text(
                  _stripMarkdownFormatting(trimmed.substring(2)),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    lineSpacing: 3,
                    color: PdfColor.fromInt(0xFF424242),
                  ),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Regular paragraph
      widgets.add(pw.Text(
        _stripMarkdownFormatting(trimmed),
        style: const pw.TextStyle(
          fontSize: 9,
          lineSpacing: 3,
          color: PdfColor.fromInt(0xFF424242),
        ),
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 마크다운 인라인 포맷 제거 (**bold**, *italic* 등)
  String _stripMarkdownFormatting(String text) {
    var result = text;
    // **bold** → bold
    result = result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
    // *italic* → italic
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);
    // `code` → code
    result = result.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m[1]!);
    return result;
  }

  /// 이모지 제거 (PDF 폰트에 글리프 없어 깨짐 방지)
  static String _removeEmojis(String text) {
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
}
