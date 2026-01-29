import 'package:flutter/material.dart';
import '../models/pill.dart';
import '../data/repositories/drug_repository.dart';
import 'package:myapp/l10n/app_localizations.dart';

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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await _repository.searchDrugs('');
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
      final results = await _repository.searchDrugs(query);
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
      appBar: AppBar(
        title: Text(l10n.searchTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 18), // 4050 타겟: 글자 크기 키움
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  )
                : _filteredDrugs.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noResults,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredDrugs.length,
                        itemBuilder: (context, index) {
                          final pill = _filteredDrugs[index];
                          String subtitleText = pill.brand;
                          if (pill is KoreanPill) {
                            subtitleText += ' • ${pill.category}';
                          } else if (pill is AmericanPill) {
                            subtitleText += ' • US Supplement';
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: pill.imageUrl.startsWith('http')
                                  ? Image.network(pill.imageUrl,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.medication))
                                  : const Icon(Icons.medication,
                                      color: Colors.grey, size: 30),
                            ),
                            title: Text(
                              pill.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                subtitleText,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Color(0xFF2E7D32), size: 32),
                              onPressed: () => _addToCabinet(pill),
                            ),
                            onTap: () => _addToCabinet(pill),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
