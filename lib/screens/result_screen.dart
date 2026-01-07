
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart';

// [New] Model for a single detected item
class DetectedItem {
  final int id;
  final String brandName;
  final String productName;
  final String keyIngredients;
  final String confidenceLevel;
  final int estimatedPrice;

  DetectedItem({
    required this.id,
    required this.brandName,
    required this.productName,
    required this.keyIngredients,
    required this.confidenceLevel,
    required this.estimatedPrice,
  });

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      id: json['id'] ?? 0,
      brandName: json['brand_name'] ?? '알수없음',
      productName: json['product_name'] ?? '제품명 불명',
      keyIngredients: json['key_ingredients'] ?? '확인필요',
      confidenceLevel: json['confidence_level'] ?? 'low',
      estimatedPrice: json['estimated_price'] ?? 0,
    );
  }
}

// [New] Model for the entire API response
class AnalysisResponse {
  final List<DetectedItem> detectedItems;
  final int totalCount;
  final String summary;
  final int totalSavingAmount;

  AnalysisResponse({
    required this.detectedItems,
    required this.totalCount,
    required this.summary,
    required this.totalSavingAmount,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = json['detected_items'] as List<dynamic>? ?? [];
    List<DetectedItem> items =
        itemsList.map((i) => DetectedItem.fromJson(i)).toList();
    
    // Calculate total saving amount from the list
    int totalSavings = items.fold(0, (sum, item) => sum + item.estimatedPrice);

    return AnalysisResponse(
      detectedItems: items,
      totalCount: json['total_count'] ?? 0,
      summary: json['summary'] ?? '분석이 완료되었습니다.',
      totalSavingAmount: totalSavings,
    );
  }
}


// --- Color Constants ---
const Color kLoadingIndicatorColor = Color(0xFF2E7D32);
const Color kAppBarBackgroundColor = Colors.white;
const Color kAppBarForegroundColor = Colors.black;
const Color kBodyTextColor = Colors.grey;
const Color kErrorTextColor = Colors.red;
const Color kSummaryTextColor = Colors.black87;
const Color kSavingCardBackgroundColor = Color(0xFFFFF8E1);
const Color kSavingCardBorderColor = Color(0xFFFFB300);
const Color kSavingCardTitleColor = Color(0xFF8D6E63);
const Color kSavingAmountIconColor = Color(0xFFFF6F00);
const Color kSavingAmountTextColor = Color(0xFFE65100);
const Color kDisclaimerBackgroundColor = Color(0xFFE8F5E9);
const Color kDisclaimerTextColor = Colors.grey;


class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  AnalysisResponse? _analysisResult; // [Updated] Use the new response model
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final File imageFile = File(widget.imagePath);
      final jsonString = await ApiService.analyzeDrugImage(imageFile);

      // [Updated] Ensure JSON is cleaned before parsing
      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> result = jsonDecode(cleanJson);

      if (mounted) {
        setState(() {
          // [Updated] Parse into the new response model
          _analysisResult = AnalysisResponse.fromJson(result);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "분석 중 오류가 발생했습니다.\n다시 시도해주세요. ($e)";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: kAppBarBackgroundColor,
        foregroundColor: kAppBarForegroundColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kLoadingIndicatorColor),
            SizedBox(height: 20),
            Text(
              "약비서가 꼼꼼하게\n성분을 확인하고 있어요... 🔍",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: kBodyTextColor),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kErrorTextColor)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Summary Text
          Text(
            _analysisResult?.summary ?? "분석이 완료되었습니다.",
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kSummaryTextColor),
          ),
          const SizedBox(height: 20),

          // 2. [Updated] Saving Card
          _buildSavingCard(),

          const SizedBox(height: 30),

          // 3. [New] Detected Items List
          Text("총 ${_analysisResult?.totalCount ?? 0}개의 영양제 발견", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _analysisResult?.detectedItems.length ?? 0,
            itemBuilder: (context, index) {
              final item = _analysisResult!.detectedItems[index];
              return _buildDetectedItemCard(item);
            },
          ),

          const SizedBox(height: 40),

          // 4. Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDisclaimerBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '※ 본 결과는 식약처 데이터를 기반으로 한 정보 제공이며, 의학적 진단을 대신할 수 없습니다. 정확한 판단은 의사/약사와 상의하세요.',
              style: TextStyle(fontSize: 12, color: kDisclaimerTextColor),
            ),
          ),
        ],
      ),
    );
  }

  // [Updated] Saving Card Widget
  Widget _buildSavingCard() {
    final int savingAmount = _analysisResult?.totalSavingAmount ?? 0;

    if (savingAmount <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSavingCardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kSavingCardBorderColor, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            "이번 달 예상 절약 금액",
            style: TextStyle(
                fontSize: 14,
                color: kSavingCardTitleColor,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.savings_rounded,
                  color: kSavingAmountIconColor, size: 32),
              const SizedBox(width: 8),
              Text(
                "${savingAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: kSavingAmountTextColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "불필요한 중복 영양제를 줄여보세요!",
            style: TextStyle(fontSize: 12, color: kSavingCardTitleColor),
          )
        ],
      ),
    );
  }

  // [New] Detected Item Card Widget
  Widget _buildDetectedItemCard(DetectedItem item) {
    final bool isHighConfidence = item.confidenceLevel == 'high';
    final IconData icon = isHighConfidence ? Icons.check_circle_rounded : Icons.help_outline_rounded;
    final Color iconColor = isHighConfidence ? Colors.green.shade700 : Colors.red.shade700;
    final String title = isHighConfidence ? item.productName : "인식 실패 (터치해서 수정)";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                children: [
                  TextSpan(text: "브랜드: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: "${item.brandName}\n"),
                  TextSpan(text: "주요성분: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: item.keyIngredients),
                ]
              )
            ),
             if (item.estimatedPrice > 0) ...[
                const SizedBox(height: 8),
                 Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "예상가: ${item.estimatedPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSavingAmountTextColor),
                  ),
                )
             ]
          ],
        ),
      ),
    );
  }
}
