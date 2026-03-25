import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/analysis_loading_screen.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/services/gemini_analysis_service.dart';
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
  final GeminiAnalysisService _analysisService = GeminiAnalysisService();

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

  /// 원스톱 파이프라인: 이미지 → 캐시 조회 → (미스 시) Gemini 원스톱 분석 → 결과
  Future<SuppleCutAnalysisResult> _processImage() async {
    final imageBytes = await widget.image.readAsBytes();

    // 이미지 크기+해시 기반 캐시 키 생성
    final imageHash =
        '${imageBytes.length}_${imageBytes.buffer.asUint8List().hashCode}';
    final cacheKey = ['onestop', imageHash];

    // Step 1: 캐시 조회 (7일 TTL) — forceRefresh 시 스킵
    if (!widget.forceRefresh) {
      final cached =
          await AnalysisCacheService.get(cacheKey, locale: widget.locale);
      if (cached != null) {
        return cached;
      }
    }

    // Step 2: Gemini 원스톱 분석 (1회 호출)
    final onestopResult = await _analysisService.analyzeImage(imageBytes);

    // Step 3: 기존 UI 호환 변환
    final result = onestopResult.toSuppleCutAnalysisResult();

    // Step 4: 결과 캐시 저장
    await AnalysisCacheService.put(cacheKey, result, locale: widget.locale);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
