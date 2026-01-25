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
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.medication,
                    color: colorScheme.onPrimaryContainer),
              ),
              title: Text(
                pill.name,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${pill.brand} | ${pill.dailyDosage}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(pill.name),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('제조사: ${pill.brand}',
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('섭취방법 / 유통기한:',
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(pill.dailyDosage, style: textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text('주요 원재료:',
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(pill.ingredients, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('닫기'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
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
