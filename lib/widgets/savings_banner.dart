import 'package:flutter/material.dart';

class SavingsBanner extends StatelessWidget {
  final int savingAmount;
  final List<String> excludedProductNames; // Names of products causing savings

  const SavingsBanner({
    super.key,
    required this.savingAmount,
    this.excludedProductNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Case 1: No savings - Show positive message
    if (savingAmount <= 0) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], // Green gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
              "✅ 잘 먹고 계세요!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "영양제 중복 없이 균형 잡힌 섭취를 하고 계십니다.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Case 2: Has savings - Show savings banner
    final yearlySavings = savingAmount * 12;

    final formattedMonthly = savingAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    final formattedYearly = yearlySavings.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    String exclusionText = "";
    if (excludedProductNames.isNotEmpty) {
      if (excludedProductNames.length == 1) {
        exclusionText = "${excludedProductNames.first} 제외 시";
      } else {
        exclusionText =
            "${excludedProductNames.first} 외 ${excludedProductNames.length - 1}개 제외 시";
      }
    } else {
      // Fallback or generic message
      exclusionText = "중복 제품 제외 시";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Gold to Orange
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
          const Text(
            "💰 월 절감 가능 금액",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5D4037), // Dark Brown for contrast on gold
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$formattedMonthly원",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white, // White text pops on orange/gold
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Color(0x40000000),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎉 ", style: TextStyle(fontSize: 14)),
                Text(
                  "연간 $formattedYearly원 아낄 수 있어요!",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
          if (exclusionText.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white54, height: 1),
            const SizedBox(height: 8),
            Text(
              exclusionText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.brown[800],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
