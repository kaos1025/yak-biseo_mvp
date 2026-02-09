import 'package:flutter/material.dart';
import 'package:myapp/models/supplement_analysis.dart';
import 'package:myapp/models/pill.dart';
import 'package:myapp/services/my_pill_service.dart';
import 'package:myapp/widgets/expandable_product_card.dart';
import 'package:myapp/widgets/savings_banner.dart';
import 'package:myapp/widgets/warning_banner.dart';
import 'package:myapp/l10n/app_localizations.dart';

class AnalysisResultScreen extends StatefulWidget {
  final AnalyzeResult result;
  final String report;

  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.report,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final Set<String> _addedPillNames = {};
  final Map<String, String> _productStatus = {}; // SAFE, WARNING, REDUNDANT
  final Set<String> _excludedPills = {}; // Set of product names to exclude
  List<String> _redundantItemNames = []; // Names of redundant items for banner
  bool _isReportExpanded = true;
  int _totalSavings = 0;

  @override
  void initState() {
    super.initState();
    _checkRedundancy();
    _parseReportForWarnings(); // Placeholder for future advanced parsing
  }

  Future<void> _checkRedundancy() async {
    // Initialize all products as SAFE
    // REDUNDANT status is determined ONLY by AI report analysis (업로드된 사진만 기준)
    if (!mounted) return;

    setState(() {
      for (var product in widget.result.products) {
        _productStatus[product.name] = 'SAFE';
      }
      _totalSavings = 0;
      _redundantItemNames = [];
    });

    // Parse AI Report - the ONLY source of truth for REDUNDANT and savings
    _parseReportAndApplyRecommendations();
  }

