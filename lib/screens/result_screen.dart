import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/screens/analyzing_screen.dart';
import 'package:myapp/theme/app_theme.dart';

// [모델 클래스]
class DetectedItem {
  final String id;
  final String name;
  final String status; // SAFE, REDUNDANT, WARNING
  final String desc;
  final int price;

  DetectedItem({
    required this.id,
    required this.name,
    required this.status,
    required this.desc,
    required this.price,
  });

  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    return DetectedItem(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? '제품명 확인 불가',
      status: json['status'] ?? 'SAFE',
      desc: json['desc'] ?? '',
      price: json['price'] ?? 0,
    );
  }
}

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
    // 2. 분석 중일 때 전용 로딩 화면 표시
    if (_isLoading) {
      return const AnalyzingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _analyzeImage();
                },
                child: const Text("다시 시도"),
              )
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3. 총 절약 금액 카드 (가장 크게 강조)
          _buildTotalSavingCard(),
          const SizedBox(height: 24),

          // 요약 텍스트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _analysisResult?.summary ?? "분석 완료",
              style: const TextStyle(
                  fontSize: 16, height: 1.5, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 30),

          // 발견된 항목 타이틀
          Text(
            "발견된 제품 목록 (${_analysisResult?.detectedItems.length ?? 0}개)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          // 3. 아이템 리스트 (접이식 UI 적용)
          if (_analysisResult != null)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analysisResult!.detectedItems.length,
              itemBuilder: (context, index) {
                final item = _analysisResult!.detectedItems[index];
                return _ResultItemCard(item: item);
              },
            ),

          const SizedBox(height: 40),

          // 4. Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '본 결과는 AI 분석 결과이며, 정확한 의학적 판단은 의사/약사와 상의하세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTotalSavingCard() {
    final int savingAmount = _analysisResult?.totalSavingAmount ?? 0;
    if (savingAmount <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
            SizedBox(height: 10),
            Text(
              "중복된 영양제가 없습니다!",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "지금처럼 잘 챙겨드세요 :)",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      color: AppTheme.primaryColor, // Deep Green
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            const Text(
              "이번 달 예상 절약 금액",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings,
                    color: AppTheme.accentColor, size: 36),
                const SizedBox(width: 8),
                Text(
                  "${savingAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                  style: const TextStyle(
                    color: AppTheme.accentColor, // Amber (Highlight)
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text(
                "📉 중복 섭취를 줄여서 건강과 지갑을 지켰어요!",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [리팩토링] 접이식 디자인 아이템 카드 위젯
class _ResultItemCard extends StatefulWidget {
  final DetectedItem item;
  const _ResultItemCard({required this.item});

  @override
  State<_ResultItemCard> createState() => _ResultItemCardState();
}

class _ResultItemCardState extends State<_ResultItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool isWarning =
        item.status == 'WARNING' || item.status == 'REDUNDANT';

    // 스타일 정의
    final Color bgColor = isWarning ? Colors.orange.shade50 : Colors.white;
    final Color borderColor =
        isWarning ? Colors.orange.shade200 : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          )
        ],
      ),
      child: Theme(
        // ExpansionTile의 기본 Divider 제거 및 스타일 조정
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          // 뱃지와 제품명
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWarning ? Colors.orange : AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isWarning ? "중복" : "안전",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isWarning ? Colors.black : Colors.black87),
                ),
              ),
            ],
          ),
          // 핵심 요약 (닫힌 상태 서브타이틀)
          subtitle: !_isExpanded
              ? Text(
                  item.desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      color: isWarning ? Colors.black87 : Colors.grey[800]),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.price > 0 && !_isExpanded)
                Text(
                  "${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                  style: TextStyle(
                      fontSize: 15,
                      color: isWarning ? Colors.black : Colors.grey[700],
                      fontWeight: FontWeight.w700),
                ),
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: isWarning ? Colors.black54 : Colors.grey,
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text(
                    item.desc,
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Color(0xFF424242),
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                  if (item.price > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      "예상 가격: ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 15,
                          color: isWarning ? Colors.black : Colors.grey[800],
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
