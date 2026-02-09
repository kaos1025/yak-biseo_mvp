import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingsBanner extends StatelessWidget {
  final String bannerType; // 'good' or 'savings'
  final int monthlySavings;
  final int yearlySavings;
  final String exclusionReason;
  final List<String> excludedProductNames;

  const SavingsBanner({
    super.key,
    required this.bannerType,
    required this.monthlySavings,
    this.yearlySavings = 0,
    this.exclusionReason = '',
    this.excludedProductNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (bannerType == 'good') {
      // Case A: Good (Green)
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          children: [
            Text(
              '✅ 잘 먹고 계세요!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '영양제 중복 없이 균형 잡힌\n섭취를 하고 계십니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Case B: Savings (Gold)
      String excludedProductText = "";
      if (excludedProductNames.isNotEmpty) {
        if (excludedProductNames.length == 1) {
          excludedProductText = "${excludedProductNames.first} 제외 시";
        } else {
          excludedProductText =
              "${excludedProductNames.first} 외 ${excludedProductNames.length - 1}개 제외 시";
        }
      } else {
        excludedProductText = "중복 제품 제외 시";
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              excludedProductText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4037),
              ),
            ),
            const Divider(color: Colors.white30, height: 24),
            const Text(
              '💰 월 절감 가능 금액',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${NumberFormat('#,###').format(monthlySavings)}원',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🎉 연간 ${NumberFormat('#,###').format(yearlySavings > 0 ? yearlySavings : monthlySavings * 12)}원 아낄 수 있어요!',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
            ),
            if (exclusionReason.isNotEmpty) ...[
              const Divider(color: Colors.white30, height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💊 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      exclusionReason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4E342E),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }
  }
}
