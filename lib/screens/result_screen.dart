import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ApiService import 확인

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  // 1. 이미지 분석 요청 함수
  Future<void> _analyzeImage() async {
    try {
      final File imageFile = File(widget.imagePath);
      
      // API 호출 (정적 메서드 직접 호출로 변경)
      final jsonString = await ApiService.analyzeDrugImage(imageFile);
      
      // JSON 파싱
      // AI가 가끔 마크다운 ```json ... ``` 을 붙일 때가 있어서 제거해줌
      final cleanJson = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> result = jsonDecode(cleanJson);

      if (mounted) {
        setState(() {
          _analysisResult = result;
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // A. 로딩 중일 때
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFF2E7D32)),
            SizedBox(height: 20),
            Text(
              "약비서가 꼼꼼하게\n성분을 확인하고 있어요... 🔍",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // B. 에러 났을 때
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    // C. 결과 보여주기
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 3줄 요약 멘트
          Text(
            _analysisResult?['summary'] ?? "분석이 완료되었습니다.",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // 🌟 2. [핵심 기능] 돈 낭비 방지 카드 (절약 금액이 있을 때만 표시)
          _buildSavingCard(),
          
          const SizedBox(height: 20),

          // 3. 상세 분석 카드 리스트
          ...(_analysisResult?['cards'] as List? ?? []).map((card) {
            return _buildResultCard(card);
          }).toList(),

          const SizedBox(height: 40),
          
          // 4. 면책 조항 (필수)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '※ 본 결과는 식약처 데이터를 기반으로 한 정보 제공이며, 의학적 진단을 대신할 수 없습니다. 정확한 판단은 의사/약사와 상의하세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // 💰 절약 금액 카드 위젯
  Widget _buildSavingCard() {
    // JSON에서 total_saving_amount 가져오기 (없으면 0원)
    int savingAmount = _analysisResult?['total_saving_amount'] ?? 0;

    // 절약할 돈이 없으면 화면에 안 그림 (빈 박스 리턴)
    if (savingAmount <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // 연한 노란색 배경
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB300), width: 2), // 진한 노란 테두리
      ),
      child: Column(
        children: [
          const Text(
            "이번 달 예상 절약 금액",
            style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.savings_rounded, color: Color(0xFFFF6F00), size: 32),
              const SizedBox(width: 8),
              Text(
                // 3자리마다 콤마 찍기 로직
                "${savingAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원",
                style: const TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFFE65100)
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "불필요한 중복 영양제를 줄여보세요!",
            style: TextStyle(fontSize: 12, color: Color(0xFF8D6E63)),
          )
        ],
      ),
    );
  }

  // 🚦 개별 분석 카드 위젯
  Widget _buildResultCard(Map<String, dynamic> cardData) {
    Color cardColor;
    Color titleColor;
    IconData icon;

    // 카드 타입에 따른 색상 분기
    String type = (cardData['type'] ?? 'INFO').toString().toUpperCase();
    
    if (type == 'WARNING' || type == 'RED') {
      cardColor = const Color(0xFFFFEBEE); // 연한 빨강
      titleColor = const Color(0xFFC62828); // 진한 빨강
      icon = Icons.warning_rounded;
    } else if (type == 'CAUTION' || type == 'YELLOW') {
      cardColor = const Color(0xFFFFF3E0); // 연한 주황
      titleColor = const Color(0xFFEF6C00); // 진한 주황
      icon = Icons.info_rounded;
    } else { // SAFE or GREEN
      cardColor = const Color(0xFFE8F5E9); // 연한 초록
      titleColor = const Color(0xFF2E7D32); // 진한 초록
      icon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: titleColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cardData['title'] ?? '',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: titleColor
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cardData['content'] ?? '',
            style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
