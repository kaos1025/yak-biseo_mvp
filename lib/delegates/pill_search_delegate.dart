import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../models/pill.dart';
import '../services/api_service.dart';

class PillSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => '약품 명을 입력하세요';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('검색어를 입력하세요.'));
    }

    return FutureBuilder<List<KoreanPill>>(
      future: ApiService.searchPill(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('에러가 발생했습니다: ${snapshot.error}'),
          );
        }

        final results = snapshot.data;

        if (results == null || results.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final pill = results[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.medication, color: Color(0xFF2E7D32)),
              ),
              title: Text(
                pill.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(pill.brand),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Placeholder for detail navigation
                developer.log('Selected Pill: ${pill.name} (ID: ${pill.id})');
                // Could navigate to details screen here later
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Optionally implement suggestions api logic here
    if (query.isEmpty) {
      return const Center(child: Text('검색어를 입력하세요.'));
    }
    // For now simple text, or could show recent searches
    return const Center(child: Text('검색어를 입력하여 조회하세요.'));
  }
}
