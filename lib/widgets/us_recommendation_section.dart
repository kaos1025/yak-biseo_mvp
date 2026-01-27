import 'package:flutter/material.dart';
import 'package:myapp/widgets/popular_supplement_card.dart';

class USRecommendationSection extends StatelessWidget {
  const USRecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              "🔥 Popular Supplements",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 180, // Reduced height for compact cards
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildRecommendationCard(context, _items[index]);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
      BuildContext context, _RecommendationItem item) {
    return PopularSupplementCard(
      brandName: item.brand,
      productName: item.getName(context),
      tags: item.getTags(context),
      icon: item.icon,
      iconColor: item.color,
    );
  }
}

class _RecommendationItem {
  final String nameEn;
  final String nameKo;
  final String brand;
  final Color color;
  final IconData icon;
  final List<String> tagsEn;
  final List<String> tagsKo;

  const _RecommendationItem({
    required this.nameEn,
    required this.nameKo,
    required this.brand,
    required this.color,
    required this.icon,
    required this.tagsEn,
    required this.tagsKo,
  });

  String getName(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en'
        ? nameEn
        : nameKo;
  }

  List<String> getTags(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'en'
        ? tagsEn
        : tagsKo;
  }
}

const List<_RecommendationItem> _items = [
  _RecommendationItem(
    nameEn: "Omega-3",
    nameKo: "오메가-3",
    brand: "Sports Research",
    color: Color(0xFFFFA000), // Amber 700
    icon: Icons.water_drop_rounded,
    tagsEn: ["Heart", "Brain"],
    tagsKo: ["혈행개선", "두뇌건강"],
  ),
  _RecommendationItem(
    nameEn: "Vitamin C",
    nameKo: "비타민 C",
    brand: "Korea Eundan",
    color: Color(0xFFFB8C00), // Orange 600
    icon: Icons.wb_sunny_rounded,
    tagsEn: ["Immunity", "Antioxidant"],
    tagsKo: ["면역력", "항산화"],
  ),
  _RecommendationItem(
    nameEn: "Magnesium",
    nameKo: "마그네슘",
    brand: "Nature Made",
    color: Color(0xFF7E57C2), // DeepPurple 400
    icon: Icons.nightlight_round,
    tagsEn: ["Sleep", "Muscle"],
    tagsKo: ["수면", "근육이완"],
  ),
  _RecommendationItem(
    nameEn: "Probiotics",
    nameKo: "유산균",
    brand: "Lacto-Fit",
    color: Color(0xFF43A047), // Green 600
    icon: Icons.spa_rounded,
    tagsEn: ["Digestion", "Gut"],
    tagsKo: ["장건강", "소화"],
  ),
  _RecommendationItem(
    nameEn: "Vitamin D",
    nameKo: "비타민 D",
    brand: "Doctor's Best",
    color: Color(0xFFF9A825), // Yellow 800
    icon: Icons.brightness_5_rounded,
    tagsEn: ["Bone", "Immunity"],
    tagsKo: ["뼈건강", "면역력"],
  ),
];