  void _parseReportAndApplyRecommendations() {
    final report = widget.report;
    if (report.length < 20) return;

    // Find the exclusion section in the report
    final exclusionStart = report.indexOf('제외 권장');
    if (exclusionStart == -1) return;

    // Get text from "제외 권장" to end of report or next major section
    String exclusionSection = report.substring(exclusionStart);
    final nextSection = RegExp(r'###\s*3\.').firstMatch(exclusionSection);
    if (nextSection != null) {
      exclusionSection = exclusionSection.substring(0, nextSection.start);
    }

    // Normalize for comparison (remove special chars, lowercase)
    final exclusionLower = exclusionSection
        .replaceAll(RegExp(r'[*\[\]()&\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    // Extract savings amount from entire report
    int? parsedSavings;
    final savingsMatch =
        RegExp(r'월간?\s*절[약감]\s*가능?\s*금액\s*[:：]?\s*([\d,]+)\s*원')
            .firstMatch(report);
    if (savingsMatch != null) {
      final savingsStr = savingsMatch.group(1)?.replaceAll(',', '');
      parsedSavings = int.tryParse(savingsStr ?? '');
    }

    // For each product, check if it's mentioned in the exclusion section
    for (var product in widget.result.products) {
      if (_productStatus[product.name] == 'REDUNDANT') continue;

      bool isExcluded = false;

      // Prepare search terms from product
      final searchTerms = <String>[];

      // Add full name (English)
      final nameLower = product.name
          .toLowerCase()
          .replaceAll(RegExp(r'[&\-]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (nameLower.length > 3) searchTerms.add(nameLower);

      // Add Korean name
      if (product.nameKo != null && product.nameKo!.isNotEmpty) {
        final nameKoLower = product.nameKo!
            .toLowerCase()
            .replaceAll(RegExp(r'[&\-]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (nameKoLower.length > 3) searchTerms.add(nameKoLower);
      }

      // Add brand + name combination
      if (product.brand != null) {
        final brandName = '${product.brand!.toLowerCase()} ${nameLower}'.trim();
        searchTerms.add(brandName);
      }

      // Check if any search term appears in exclusion section
      for (var term in searchTerms) {
        if (exclusionLower.contains(term)) {
          isExcluded = true;
          break;
        }
      }

      // If not found, try matching individual significant words
      if (!isExcluded) {
        // Split all terms into words and check for multiple matches
        final allWords = searchTerms
            .join(' ')
            .split(' ')
            .where((w) => w.length >= 3)
            .toSet();

        int matchCount = 0;
        for (var word in allWords) {
          if (exclusionLower.contains(word)) {
            matchCount++;
          }
        }

        // If 2+ significant words match, consider it excluded
        if (matchCount >= 2) {
          isExcluded = true;
        }
      }

      if (isExcluded) {
        if (!mounted) return;

        setState(() {
          _productStatus[product.name] = 'REDUNDANT';

          if (!_redundantItemNames.contains(product.nameKo ?? product.name)) {
            int savings = parsedSavings ?? 0;
            if (savings == 0) {
              if (product.monthlyPrice != null && product.monthlyPrice! > 0) {
                savings = product.monthlyPrice!;
              } else if (product.estimatedPrice != null &&
                  product.estimatedPrice! > 0) {
                savings = (product.estimatedPrice! /
                        (product.supplyPeriodMonths ?? 1))
                    .round();
              } else {
                savings = 5500;
              }
            }

            _totalSavings += savings;
            _redundantItemNames.add(product.nameKo ?? product.name);
          }
        });
      }
    }
  }

  void _parseReportForWarnings() {
    // TODO: Parse the "⚠️ 주의 성분" section from widget.report string
  }

  Future<void> _handleSavePill(Product product) async {
    final newPill = KoreanPill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: product.nameKo ?? product.name,
      brand: product.brand,
      dailyDosage: product.servingSize,
      category: 'General',
      ingredients: product.ingredients
          .map((i) => '${i.nameKo ?? i.name} (${i.amount}${i.unit})')
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

    // Sort products: REDUNDANT -> WARNING -> SAFE
    final sortedProducts = List<Product>.from(widget.result.products);
    sortedProducts.sort((a, b) {
      final statusA = _productStatus[a.name] ?? 'SAFE';
      final statusB = _productStatus[b.name] ?? 'SAFE';

      int score(String s) {
        if (s == 'REDUNDANT') return 0;
        if (s == 'WARNING') return 1;
        return 2;
      }

      return score(statusA).compareTo(score(statusB));
    });

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
                left: 20,
                right: 20,
                top: 20,
                bottom: 100), // Add bottom padding for button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Savings Banner
                SavingsBanner(
                  savingAmount: _totalSavings,
                  excludedProductNames: _redundantItemNames,
                ),

                // 2. Warning Banners (Mock for Demo/Parsing placeholder)
                if (widget.report.contains("주의 성분") &&
                    widget.report.contains("마그네슘"))
                  const WarningBanner(
                    ingredientName: "마그네슘",
                    currentAmount: "595mg",
                    limitAmount: "350mg",
                  ),

                const SizedBox(height: 10),

                // 3. Product List
                const Text("분석 결과 확인",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedProducts.length,
                  itemBuilder: (context, index) {
                    final product = sortedProducts[index];
                    final status = _productStatus[product.name] ?? 'SAFE';
                    final isAdded = _addedPillNames
                        .contains(product.nameKo ?? product.name);

                    // Tags
                    final tags = <String>[];
                    if (status == 'SAFE') tags.add(l10n.tagVerified);
                    if (status == 'WARNING') tags.add(l10n.tagDuplicateWarning);
                    if (status == 'REDUNDANT') tags.add(l10n.redundant);

                    final tagColors = {
                      l10n.tagVerified: const Color(0xFFE8F5E9),
                      l10n.tagDuplicateWarning: const Color(0xFFFFF3E0),
                      l10n.redundant: const Color(0xFFFFEBEE),
                    };
                    final tagTextColors = {
                      l10n.tagVerified: const Color(0xFF2E7D32),
                      l10n.tagDuplicateWarning: const Color(0xFFE65100),
                      l10n.redundant: const Color(0xFFC62828),
                    };

                    // Recommendation Logic
                    final isRedundant = status == 'REDUNDANT';
                    int mockSavings = 0;

                    if (product.monthlyPrice != null &&
                        product.monthlyPrice! > 0) {
                      mockSavings = product.monthlyPrice!;
                    } else if (product.estimatedPrice != null &&
                        product.estimatedPrice! > 0) {
                      mockSavings = (product.estimatedPrice! /
                              (product.supplyPeriodMonths ?? 1))
                          .round();
                    } else {
                      // Mock Price for demo
                      mockSavings = 5500;
                      if (product.name.contains("Omega"))
                        mockSavings =
                            35000; // Keep high for visible test? No, adhere to monthly.
                      if (product.name.contains("Vitamin")) mockSavings = 4000;
                      if (product.name.contains("Magnesium"))
                        mockSavings = 5500;
                    }

                    Color? cardBgColor = Colors.white;
                    if (isRedundant) cardBgColor = const Color(0xFFFFEBEE);

                    String ingredientsSummary = product.ingredients
                        .map((i) =>
                            '${i.nameKo ?? i.name} (${i.amount}${i.unit})')
                        .join(', ');

                    return ExpandableProductCard(
                      backgroundColor: cardBgColor,
                      brand: product.brand,
                      name: product.nameKo ?? product.name,
                      price: "", // Hide price
                      tags: tags,
                      tagColors: tagColors,
                      tagTextColors: tagTextColors,
                      ingredients: ingredientsSummary,
                      dosage: product.servingSize,
                      isAdded: isAdded,
                      onAdd: () => _handleSavePill(product),
                      // New Properties
                      isRecommendedToRemove: isRedundant,
                      removalSavingsAmount: mockSavings,
                      onRemoveCheckChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _excludedPills.add(product.name);
                          } else {
                            _excludedPills.remove(product.name);
                          }
                        });
                      },
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
                              const Text("AI 상세 분석 리포트",
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: SelectableText(
                            widget.report,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Color(0xFF424242)),
                          ),
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
