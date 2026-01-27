import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/widgets/pill_icon_graphic.dart';

class USRecommendationSection extends StatelessWidget {
  const USRecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Text(
            "🔥 Popular Supplements (Quick Add)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 200, // Reduced height since we don't have large images
          child: _AutoScrollingCarousel(),
        ),
      ],
    );
  }
}

class _RecommendationItem {
  final String nameEn;
  final String nameKo;
  final String brand;
  final Color color;
  final IconData icon;

  const _RecommendationItem({
    required this.nameEn,
    required this.nameKo,
    required this.brand,
    required this.color,
    required this.icon,
  });

  String getName(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en'
        ? nameEn
        : nameKo;
  }
}

class _AutoScrollingCarousel extends StatefulWidget {
  const _AutoScrollingCarousel();

  @override
  State<_AutoScrollingCarousel> createState() => _AutoScrollingCarouselState();
}

class _AutoScrollingCarouselState extends State<_AutoScrollingCarousel> {
  late PageController _pageController;
  Timer? _timer;

  static const List<_RecommendationItem> _items = [
    _RecommendationItem(
      nameEn: "Omega-3",
      nameKo: "오메가-3",
      brand: "Sports Research",
      color: Color(0xFFFFA000), // Amber 700
      icon: Icons.water_drop_rounded,
    ),
    _RecommendationItem(
      nameEn: "Vitamin C",
      nameKo: "비타민 C",
      brand: "Korea Eundan",
      color: Color(0xFFFB8C00), // Orange 600
      icon: Icons.wb_sunny_rounded,
    ),
    _RecommendationItem(
      nameEn: "Magnesium",
      nameKo: "마그네슘",
      brand: "Nature Made",
      color: Color(0xFF7E57C2), // DeepPurple 400
      icon: Icons.nightlight_round,
    ),
    _RecommendationItem(
      nameEn: "Probiotics",
      nameKo: "유산균",
      brand: "Lacto-Fit",
      color: Color(0xFF43A047), // Green 600
      icon: Icons.spa_rounded,
    ),
    _RecommendationItem(
      nameEn: "Vitamin D",
      nameKo: "비타민 D",
      brand: "Doctor's Best",
      color: Color(0xFFF9A825), // Yellow 800
      icon: Icons.brightness_5_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.45,
      initialPage: 1000 * _items.length,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemBuilder: (context, index) {
        final itemIndex = index % _items.length;
        return _buildRecommendationCard(_items[itemIndex]);
      },
    );
  }

  Widget _buildRecommendationCard(_RecommendationItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.1), // Colored shadow
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PillIconGraphic(
            color: item.color,
            icon: item.icon,
            size: 64,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Text(
                  item.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.getName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
