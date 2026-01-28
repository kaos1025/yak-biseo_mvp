import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/expandable_product_card.dart';

class AnalysisScreen extends StatelessWidget {
  final XFile? image;

  const AnalysisScreen({super.key, this.image});

  static const Color medicalGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4CAF50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "분석 결과",
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Global Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FBF4), Color(0xFFE8F5E9)],
              ),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                children: [
                  _buildSavingsCard(),
                  const SizedBox(height: 20),
                  _buildAiSummary(),
                  const SizedBox(height: 32),
                  _buildProductListHeader(),
                  const SizedBox(height: 12),
                  _buildMockProductList(),
                ],
              ),
            ),
          ),
          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDD835), Color(0xFFFFCA28)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFDD835).withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "이번 달 예상 절약 금액",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: const [
                            Text(
                              "18,000",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            Text(
                              "원",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.savings_rounded,
                          color: Color(0xFF2E7D32), size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "동일 성분 제품을 더 저렴하게 구매할 수 있어요!",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              const Icon(Icons.auto_awesome,
                  size: 18, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                "AI 분석 요약",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "촬영된 약통에서 총 4개의 영양제를 발견했습니다.\n'오메가3' 제품이 기존 복용 중인 영양제와 성분이 중복될 가능성이 있어 주의가 필요합니다.",
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListHeader() {
    return Row(
      children: const [
        const Icon(Icons.inventory_2_outlined,
            color: Color(0xFF2E7D32), size: 20),
        SizedBox(width: 8),
        Text(
          "발견된 제품 목록 (4개)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _buildMockProductList() {
    final products = [
      {
        "brand": "종근당건강",
        "name": "락토핏 생유산균 골드",
        "price": "15,900원",
        "tags": ["식약처 인증", "AI 분석 결과"],
      },
      {
        "brand": "California Gold",
        "name": "Omega-3 Premium Fish Oil",
        "price": "24,000원",
        "tags": ["중복 경고", "해외 직구"],
      },
      {
        "brand": "고려은단",
        "name": "비타민C 1000",
        "price": "12,000원",
        "tags": ["식약처 인증", "인기"],
      },
      {
        "brand": "Nature Made",
        "name": "Magnesium Oxide",
        "price": "18,500원",
        "tags": ["해외 직구"],
      },
    ];

    return Column(
      children: products.map((p) {
        return ExpandableProductCard(
          brand: p["brand"] as String,
          name: p["name"] as String,
          price: p["price"] as String,
          tags: p["tags"] as List<String>,
          tagColors: const {
            "식약처 인증": Color(0xFFE8F5E9),
            "AI 분석 결과": Color(0xFFE3F2FD),
            "중복 경고": Color(0xFFFFF3E0),
            "해외 직구": Color(0xFFF3E5F5),
            "인기": Color(0xFFFFEBEE),
          },
          tagTextColors: const {
            "식약처 인증": Color(0xFF2E7D32),
            "AI 분석 결과": Color(0xFF1565C0),
            "중복 경고": Color(0xFFE65100),
            "해외 직구": Color(0xFF7B1FA2),
            "인기": Color(0xFFC62828),
          },
        );
      }).toList(),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    "본 분석 결과는 참고용이며, 정확한 복용 상담은 전문의와 상의하십시오.",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          "홈으로 돌아가기",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.home_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
