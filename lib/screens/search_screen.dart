import 'package:flutter/material.dart';
import '../models/pill.dart';
import '../data/repositories/drug_repository.dart';
import 'package:myapp/l10n/app_localizations.dart';
import '../widgets/expandable_product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DrugRepository _repository = DrugRepository();

  List<BasePill> _filteredDrugs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final results = await _repository.searchDrugs('', locale);
      if (mounted) {
        setState(() {
          _filteredDrugs = results;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locale = Localizations.localeOf(context).languageCode;
      final results = await _repository.searchDrugs(query, locale);
      if (mounted) {
        setState(() {
          _filteredDrugs = results;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addToCabinet(BasePill pill) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${pill.name} ${l10n.addedToCabinet}',
          style: const TextStyle(fontSize: 16),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: l10n.undo,
          textColor: Colors.yellow,
          onPressed: () {
            // 실행 취소 로직
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.searchTitle,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FBF4), Color(0xFFE8F5E9)],
              ),
            ),
          ),
          // 2. Content
          SafeArea(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(204), // 0.8 * 255
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13), // 0.05 * 255
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 15),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF2E7D32), size: 24),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchChanged,
                    ),
                  ),
                ),

                // Popular Searches (Visible only when filtering is not active or empty)
                if (_searchController.text.isEmpty && !_isLoading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.popularSearches,
                          style: const TextStyle(
                            fontSize:
                                14, // Reduced font size for better hierarchy
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            "Omega-3",
                            "Vitamin C",
                            "Probiotics",
                            "Magnesium",
                            "Vitamin D"
                          ]
                              .map((term) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ActionChip(
                                      label: Text(term),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      backgroundColor: const Color(0xFFE8F5E9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide.none,
                                      ),
                                      onPressed: () {
                                        _searchController.text = term;
                                        _onSearchChanged(term);
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                // Search Results
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E7D32),
                          ),
                        )
                      : (_filteredDrugs.isEmpty &&
                              _searchController.text.isNotEmpty)
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded,
                                      size: 64, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noResults,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (_filteredDrugs.isEmpty &&
                                  _searchController.text.isEmpty)
                              ? Center(
                                  // Empty State for initial screen
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.medication_outlined,
                                          size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.searchEmptyState,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  itemCount: _filteredDrugs.length,
                                  itemBuilder: (context, index) {
                                    final pill = _filteredDrugs[index];

                                    // Determine properties based on pill type
                                    String? ingredients;
                                    if (pill is KoreanPill) {
                                      ingredients = pill.ingredients;
                                    }

                                    return ExpandableProductCard(
                                      brand: pill.brand,
                                      name: pill.name,
                                      // We don't have price in BasePill, using a placeholder logic or modifying BasePill would be better
                                      // But for now, we'll check if we can get it or hide it.
                                      // ExpandableProductCard REQUIRES price.
                                      // Let's assume a default or fetch logic.
                                      // Since this is MVP search, maybe we don't show price or show "Info".
                                      price: l10n.viewDetails,
                                      tags: const [], // Mock tags for search list
                                      tagColors: const {},
                                      tagTextColors: const {},
                                      backgroundColor: Colors.white.withAlpha(
                                          217), // 0.85 * 255 = 216.75
                                      ingredients: ingredients,
                                      imageUrl: pill.imageUrl,
                                      onAdd: () => _addToCabinet(pill),
                                    );
                                  },
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
