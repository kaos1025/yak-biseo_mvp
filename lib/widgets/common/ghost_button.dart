import 'package:flutter/material.dart';
import 'package:myapp/theme/supplecut_tokens.dart';

/// DS v0.5 §7.17 Ghost Button.
///
/// 사용처: Content Question Card 내부, 분석 결과 섹션 펼치기 등.
/// fg는 ScColors.ink 고정 — brand green 단일 앵커 원칙(D-9-A) 준수.
class GhostButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onPressed;

  const GhostButton({
    super.key,
    required this.label,
    this.trailingIcon = Icons.arrow_forward,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(ScRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: ScColors.brandTint,
          borderRadius: BorderRadius.circular(ScRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ScText.caption.copyWith(
                color: ScColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: ScSpace.xs),
              Icon(trailingIcon, size: 14, color: ScColors.ink),
            ],
          ],
        ),
      ),
    );
  }
}
