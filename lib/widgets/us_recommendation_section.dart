import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pill.dart';
import '../services/product_service.dart';

class USRecommendationSection extends StatelessWidget {
  const USRecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
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
          height: 220, // Height for the horizontal list
          child: FutureBuilder<List<AmericanPill>>(
            future: ProductService.loadUSTop10(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(child: Text("추천 제품이 없습니다."));
              }

              final items = snapshot.data!;
              return _AutoScrollingCarousel(items: items);
            },
          ),
        ),
      ],
    );
  }
}

class _AutoScrollingCarousel extends StatefulWidget {
  final List<AmericanPill> items;
  const _AutoScrollingCarousel({required this.items});

  @override
  State<_AutoScrollingCarousel> createState() => _AutoScrollingCarouselState();
}

class _AutoScrollingCarouselState extends State<_AutoScrollingCarousel> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.45, // Show multiple items (2-3 items)
      initialPage: 1000 * widget.items.length, // Start in the middle
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
      onPageChanged: (index) {
        // Reset timer on manual interaction if needed, but for simple rolling we keep it.
        // Or we could pause it. For now, continuous rolling is fine.
      },
      itemBuilder: (context, index) {
        final itemIndex = index % widget.items.length;
        return _buildRecommendationCard(widget.items[itemIndex]);
      },
    );
  }

  Widget _buildRecommendationCard(AmericanPill pill) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: pill.imageUrl.startsWith('http')
                    ? Image.network(
                        pill.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        pill.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pill.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10, // Slightly smaller for dense view
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pill.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13, // Slightly smaller
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
