import 'package:flutter/material.dart';
import 'package:myapp/theme/supplecut_tokens.dart';
import 'package:myapp/widgets/common/ghost_button.dart';

/// DS v0.5 §7.20 Content Question Card.
///
/// Dumb component — `question`은 호출부에서 주입(예: HealthTipModel.getQuestion(locale)).
class ContentQuestionCard extends StatelessWidget {
  final String question;
  final String categoryLabel;
  final String ctaLabel;
  final VoidCallback onCtaTap;

  const ContentQuestionCard({
    super.key,
    required this.question,
    this.categoryLabel = "Today's supplement question",
    this.ctaLabel = 'Learn more',
    required this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ScSpace.lg),
      decoration: BoxDecoration(
        color: ScColors.surface,
        border: Border.all(color: ScColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(ScRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                size: 18,
                color: ScColors.textSec,
              ),
              const SizedBox(width: 6),
              Text(
                categoryLabel,
                style: ScText.caption.copyWith(
                  color: ScColors.textSec,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: ScSpace.md),
          Text(
            '"$question"',
            style: ScText.h2.copyWith(color: ScColors.ink),
          ),
          const SizedBox(height: ScSpace.md),
          Align(
            alignment: Alignment.centerRight,
            child: GhostButton(
              label: ctaLabel,
              onPressed: onCtaTap,
            ),
          ),
        ],
      ),
    );
  }
}
