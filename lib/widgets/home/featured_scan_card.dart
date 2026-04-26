import 'package:flutter/material.dart';
import 'package:myapp/theme/supplecut_tokens.dart';
import 'package:myapp/widgets/common/ghost_button.dart';

/// DS v0.5 §7.19 Featured Scan Card.
///
/// 사용처: 홈 분석 후 분기 (HomeScreen — recentAnalysis != null).
/// Status accent 매핑: safe→okAccent / warning→warnAccent / danger→dangerAccent.
enum FeaturedScanStatus { safe, warning, danger }

class FeaturedScanCard extends StatelessWidget {
  final FeaturedScanStatus status;
  final String statusLabel;
  final String? summaryText;
  final String productPreview;
  final String analyzedOn;
  final VoidCallback onViewDetails;

  const FeaturedScanCard({
    super.key,
    required this.status,
    required this.statusLabel,
    required this.summaryText,
    required this.productPreview,
    required this.analyzedOn,
    required this.onViewDetails,
  });

  Color _accent() => switch (status) {
        FeaturedScanStatus.safe => ScColors.okAccent,
        FeaturedScanStatus.warning => ScColors.warnAccent,
        FeaturedScanStatus.danger => ScColors.dangerAccent,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
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
          Text(
            'RECENT ANALYSIS',
            style: ScText.label.copyWith(color: ScColors.textSec),
          ),
          const SizedBox(height: ScSpace.md),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: ScSpace.sm),
              Expanded(
                child: Text(
                  statusLabel,
                  style: ScText.h2.copyWith(color: accent),
                ),
              ),
            ],
          ),
          if (summaryText != null && summaryText!.isNotEmpty) ...[
            const SizedBox(height: ScSpace.sm),
            Text(
              summaryText!,
              style: ScText.body.copyWith(color: ScColors.textSec),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: ScSpace.sm),
          Text(
            productPreview,
            style: ScText.body.copyWith(color: ScColors.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ScSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Analyzed on $analyzedOn',
                  style: ScText.caption.copyWith(color: ScColors.textTer),
                ),
              ),
              GhostButton(
                label: 'View details',
                onPressed: onViewDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
