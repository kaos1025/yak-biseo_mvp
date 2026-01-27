import 'package:flutter/material.dart';

class BottomActionArea extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final String cameraLabel;
  final String galleryLabel;
  final String disclaimerText;

  const BottomActionArea({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.cameraLabel,
    required this.galleryLabel,
    required this.disclaimerText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Disclaimer
          Text(
            disclaimerText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // Primary Button (Camera)
          _buildButton(
            context: context,
            label: cameraLabel,
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFF4CAF50), // Primary
            textColor: Colors.white,
            onTap: onCameraTap,
          ),
          const SizedBox(height: 12),

          // Secondary Button (Gallery)
          _buildButton(
            context: context,
            label: galleryLabel,
            icon: Icons.photo_library_rounded,
            color: const Color(0xFF8BC34A), // Secondary
            textColor: Colors.white,
            onTap: onGalleryTap,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
