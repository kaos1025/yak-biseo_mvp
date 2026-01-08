import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/api_service.dart';

// [Updated] Model matching 'Group Shot' JSON schema
class DetectedItem {
  final int id;
  final String name; // Combined Brand + Product Name
  final String status; // SAFE, REDUNDANT, WARNING
  final String desc; // Description / Reason
  final int price; // Estimated Price

  DetectedItem({
    required this.id,
    required this.name,
    required this.status,
    required this.desc,
    required this.price,
  });

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '제품명 확인 불가',
      status: json['status'] ?? 'SAFE',
      desc: json['desc'] ?? '',
      price: json['price'] ?? 0,
    );
  }
}

// Model for the entire API response
class AnalysisResponse {
  final List<DetectedItem> detectedItems;
  final String summary;
  final int totalSavingAmount;

  AnalysisResponse({
    required this.detectedItems,
    required this.summary,
    required this.totalSavingAmount,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = json['detected_items'] as List<dynamic>? ?? [];
    List<DetectedItem> items =
        itemsList.map((i) => DetectedItem.fromJson(i)).toList();

    return AnalysisResponse(
      detectedItems: items,
      summary: json['summary'] ?? '분석이 완료되었습니다.',
      totalSavingAmount: json['total_saving_amount'] ?? 0,
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
  final XFile image;

  const ResultScreen({super.key, required this.image});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  AnalysisResponse? _analysisResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      final jsonString = await ApiService.analyzeDrugImage(widget.image);
      final cleanJson =
          jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> result = jsonDecode(cleanJson);

      if (mounted) {
        setState(() {
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
              "여러 개의 영양제를 한 번에\n분석하고 있어요... 💊",
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

          // 2. Saving Card
          _buildSavingCard(),

          if ((_analysisResult?.totalSavingAmount ?? 0) > 0)
            const SizedBox(height: 30),

          // 3. Detected Items List
          Text("발견된 제품 목록 (${_analysisResult?.detectedItems.length ?? 0}개)",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            "중복된 영양제만 줄여도 돈이 모여요!",
            style: TextStyle(fontSize: 12, color: kSavingCardTitleColor),
          )
        ],
      ),
    );
  }

  Widget _buildDetectedItemCard(DetectedItem item) {
    // Check status
    final bool isWarning =
        item.status == 'WARNING' || item.status == 'REDUNDANT';

    // Define colors based on requirements
    final Color bgColor = isWarning ? Colors.orange[50]! : Colors.green[50]!;
    final Color titleColor =
        isWarning ? Colors.deepOrange : Colors.green.shade900;
    final Color textColor = isWarning ? Colors.brown : Colors.black87;
    final IconData icon =
        isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline;
    final Color iconColor = isWarning ? Colors.orange : Colors.green;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isWarning
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name, // Display Name
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: titleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description / Reason
            Text(
              item.desc,
              style: TextStyle(fontSize: 14, color: textColor),
            ),

            if (item.price > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "예상가: ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.8)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
