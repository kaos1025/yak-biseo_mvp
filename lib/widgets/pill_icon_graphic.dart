import 'package:flutter/material.dart';

class PillIconGraphic extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;

  const PillIconGraphic({
    super.key,
    required this.color,
    required this.icon,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2), // Light background
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Main Icon
          Icon(
            icon,
            color: color,
            size: size * 0.5,
          ),
          // Decorative mini-pill icon
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.medication_outlined,
                size: size * 0.25,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
