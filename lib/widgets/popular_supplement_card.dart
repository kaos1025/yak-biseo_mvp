import 'dart:ui';
import 'package:flutter/material.dart';

class PopularSupplementCard extends StatelessWidget {
  final String brandName;
  final String productName;
  final List<String> tags;
  final IconData icon;
  final Color iconColor;

  const PopularSupplementCard({
    super.key,
    required this.brandName,
    required this.productName,
    required this.tags,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Verified blur 12px
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6), // Opacity 0.6
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.4), // Verified border opacity
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1), // Verified shadow
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Inner shadow effect simulated
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        spreadRadius: -2,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.1),
                        blurRadius: 0,
                        spreadRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Brand Name
              Text(
                brandName,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Product Name
              Text(
                productName,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Tags
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: tags.map((tag) => _buildTag(tag)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            const Color(0xFF8BC34A).withValues(alpha: 0.15), // Light green bg
        borderRadius: BorderRadius.circular(20), // Pill shape
        border:
            Border.all(color: const Color(0xFF8BC34A).withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF558B2F), // Darker green text
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
