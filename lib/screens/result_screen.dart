
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<String> _analysisResult;

  @override
  void initState() {
    super.initState();
    _analysisResult = ApiService.analyzeDrugImage(File(widget.imagePath));
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'WARNING':
        return Colors.red.shade100;
      case 'INFO':
        return Colors.blue.shade100;
      case 'SAVING':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약 분석 결과'),
      ),
      body: FutureBuilder<String>(
        future: _analysisResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            try {
              final result = jsonDecode(snapshot.data!) as Map<String, dynamic>;
              if (result['status'] == 'SUCCESS') {
                final summary = result['summary'] as String;
                final cards = result['cards'] as List;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '분석 요약',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(summary),
                      const SizedBox(height: 24),
                      ...cards.map((cardData) {
                        final card = cardData as Map<String, dynamic>;
                        return Card(
                          color: _getCardColor(card['type'] as String),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(card['content'] as String),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              } else {
                return Center(child: Text('분석 실패: ${result['summary']}'));
              }
            } catch (e) {
              return Center(child: Text('결과를 파싱하는 중 오류가 발생했습니다: $e'));
            }
          } else {
            return const Center(child: Text('결과가 없습니다.'));
          }
        },
      ),
    );
  }
}
