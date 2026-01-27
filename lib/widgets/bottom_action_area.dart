import 'dart:ui';
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: const Border(
              top: BorderSide(color: Color(0x0D000000)), // 0.05 opacity black
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
              _buildGradientButton(
                context: context,
                label: cameraLabel,
                icon: Icons.camera_alt_rounded,
                colors: [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                onTap: onCameraTap,
              ),
              const SizedBox(height: 12),

              // Secondary Button (Gallery)
              _buildGradientButton(
                context: context,
                label: galleryLabel,
                icon: Icons.photo_library_rounded,
                colors: [const Color(0xFF81C784), const Color(0xFFA5D6A7)],
                shadowColor: const Color(0xFF81C784).withValues(alpha: 0.3),
                onTap: onGalleryTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16, // Soft shadow
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Adjusted weight
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
