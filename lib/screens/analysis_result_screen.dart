import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/models/onestop_analysis_result.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/services/claude_report_service.dart';
import 'package:myapp/services/pdf_report_service.dart';
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:myapp/core/service_locator.dart';
import 'package:myapp/services/iap_service.dart';
import 'package:myapp/utils/localization_utils.dart';
import 'package:myapp/widgets/disclaimer_banner.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/services/profile_service.dart';
import 'package:myapp/screens/subscription/paywall_screen.dart';
import 'package:myapp/screens/profile/profile_setup_screen.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isReportExpanded = true;
  bool _isReportUnlocked = false;
  bool _isReportLoading = false;
  bool _isReportStreaming = false;
  bool _isPdfGenerating = false;
  String? _detailedReport;
  String? _reportError;

  late IAPService _iapService;
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _hasUnlimitedReports = false;
  bool _showProfileBanner = false;
  StreamSubscription<PurchaseStatus>? _purchaseSubscription;
  StreamSubscription<String>? _reportStreamSubscription;

  /// 커서 깜빡임 애니메이션
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  /// Safety details 섹션 스크롤 키
  final _safetyDetailKey = GlobalKey();

  SuppleCutAnalysisResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
    _cursorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
    _iapService = getIt<IAPService>();
    _purchaseSubscription = _iapService.purchaseStatusStream.listen((status) {
      if (!mounted) return;
      if (status == PurchaseStatus.purchased ||
          status == PurchaseStatus.restored) {
        _generateReport(showPdfPrompt: true);
        _trackReportPurchaseAndUpsell();
      } else if (status == PurchaseStatus.error) {
        setState(() {
          _isReportLoading = false;
          final l10n = AppLocalizations.of(context);
          _reportError = l10n?.errorGeneric ?? "결제에 실패했습니다.";
        });
      } else if (status == PurchaseStatus.pending) {
        setState(() {
          _isReportLoading = true;
          _reportError = null;
        });
      }
    });

    // 구독 상태 체크
    _checkSubscription();
    _checkProfileBanner();
  }

  Future<void> _checkProfileBanner() async {
    final hasProfile = await ProfileService().hasProfile();
    if (mounted && !hasProfile) {
      setState(() => _showProfileBanner = true);
    }
  }

  Future<void> _checkSubscription() async {
    await _subscriptionService.initialize();
    final unlimited = await _subscriptionService.hasUnlimitedReports();
    if (mounted) {
      setState(() => _hasUnlimitedReports = unlimited);
    }
  }

  @override
  void dispose() {
    _reportStreamSubscription?.cancel();
    _purchaseSubscription?.cancel();
    _subscriptionService.dispose();
    _cursorController.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          const DisclaimerBanner(),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 20, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 프로필 유도 배너 ──
                      if (_showProfileBanner) ...[
                        _buildProfileBanner(),
                        const SizedBox(height: 12),
                      ],

                      // ── 무료 섹션 ──

                      // 1. critical_stop 배너 (있을 때만)
                      if (result.exclusionResult?.hasCriticalStop ?? false) ...[
                        _buildCriticalStopBanner(),
                        const SizedBox(height: 12),
                      ],

                      // 1b. medical_supervision 배너 (있을 때만)
                      if (result.exclusionResult?.hasMedicalSupervision ??
                          false) ...[
                        _buildMedicalSupervisionBanner(),
                        const SizedBox(height: 12),
                      ],

                      // 2. 상단 배너 (이슈 유형별 분기)
                      if (result.exclusionResult?.hasSavings ?? false) ...[
                        _buildSavingsBanner(),
                        const SizedBox(height: 16),
                      ] else if (result.hasSavings &&
                          result.overallRisk != 'safe') ...[
                        _buildSavingsBanner(),
                        const SizedBox(height: 16),
                      ] else if (result.hasDuplicates ||
                          result.singleProductUlExcess.isNotEmpty) ...[
                        _buildSafetyIssuesBanner(),
                        const SizedBox(height: 16),
                      ] else if (result.functionalOverlaps.isNotEmpty) ...[
                        _buildFunctionalOverlapBanner(),
                        const SizedBox(height: 16),
                      ] else if (result.ulAtLimit.isNotEmpty) ...[
                        _buildUlAtLimitBanner(),
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

                      // ── 안전성 경고 섹션 ──
                      if (result.safetyAlerts.isNotEmpty) ...[
                        SizedBox(key: _safetyDetailKey, height: 20),
                        ...result.safetyAlerts.map(_buildSafetyAlertCard),
                      ],

                      // ── 기전 중복 섹션 ──
                      if (result.functionalOverlaps.isNotEmpty) ...[
                        SizedBox(
                            key: result.safetyAlerts.isEmpty
                                ? _safetyDetailKey
                                : null,
                            height: 20),
                        const Text('🧬 Mechanism Overlap Warning',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...result.functionalOverlaps
                            .map(_buildFunctionalOverlapCard),
                      ],

                      // ── 단일 제품 UL 근접 (95~100%) 섹션 ──
                      if (result.ulAtLimit.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ...result.ulAtLimit.map(_buildUlAtLimitCard),
                      ],

                      // ── 단일 제품 UL 초과 섹션 ──
                      if (result.singleProductUlExcess.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        ...result.singleProductUlExcess
                            .map(_buildSingleUlExcessCard),
                      ],

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
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 홈 버튼
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          border:
                              Border(top: BorderSide(color: Colors.grey.shade200)),
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
                            onPressed: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Critical Stop 배너 — Research Chemical / Therapeutic Dose
  Widget _buildCriticalStopBanner() {
    final criticalItems = result.exclusionResult!.criticalStopItems;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF5350), width: 1.5),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⛔', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Discontinue Immediately',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...criticalItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shortenProductName(item.product),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC62828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.reason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 4),
          const Text(
            'Consult your doctor before making changes to prescribed products.',
            style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Medical Supervision 배너 — Therapeutic Dose 제품
  Widget _buildMedicalSupervisionBanner() {
    final items = result.exclusionResult!.medicalSupervisionItems;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⚕️', style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                'Medical Supervision Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4527A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shortenProductName(item.product),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4527A0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.reason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 4),
          const Text(
            'Do not adjust or discontinue without consulting your prescribing physician.',
            style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
            textAlign: TextAlign.center,
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
  /// 제품명 축약: "Brand, Product, Dosage, Count" → "Brand, Product"
  String _shortenProductName(String fullName) {
    final parts = fullName.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) return parts.take(2).join(', ');
    return fullName;
  }

  /// Keep/Remove 텍스트 생성
  /// medical_supervision / critical_stop은 별도 카드로 표시하므로
  /// Remove에는 recommend_remove + conditional_remove만 표시.
  /// ExclusionEngine에 savingsItems가 없으면 excludedProduct(sanitizedRec 경유) fallback.
  String _buildKeepRemoveText() {
    final ex = result.exclusionResult;

    // 1차: ExclusionEngine의 savingsItems
    if (ex != null && ex.savingsItems.isNotEmpty) {
      final removeItems = ex.savingsItems;
      final removeCount = removeItems.length;
      final removeNames =
          removeItems.map((i) => _shortenProductName(i.product)).toList();
      final keepCount = ex.keptProducts.length;

      if (removeCount <= 2) {
        return 'Remove: ${removeNames.join(', ')}';
      }
      if (keepCount == 1) {
        return 'Keep: ${_shortenProductName(ex.keptProducts.first)}\nRemove: $removeCount other products';
      }
      return 'Keep: $keepCount products\nRemove: $removeCount other products';
    }

    // 2차: sanitizedRec에서 온 excludedProduct fallback
    final fallback = result.excludedProduct;
    if (fallback != null && fallback.isNotEmpty) {
      return 'Remove: ${_shortenProductName(fallback)}';
    }

    return '';
  }

  /// 경고 요약 텍스트
  String? _buildWarningSummary() {
    // functional_overlaps HIGH 우선
    final highFo =
        result.functionalOverlaps.where((fo) => fo.severity == 'high').toList();
    if (highFo.isNotEmpty) {
      final count = highFo.first.products.length;
      return '$count ${highFo.first.pathway} detected';
    }

    // safety_alerts
    if (result.safetyAlerts.isNotEmpty) {
      final sa = result.safetyAlerts.first;
      return 'Safety alert: ${_shortenProductName(sa.product)}';
    }

    return null;
  }

  Widget _buildSavingsBanner() {
    final ex = result.exclusionResult;
    final monthlySavingsUsd = (ex?.monthlySavings ?? 0) > 0
        ? ex!.monthlySavings
        : result.geminiMonthlySavingsUsd;
    final annualSavingsUsd = (ex?.annualSavings ?? 0) > 0
        ? ex!.annualSavings
        : result.geminiAnnualSavingsUsd;

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
          // 1. 헤드라인
          const Text(
            'You could save',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF795548),
            ),
          ),
          const SizedBox(height: 4),

          // 2. 절감액 (USD)
          Text(
            '\$${monthlySavingsUsd.toStringAsFixed(2)}/mo',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3E2723),
            ),
          ),

          // 3. 연간 절감 배지
          if (annualSavingsUsd > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "That's \$${annualSavingsUsd.toStringAsFixed(0)}/year!",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
            ),
          ],

          // 4. Keep/Remove 정보
          if (_buildKeepRemoveText().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _buildKeepRemoveText(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E342E),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // 5. 경고 요약 + "See safety details ▾"
          if (_buildWarningSummary() != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                final ctx = _safetyDetailKey.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(ctx,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      '⚠️ ${_buildWarningSummary()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF795548),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'See safety details ▾',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 제품명 퍼지 매칭 (Gemini가 이름을 축약/변형할 수 있으므로)
  bool _productNameMatches(
      String dupName, String productName, String? productNameKo) {
    final dn = dupName.toLowerCase().trim();
    final pn = productName.toLowerCase().trim();
    final pnKo = productNameKo?.toLowerCase().trim() ?? '';

    // 정확 매칭
    if (dn == pn || (pnKo.isNotEmpty && dn == pnKo)) return true;
    // 포함 매칭 (한쪽이 다른 쪽을 포함)
    if (dn.length >= 3 && pn.length >= 3) {
      if (dn.contains(pn) || pn.contains(dn)) return true;
    }
    if (pnKo.length >= 2 && dn.isNotEmpty) {
      if (dn.contains(pnKo) || pnKo.contains(dn)) return true;
    }
    // 토큰 기반 매칭 — dupName의 토큰 80%+ 가 productName에 포함
    final dnTokens = dn
        .split(RegExp(r'[\s,;:/\-\(\)]+'))
        .where((t) => t.length >= 2)
        .toList();
    if (dnTokens.length >= 2) {
      int score = 0;
      for (final token in dnTokens) {
        if (pn.contains(token)) score++;
      }
      if (score >= (dnTokens.length * 0.8).ceil()) return true;
    }
    return false;
  }

  /// 제품의 신호등 색상 결정
  ///
  /// - 중복 없음 → 초록
  /// - 중복 있음 + excludedProduct → 빨강
  /// - 중복 있음 + danger riskLevel → 빨강
  /// - 중복 있음 + warning riskLevel → 주황
  /// - 중복 있음 + safe riskLevel → 노랑
  Color _getProductSignalColor(AnalyzedProduct product) {
    const red = Color(0xFFE53935);
    const orange = Color(0xFFFFA726);
    const yellow = Color(0xFFFDD835);
    const green = Color(0xFF43A047);

    // 1. safety_alerts에 포함 → 빨강
    final hasSafetyAlert = result.safetyAlerts.any(
        (sa) => _productNameMatches(sa.product, product.name, product.nameKo));
    if (hasSafetyAlert) return red;

    // 2~4. functional_overlaps 최대 severity 확인
    String? maxFoSeverity;
    for (final fo in result.functionalOverlaps) {
      final isInvolved = fo.products.any((foName) =>
          _productNameMatches(foName, product.name, product.nameKo));
      if (!isInvolved) continue;

      if (fo.severity == 'high') {
        maxFoSeverity = 'high';
        break; // 이미 최고 severity
      } else if (fo.severity == 'medium' && maxFoSeverity != 'high') {
        maxFoSeverity = 'medium';
      } else if (fo.severity == 'low' && maxFoSeverity == null) {
        maxFoSeverity = 'low';
      }
    }

    if (maxFoSeverity == 'high') return red;
    if (maxFoSeverity == 'medium') return orange;
    if (maxFoSeverity == 'low') return yellow;

    // 5. overlaps(성분 중복)에 포함 → 노랑
    final hasDuplicate = result.duplicates.any((dup) => dup.products.any(
        (dupName) =>
            _productNameMatches(dupName, product.name, product.nameKo)));
    if (hasDuplicate) return yellow;

    // 6. 해당 없음 → 초록
    return green;
  }

  /// 배지 헬퍼
  Widget _buildBadge(
      String label, Color bg, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// 제품 카드 (무료) — 제품명 + 소스 태그 + 월 가격 + 성분 칩 + 배지
  Widget _buildProductCard(AnalyzedProduct product) {
    final l10n = AppLocalizations.of(context)!;
    final isEstimated = product.isEstimated;

    final signalColor = _getProductSignalColor(product);

    // 개별 배지 플래그
    final hasOverlap = result.duplicates.any((dup) => dup.products.any(
        (dupName) =>
            _productNameMatches(dupName, product.name, product.nameKo)));
    final hasFunctionalOverlap = result.functionalOverlaps.any((fo) =>
        fo.products.any((foName) =>
            _productNameMatches(foName, product.name, product.nameKo)));
    final hasUlExcess = result.singleProductUlExcess.any(
        (ex) => _productNameMatches(ex.product, product.name, product.nameKo));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isEstimated
            ? Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: signalColor, width: 4),
          ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

            // 배지 (Overlap / Similar Effect / UL Excess)
            if (hasOverlap || hasFunctionalOverlap || hasUlExcess) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (hasOverlap)
                    _buildBadge(
                      l10n.badgeDuplicate,
                      const Color(0xFFFFEBEE),
                      const Color(0xFFEF5350),
                      const Color(0xFFE53935),
                    ),
                  if (hasFunctionalOverlap)
                    _buildBadge(
                      l10n.badgeSimilarEffect,
                      const Color(0xFFE3F2FD),
                      const Color(0xFF42A5F5),
                      const Color(0xFF1565C0),
                    ),
                  if (hasUlExcess)
                    _buildBadge(
                      l10n.badgeUlExcess,
                      const Color(0xFFFFF3E0),
                      const Color(0xFFFFA726),
                      const Color(0xFFE65100),
                    ),
                ],
              ),
            ],

            // 월 환산 가격
            if (product.monthlyCostUsd > 0 ||
                product.estimatedMonthlyPrice > 0) ...[
              const SizedBox(height: 6),
              Text(
                product.monthlyCostUsd > 0
                    ? '💰 Monthly \$${product.monthlyCostUsd.toStringAsFixed(2)}/mo'
                    : '💰 ${l10n.localeName == 'en' ? 'Monthly' : '월'} ${LocalizationUtils.formatCurrency(product.estimatedMonthlyPrice.toDouble(), l10n.localeName)}',
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
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          const DisclaimerBanner(),
          const SizedBox(height: 12),
          if (_isReportLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing your supplements...',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54)),
                  ],
                ),
              ),
            )
          else if (_reportError != null && _detailedReport == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 36),
                  const SizedBox(height: 12),
                  Text(_reportError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.redAccent)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generateReport,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_detailedReport != null) ...[
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
            if (_isReportStreaming)
              AnimatedBuilder(
                animation: _cursorOpacity,
                builder: (context, child) => Opacity(
                  opacity: _cursorOpacity.value,
                  child: const Text('▌',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            if (_reportError != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _generateReport,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_reportError!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.orange)),
                      ),
                      const Icon(Icons.refresh, size: 16, color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
            if (!_isReportStreaming) ...[
              const SizedBox(height: 20),
              _buildPdfActionBar(),
            ],
          ],
        ],
      ),
    );
  }

  /// 상세 리포트 스트리밍 API 호출
  ///
  /// [showPdfPrompt] true이면 리포트 생성 후 PDF 저장 바텀시트를 자동으로 표시한다.
  Future<void> _generateReport({bool showPdfPrompt = false}) async {
    _reportStreamSubscription?.cancel();

    setState(() {
      _isReportUnlocked = true;
      _isReportLoading = true;
      _isReportStreaming = false;
      _detailedReport = null;
      _reportError = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final buffer = StringBuffer();
      final stream = ClaudeReportService()
          .generateReportStream(result, locale: l10n.localeName);

      _reportStreamSubscription = stream.listen(
        (chunk) {
          if (!mounted) return;
          buffer.write(chunk);
          setState(() {
            _isReportLoading = false;
            _isReportStreaming = true;
            _detailedReport = buffer.toString();
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isReportStreaming = false;
            _isReportUnlocked = true;
          });
          if (buffer.isEmpty) {
            setState(() {
              _reportError = 'An error occurred while generating the report.';
            });
          }
          if (showPdfPrompt && _detailedReport != null) {
            _showPdfPromptBottomSheet();
          }
        },
        onError: (Object e) {
          if (!mounted) return;
          final hasPartial = buffer.isNotEmpty;
          setState(() {
            _isReportLoading = false;
            _isReportStreaming = false;
            if (hasPartial) {
              _detailedReport = buffer.toString();
            }
            _reportError = _errorMessage(e, hasPartial);
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isReportLoading = false;
        _isReportStreaming = false;
        _reportError = _errorMessage(e, false);
      });
    }
  }

  /// 에러 타입별 사용자 메시지
  String _errorMessage(Object error, bool hasPartial) {
    if (error is ClaudeTimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is ClaudeApiException) {
      return 'Something went wrong. Please try again.';
    }
    if (error is ClaudeNetworkException) {
      return hasPartial
          ? 'Connection lost. Tap to retry.'
          : 'Connection lost. Tap to retry.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// PDF 내보내기 액션 바
  Widget _buildPdfActionBar() {
    final l10n = AppLocalizations.of(context)!;
    final isKo = l10n.localeName == 'ko';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _isPdfGenerating
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handlePdfExport,
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  isKo ? 'PDF 내보내기' : 'Export PDF',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
    );
  }

  /// PDF 내보내기 처리 (Share sheet)
  Future<void> _handlePdfExport() async {
    if (_detailedReport == null) return;
    final l10n = AppLocalizations.of(context)!;
    final isKo = l10n.localeName == 'ko';

    setState(() => _isPdfGenerating = true);
    try {
      final pdfService = PdfReportService();
      final pdfBytes = await pdfService.generatePdf(
        result: result,
        detailedReport: _detailedReport!,
        locale: l10n.localeName,
      );
      await pdfService.sharePdf(pdfBytes: pdfBytes);
      if (!mounted) return;
      setState(() => _isPdfGenerating = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPdfGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo ? 'PDF 내보내기에 실패했습니다.' : 'Failed to export PDF.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                    onPressed: _hasUnlimitedReports
                        ? () => _generateReport(showPdfPrompt: true)
                        : _showPaymentBottomSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _hasUnlimitedReports
                              ? 'Get Full Report'
                              : l10n.premiumUnlockBtn,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_hasUnlimitedReports)
                          const Text(
                            'Included with Basic',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                              color: Colors.white70,
                            ),
                          ),
                      ],
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

  /// 안전성 이슈 배너 (overlaps 또는 UL 초과)
  Widget _buildSafetyIssuesBanner() {
    final issueCount =
        result.duplicates.length + result.singleProductUlExcess.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFC62828),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            '⚠️ $issueCount safety issue${issueCount > 1 ? 's' : ''} found in your stack',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC62828),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Check the detailed analysis below.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFE53935),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 기전 중복 배너 (functional_overlaps만 있을 때)
  Widget _buildFunctionalOverlapBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.compare_arrows_rounded,
            color: Color(0xFFE65100),
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Similar effects detected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Some supplements have overlapping mechanisms. Check details below.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFF57C00),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// UL 근접 caution 배너 (95~100% UL 도달 시)
  Widget _buildUlAtLimitBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE65100),
            size: 40,
          ),
          SizedBox(height: 12),
          Text(
            'Some nutrients are at the safe upper limit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Check details below.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFF57C00),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 긍정 피드백 배너 (중복/과잉이 없을 때)
  Widget _buildPositiveBanner() {
    // 월간 총 비용 (USD) — monthlyCostUsd 직접 합산
    double totalMonthlyUsd = 0.0;
    for (final p in result.products) {
      totalMonthlyUsd += p.monthlyCostUsd > 0
          ? p.monthlyCostUsd
          : p.estimatedMonthlyPrice / 1400.0;
    }

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
          const Text(
            'Your stack looks good!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'No overlaps or safety issues detected',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF388E3C),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Total: \$${totalMonthlyUsd.toStringAsFixed(2)}/mo',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
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

  /// 결제 완료 후 PDF 내보내기 바텀시트
  void _showPdfPromptBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    final isKo = l10n.localeName == 'ko';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  isKo ? '리포트가 준비되었습니다!' : 'Report is ready!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo ? 'PDF로 내보낼 수 있습니다.' : 'You can export it as a PDF.',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePdfExport();
                    },
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(isKo ? 'PDF 내보내기' : 'Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isKo ? '나중에' : 'Later',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentBottomSheet() {
    final l10n = AppLocalizations.of(context)!;
    // Play Store에서 조회한 실제 가격 사용
    final formattedPrice = _iapService.formattedPrice;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.paymentTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 상세 리포트 포함 내용
                Text(l10n.paymentIncludes,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildPaymentFeatureItem('✨', l10n.paymentItem1),
                _buildPaymentFeatureItem('⚖️', l10n.paymentItem2),
                _buildPaymentFeatureItem('🔄', l10n.paymentItem3),
                _buildPaymentFeatureItem('📄', l10n.paymentItem4),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    _initiatePurchase(); // Start IAP
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B1FA2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    formattedPrice != null
                        ? l10n.payButton(formattedPrice)
                        : l10n.paymentTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.paymentLater,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // ── 신규 UI 섹션: 안전성 경고, 기전 중복, 단일 UL 초과 ──

  Widget _buildSafetyAlertCard(SafetyAlert alert) {
    Color severityColor;
    String severityIcon;
    switch (alert.severity) {
      case 'high':
        severityColor = const Color(0xFFD32F2F);
        severityIcon = '🔴';
        break;
      case 'medium':
      case 'medium-high':
        severityColor = const Color(0xFFF57C00);
        severityIcon = '🟡';
        break;
      default:
        severityColor = const Color(0xFF388E3C);
        severityIcon = '🟢';
    }

    String typeLabel;
    switch (alert.alertType) {
      case 'research_chemical':
        typeLabel = 'Research Chemical';
        break;
      case 'therapeutic_dose':
        typeLabel = 'Therapeutic Dose';
        break;
      case 'otc_drug':
        typeLabel = 'OTC Drug';
        break;
      default:
        typeLabel = 'Safety Alert';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(severityIcon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.product,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(typeLabel,
                    style: TextStyle(fontSize: 11, color: severityColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.summary,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          if (alert.details != null) ...[
            const SizedBox(height: 4),
            Text(alert.details!,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  Widget _buildFunctionalOverlapCard(FunctionalOverlap overlap) {
    Color severityColor;
    switch (overlap.severity) {
      case 'high':
        severityColor = const Color(0xFFD32F2F);
        break;
      case 'medium':
        severityColor = const Color(0xFFF57C00);
        break;
      default:
        severityColor = const Color(0xFF1976D2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  overlap.severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  overlap.pathway,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: overlap.products
                .map((p) => Chip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(overlap.warning,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildUlAtLimitCard(UlAtLimit item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDD835)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.ingredient}: ${item.amount}${item.unit} / UL ${item.ul}${item.unit} (${item.percentageOfUl}%)',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(item.message,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleUlExcessCard(SingleProductUlExcess excess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  excess.product,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${excess.ingredient}: ${excess.amount} > UL ${excess.ul}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                if (excess.warning != null) ...[
                  const SizedBox(height: 2),
                  Text(excess.warning!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필 미입력 유도 배너
  Widget _buildProfileBanner() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_outline,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get personalized analysis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Add your profile for age & medication-specific results',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openProfileSetup,
            child: const Text(
              'Set Up',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: const Icon(Icons.close, color: Colors.black38),
              onPressed: () => setState(() => _showProfileBanner = false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
    );
    if (result == true && mounted) {
      setState(() => _showProfileBanner = false);
    }
  }

  static const String _kReportPurchaseCountKey = 'v1_report_purchase_count';

  /// Free 유저 리포트 구매 횟수 추적 + 1회째 Basic 체험 부여 + 2회째 구독 유도
  Future<void> _trackReportPurchaseAndUpsell() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = (prefs.getInt(_kReportPurchaseCountKey) ?? 0) + 1;
      await prefs.setInt(_kReportPurchaseCountKey, count);

      // 첫 구매 → 30일 Basic 체험 자동 부여
      if (count == 1) {
        await _subscriptionService.grantTrialFromReport();
        if (mounted) {
          setState(() => _hasUnlimitedReports = true);
        }
      }

      if (count == 2 && mounted) {
        // 2회째 구매 → 구독 유도 (분석 리포트 표시 후 약간 지연)
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaywallScreen(
              trigger: PaywallTrigger.reportUpsell,
              amountSpent: count * 1.99,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _initiatePurchase() async {
    setState(() {
      _isReportLoading = true;
      _reportError = null;
    });

    final success = await _iapService.buyDetailedReport();
    if (!success) {
      if (!mounted) return;
      setState(() {
        _isReportLoading = false;
      });
    }
  }
}
