import 'package:flutter/material.dart';
import 'package:myapp/models/unified_analysis_result.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';
import 'package:myapp/services/report_purchase_service.dart';

class PaidReportSection extends StatefulWidget {
  final UnifiedAnalysisResult result;

  const PaidReportSection({super.key, required this.result});

  @override
  State<PaidReportSection> createState() => _PaidReportSectionState();
}

class _PaidReportSectionState extends State<PaidReportSection> {
  final ReportPurchaseService _purchaseService = ReportPurchaseService();
  final GeminiAnalyzerService _analyzerService = GeminiAnalyzerService();

  bool _isPurchased = false;
  bool _isLoading = false;
  String? _content;
  String? _errorMessage;
  String? _formattedPrice;

  @override
  void initState() {
    super.initState();
    _loadPrice();
    _checkPurchaseStatus();

    // Listen to purchase events
    _purchaseService.onPurchaseSuccess = (id) {
      if (id == widget.result.id && mounted) {
        setState(() {
          _isPurchased = true;
        });
        _generateReport();
      }
    };

    _purchaseService.onPurchaseError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    };
  }

  @override
  void dispose() {
    // Clean up callbacks to avoid memory leaks or unwanted calls
    _purchaseService.onPurchaseSuccess = null;
    _purchaseService.onPurchaseError = null;
    super.dispose();
  }

  Future<void> _loadPrice() async {
    await _purchaseService.loadPrice();
    if (mounted) {
      setState(() {
        _formattedPrice = _purchaseService.formattedPrice;
      });
    }
  }

  Future<void> _checkPurchaseStatus() async {
    // TODO: 스크린샷 후 원복 필요! 임시로 결제 우회
    if (mounted) {
      setState(() {
        _isPurchased = true;
      });
      _generateReport();
    }
    // --- 원본 코드 (스크린샷 후 아래로 교체) ---
    // final purchased =
    //     await _purchaseService.isReportPurchased(widget.result.id);
    // if (mounted) {
    //   setState(() {
    //     _isPurchased = purchased;
    //     if (_isPurchased) {
    //       if (widget.result.premiumReport != null &&
    //           widget.result.premiumReport!.isNotEmpty) {
    //         _content = widget.result.premiumReport;
    //       } else {
    //         _generateReport();
    //       }
    //     }
    //   });
    // }
  }

  Future<void> _generateReport() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report =
          await _analyzerService.generatePremiumReport(widget.result);
      if (mounted) {
        setState(() {
          _content = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "리포트 생성에 실패했습니다. (${e.toString()})";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_isPurchased && _content != null) {
      return _buildReportContent();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildPaywall();
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.purple),
          SizedBox(height: 24),
          Text(
            "🔄 리포트 생성 중...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "약 10초 정도 소요됩니다",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateReport,
            child: const Text("다시 시도"),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.purple.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome,
                    size: 20, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              const Text("AI 성분 분석 리포트",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _content ?? "",
            style: const TextStyle(
                fontSize: 15, height: 1.6, color: Color(0xFF424242)),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                  child: Text("본 분석 결과는 AI에 의한 것으로 의학적 진단을 대신할 수 없습니다.",
                      style: TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPaywall() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("✨ AI 상세 분석 리포트",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0B2), // Orange 100
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formattedPrice ?? '...',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF6C00)), // Orange 800
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Lock Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 32, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Price & Desc
                Text(_formattedPrice ?? '...',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B1FA2))), // Purple 700
                const Text("1회 결제로 영구 열람",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Benefits
                _buildBenefitItem("성분별 효능 상세 분석"),
                _buildBenefitItem("최적 섭취 타이밍 추천"),
                _buildBenefitItem("시너지/상충 성분 안내"),

                const SizedBox(height: 32),

                // Buy Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      _purchaseService.buyReport(widget.result.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0), // Purple 500
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "💳 결제하고 열람하기",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("안전한 Google Play 결제",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: Color(0xFF4CAF50)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
