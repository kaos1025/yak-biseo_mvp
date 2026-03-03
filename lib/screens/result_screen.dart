import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/analysis_loading_screen.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';
import 'package:myapp/services/analysis_cache_service.dart';

class ResultScreen extends StatefulWidget {
  final XFile image;
  final String locale;
  final bool forceRefresh;

  const ResultScreen({
    super.key,
    required this.image,
    required this.locale,
    this.forceRefresh = false,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GeminiAnalyzerService _analyzerService = GeminiAnalyzerService();

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  void _startAnalysis() {
    final imageFuture = _processImage();

    Future.microtask(() {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisLoadingScreen(
            analysisFuture: imageFuture,
          ),
        ),
      );
    });
  }

  /// 통합 파이프라인: 이미지 → OCR → 캐시 조회 → (미스 시) 분석 → 결과
  Future<SuppleCutAnalysisResult> _processImage() async {
    final imageBytes = await widget.image.readAsBytes();

    // Step 1: OCR로 제품명 추출
    final productNames = await _analyzerService.extractProductNames(imageBytes);

    // Step 2: 캐시 조회 (7일 TTL) — forceRefresh 시 스킵
    if (!widget.forceRefresh && productNames.isNotEmpty) {
      final cached =
          await AnalysisCacheService.get(productNames, locale: widget.locale);
      if (cached != null) {
        return cached; // 캐시 히트 → API 재호출 없음
      }
    }

    // Step 3: 캐시 미스 → 실제 분석 실행
    final result = await _analyzerService.analyzeWithImage(imageBytes,
        locale: widget.locale);

    // Step 4: 결과 캐시 저장
    if (productNames.isNotEmpty) {
      await AnalysisCacheService.put(productNames, result,
          locale: widget.locale);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
