import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';
import 'package:myapp/utils/localization_utils.dart';

/// SuppleCut 분석 결과 화면
///
/// 무료: 절감 배너 + 과다 섭취 경고 + 제품 목록 + 제품별 성분
/// 유료: AI 상세 분석 리포트 (중복성분 상세 + 요약 + 권장사항)
class AnalysisResultScreen extends StatefulWidget {
  final SuppleCutAnalysisResult result;
  final bool isPremiumUser;

  const AnalysisResultScreen({
    super.key,
    required this.result,
    this.isPremiumUser = false,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _isReportExpanded = true;
  bool _isReportUnlocked = false;
  bool _isReportLoading = false;
  String? _detailedReport;
  String? _reportError;

  SuppleCutAnalysisResult get result => widget.result;
  bool get isPremium => widget.isPremiumUser || _isReportUnlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.analysisTitle,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 20, right: 20, top: 20, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 무료 섹션 ──

                // 1. 절감 금액 배너 (또는 긍정 배너)
                if (result.hasSavings) ...[
                  _buildSavingsBanner(),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildPositiveBanner(),
                  const SizedBox(height: 16),
                ],

                // 3. 제품 목록
                const SizedBox(height: 20),
                Text('📦 ${l10n.analyzedProducts}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...result.products.map(_buildProductCard),

                // ── 유료 잠금 섹션: AI 상세 분석 리포트 ──
                if (_hasPremiumContent()) ...[
                  const SizedBox(height: 20),
                  _buildPremiumReportCard(),
                ],

                // Disclaimer
                if (result.disclaimer != null) ...[
                  const SizedBox(height: 20),
                  _buildDisclaimerCard(),
                ],

                const SizedBox(height: 16),

                // 기본 Disclaimer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.homeDisclaimer,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Bottom Action Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.btnBackHome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 유료 컨텐츠가 있는지 확인
  bool _hasPremiumContent() {
    return result.hasDuplicates ||
        result.summary.isNotEmpty ||
        result.recommendations.isNotEmpty;
  }

  // ── 위젯 빌더들 ──

  /// 절감 금액 배너 (무료)
  Widget _buildSavingsBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFDD835)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9A825).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 제외 제품명 (상단)
          if (result.excludedProduct != null) ...[
            Text(
              l10n.analysisExcludingProduct(result.excludedProduct!),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4037),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // 라벨
          Text(
            '💰 ${l10n.analysisSavings}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF795548),
            ),
          ),
          const SizedBox(height: 8),

          // 금액
          Text(
            LocalizationUtils.formatCurrency(
                result.monthlySavings.toDouble(), l10n.localeName),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3E2723),
            ),
          ),

          // 연간 절감 필
          if (result.yearlySavings > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🎉 ${l10n.analysisYearly(LocalizationUtils.formatCurrency(result.yearlySavings.toDouble(), l10n.localeName))}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],

          // 하단 설명
          if (result.summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '💊 ${result.summary}',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF5D4037),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// 제품 카드 (무료) — 제품명 + 소스 태그 + 월 가격 + 성분 칩 + 중복 뼉지
  Widget _buildProductCard(AnalyzedProduct product) {
    final l10n = AppLocalizations.of(context)!;
    final isEstimated = product.isEstimated;

    // 이 제품이 중복 성분에 포함되어 있는지 확인
    final isDuplicate =
        result.duplicates.any((dup) => dup.products.contains(product.name));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isEstimated
            ? Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제품명 + 소스 태그
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.localeName == 'en'
                      ? product.name
                      : (product.nameKo ?? product.name),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEstimated
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEstimated
                      ? '🤖 ${l10n.badgeAiEstimated}'
                      : '✅ ${l10n.badgeDbMatched}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isEstimated
                        ? const Color(0xFFFF8F00)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),

          // 중복 뼉지
          if (isDuplicate) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: const Color(0xFFEF5350).withValues(alpha: 0.3)),
              ),
              child: Text(
                l10n.badgeDuplicate,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ),
          ],

          // 월 환산 가격
          if (product.estimatedMonthlyPrice > 0) ...[
            const SizedBox(height: 6),
            Text(
              '💰 ${l10n.localeName == 'en' ? 'Monthly' : '월'} ${LocalizationUtils.formatCurrency(product.estimatedMonthlyPrice.toDouble(), l10n.localeName)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          // AI 추정 노트
          if (isEstimated && product.note != null) ...[
            const SizedBox(height: 6),
            Text(
              '📝 ${product.note}',
              style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54),
            ),
          ],

          // 성분 리스트
          if (product.ingredients.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: product.ingredients.map((ing) {
                final label = ing.amount > 0
                    ? '${ing.name} ${ing.amount}${ing.unit}'
                    : ing.name;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// AI 상세 분석 리포트 카드 (유료 잠금)
  Widget _buildPremiumReportCard() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium ? const Color(0xFFE0E0E0) : const Color(0xFFE8D5F5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더
          InkWell(
            onTap: () => setState(() => _isReportExpanded = !_isReportExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.detailReportTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isReportExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // 컨텐츠 영역
          if (_isReportExpanded)
            isPremium ? _buildPremiumContent() : _buildLockedContent(),
        ],
      ),
    );
  }

  /// 프리미엄 컨텐츠 (잠금 해제 상태) — 마크다운 리포트 렌더링
  Widget _buildPremiumContent() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (_isReportLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.reportGenerating,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(l10n.reportGeneratingWait,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black38)),
                  ],
                ),
              ),
            )
          else if (_reportError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(l10n.reportError(_reportError.toString()),
                      style: const TextStyle(fontSize: 14, color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _generateReport,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          else if (_detailedReport != null)
            MarkdownBody(
              data: _detailedReport!,
              styleSheet: MarkdownStyleSheet(
                h2: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                h3: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                h4: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                p: const TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.black87),
                listBullet:
                    const TextStyle(fontSize: 14, color: Colors.black87),
                strong: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 상세 리포트 API 호출
  Future<void> _generateReport() async {
    setState(() {
      _isReportUnlocked = true;
      _isReportLoading = true;
      _reportError = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final report = await GeminiAnalyzerService()
          .generateSuppleCutReport(result, locale: l10n.localeName);
      if (!mounted) return;
      setState(() {
        _detailedReport = report;
        _isReportLoading = false;
        _isReportUnlocked = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reportError = e.toString();
        _isReportLoading = false;
      });
    }
  }

  /// 잠금 상태 컨텐츠 (미리보기 + 블러 + 잠금 배너)
  Widget _buildLockedContent() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1),
        ),

        // 미리보기 영역 (블러 처리)
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(14)),
          child: Stack(
            children: [
              // 실제 컨텐츠 (블러됨)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result.summary.isNotEmpty) ...[
                      Text(l10n.analysisDetailSubtitle,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Text(
                        result.summary,
                        style: const TextStyle(
                            fontSize: 14, height: 1.6, color: Colors.black87),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),

              // 블러 + 그라디언트 페이드
              Positioned.fill(
                child: Column(
                  children: [
                    // 상단 일부는 보여주기
                    const SizedBox(height: 40),
                    // 그라디언트 페이드 → 블러
                    Expanded(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.7),
                                  Colors.white.withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.3, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 잠금 해제 CTA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_outline,
                    color: Color(0xFF7B1FA2), size: 28),
                const SizedBox(height: 8),
                Text(
                  l10n.premiumUnlockTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.premiumUnlockDesc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9C27B0),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.premiumUnlockBtn,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 긍정 피드백 배너 (중복/과잉이 없을 때)
  Widget _buildPositiveBanner() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: const Color(0xFF81C784).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF2E7D32),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.positiveBannerTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.positiveBannerDesc,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF388E3C),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Disclaimer 카드
  Widget _buildDisclaimerCard() {
    final l10n = AppLocalizations.of(context)!;

    // Check if the disclaimer matches the hardcoded AI estimate text and use l10n if so
    final isAiEstimatedDisclaimer =
        result.disclaimer == "일부 제품은 AI 추정치 기반입니다. 정확한 정보는 제품 라벨을 확인하세요.";
    final displayDisclaimer = isAiEstimatedDisclaimer
        ? l10n.disclaimerAiEstimate
        : result.disclaimer!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayDisclaimer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.brown[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
