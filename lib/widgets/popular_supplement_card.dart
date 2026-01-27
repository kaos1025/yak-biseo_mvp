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
        filter:
            ImageFilter.blur(sigmaX: 12, sigmaY: 12), // Increased blur (10->12)
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.85), // Increased opacity (0.7->0.85)
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 32, // Increased blur radius
                spreadRadius: 2,
                offset: const Offset(0, 8), // Smoother shadow
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 36, // Reduced size (48->36)
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20, // Reduced size (24->20)
                  ),
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing (12->8)

              // Brand Name
              Text(
                brandName,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4), // Reduced spacing (8->4)

              // Product Name
              Text(
                productName,
                style: const TextStyle(
                  fontSize: 13, // Slightly reduced font size (14->13)
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.bold,
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
              // Removed Bottom Spacer to make it compact
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4), // Increased horizontal, reduced vertical padding
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green bg
        borderRadius: BorderRadius.circular(12), // More rounded
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10, // Slightly reduced
          color: Color(0xFF558B2F), // Darker green text
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
