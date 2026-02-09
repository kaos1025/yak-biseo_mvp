import 'package:flutter/material.dart';

class WarningBanner extends StatelessWidget {
  final String ingredientName;
  final String currentAmount;
  final String limitAmount;

  const WarningBanner({
    super.key,
    required this.ingredientName,
    required this.currentAmount,
    required this.limitAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE), // Red Light
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "성분 과다 섭취 주의",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFFC62828)),
                    children: [
                      TextSpan(
                          text: ingredientName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " "),
                      TextSpan(
                          text: currentAmount,
                          style: const TextStyle(
                              decoration: TextDecoration.underline)),
                      const TextSpan(text: " (상한 "),
                      TextSpan(
                          text: limitAmount,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: " 초과)"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
