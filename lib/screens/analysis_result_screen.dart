import 'package:flutter/material.dart';
import 'package:myapp/models/unified_analysis_result.dart';
import 'package:myapp/models/pill.dart';
import 'package:myapp/services/my_pill_service.dart';
import 'package:myapp/widgets/expandable_product_card.dart';
import 'package:myapp/widgets/savings_banner.dart';
import 'package:myapp/widgets/warning_banner.dart';
import 'package:myapp/l10n/app_localizations.dart';

class AnalysisResultScreen extends StatefulWidget {
  final UnifiedAnalysisResult result;

  const AnalysisResultScreen({
    super.key,
    required this.result,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final Set<String> _addedPillNames = {};
  bool _isReportExpanded = true; // Default expanded
  bool _isPremiumUnlocked = false; // Dev/MVP: Unlock premium report

  Future<void> _handleSavePill(UnifiedProduct product) async {
    final newPill = KoreanPill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: product
          .name, // UnifiedProduct has name (no nameKo separate field in user prompt, maybe check prompt)
      brand: product.brand,
      dailyDosage:
          '', // prompt didn't strictly have serving_size in Products list? Wait.
      category: 'General',
      ingredients: product.ingredients
          .map(
              (i) => i.amount > 0 ? '${i.name} (${i.amount}${i.unit})' : i.name)
          .join(', '),
      imageUrl: '',
    );

    final result = await MyPillService.savePill(newPill);
    if (mounted) {
      setState(() {
        _addedPillNames.add(newPill.name);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == 0
              ? AppLocalizations.of(context)!.addedToCabinet
              : AppLocalizations.of(context)!.alreadyInCabinet),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final analysis = widget.result.analysis;
    final productsUI = widget.result.productsUI;
    final rawProducts = widget.result.products;

    // Collect excluded product names for banner
    final excludedNames = productsUI
        .where((p) => p.status == 'danger')
        .map((p) => p.name)
        .toList();

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
                // 1. Savings Banner
                SavingsBanner(
                  bannerType: analysis.bannerType,
                  monthlySavings: analysis.monthlySavings,
                  yearlySavings: analysis.yearlySavings,
                  exclusionReason: analysis.exclusionReason ?? '',
                  excludedProductNames: excludedNames,
                ),

                // 2. Warning Banners
                ...analysis.overLimitIngredients
                    .map((ingredient) => WarningBanner(
                          ingredientName: ingredient.name,
                          currentAmount:
                              "${ingredient.total}${ingredient.unit}",
                          limitAmount: "${ingredient.limit}${ingredient.unit}",
                        )),

                const SizedBox(height: 10),

                // 3. Product List
                const Text("분석 결과 확인",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productsUI.length,
                  itemBuilder: (context, index) {
                    final uiProduct = productsUI[index];
                    // Find detailed info
                    final rawProduct = rawProducts.firstWhere(
                      (p) =>
                          p.name.trim().toLowerCase() ==
                              uiProduct.name.trim().toLowerCase() ||
                          (uiProduct.name.contains(p.name) ||
                              p.name.contains(uiProduct.name)),
                      orElse: () => UnifiedProduct(
                          brand: uiProduct.brand,
                          name: uiProduct.name,
                          ingredients: [],
                          estimatedMonthlyPrice: 0),
                    );

                    final isAdded = _addedPillNames.contains(uiProduct.name);
                    final isRedundant = uiProduct.status == 'danger';

                    // Tags
                    final tags = <String>[];
                    if (uiProduct.tag != null) tags.add(uiProduct.tag!);

                    String ingredientsSummary = rawProduct.ingredients
                        .map((i) => i.amount > 0
                            ? '${i.name} (${i.amount}${i.unit})'
                            : i.name)
                        .join(', ');

                    return ExpandableProductCard(
                      status: uiProduct.status,
                      brand: uiProduct.brand,
                      name: uiProduct.name,
                      price: "",
                      imageUrl: null,
                      tags: tags,
                      ingredients: ingredientsSummary,
                      dosage: rawProduct.dosage ?? "섭취방법 정보 없음",
                      isAdded: isAdded,
                      onAdd: () => _handleSavePill(rawProduct),
                      isRecommendedToRemove: isRedundant,
                      removalSavingsAmount: uiProduct.monthlyPrice,
                      originalPrice: rawProduct.originalPrice,
                      durationMonths: rawProduct.durationMonths,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 4. Collapsible AI Report
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Toggle expanded state logic if we want to allow user to try to open it
                          // For now, let's keep it 'open' but blurred at bottom
                          setState(() {
                            _isReportExpanded = !_isReportExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.auto_awesome,
                                    size: 20, color: Colors.purple),
                              ),
                              const SizedBox(width: 12),
                              const Text("AI 성분 분석 리포트",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Icon(
                                  _isReportExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      if (_isReportExpanded)
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              // Limit height if not unlocked
                              height: _isPremiumUnlocked ? null : 150,
                              child: Text(
                                // Remove greeting if present manually just in case
                                widget.result.premiumReport
                                    .replaceAll(
                                        RegExp(r'^안녕하세요.*?\n',
                                            multiLine: true, dotAll: true),
                                        '')
                                    .trim(),
                                style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: Color(0xFF424242)),
                                maxLines: _isPremiumUnlocked ? null : 5,
                                overflow: _isPremiumUnlocked
                                    ? TextOverflow.visible
                                    : TextOverflow.fade,
                              ),
                            ),
                            // Blur Overlay & Lock (Show only if NOT unlocked)
                            if (!_isPremiumUnlocked) ...[
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.4, 1.0],
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.5),
                                        Colors.white.withValues(alpha: 1.0),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(16)),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.lock_rounded,
                                            size: 24, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Dev Mode: Unlock immediately
                                          setState(() {
                                            _isPremiumUnlocked = true;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "DEV MODE: 프리미엄 리포트가 해제되었습니다.")),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                        ),
                                        child:
                                            const Text("전체 리포트 열람하기 (Premium)"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 5. Disclaimer
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
                  child: const Text(
                    "홈으로 돌아가기",
                    style: TextStyle(
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
}
