import 'package:flutter/material.dart';
import '../../../../data/models/health_tip_model.dart';
import '../../../../widgets/bottom_action_area.dart';
import '../../../../l10n/app_localizations.dart';

class HealthTipModal extends StatelessWidget {
  final HealthTipModel tip;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  const HealthTipModal({
    super.key,
    required this.tip,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  void _showActionBottomSheet(BuildContext context) {
    Navigator.pop(context); // Close the modal first
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomActionArea(
        onCameraTap: () {
          Navigator.pop(context);
          onCameraTap();
        },
        onGalleryTap: () {
          Navigator.pop(context);
          onGalleryTap();
        },
        cameraLabel: l10n.homeBtnCamera,
        galleryLabel: l10n.homeBtnGallery,
        disclaimerText: l10n.homeDisclaimer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tip.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                tip.teaser,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.black12, thickness: 1),
            const SizedBox(height: 24),
            Text(
              '👀 ${tip.cta}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showActionBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    l10n.tipModalBtn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
