import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/analysis_loading_screen.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';

class ResultScreen extends StatefulWidget {
  final XFile image;
  final String locale;

  const ResultScreen({super.key, required this.image, required this.locale});

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

  /// 통합 파이프라인: 이미지 → OCR → 로컬 DB 매칭 → 분석
  Future<SuppleCutAnalysisResult> _processImage() async {
    final imageBytes = await widget.image.readAsBytes();
    return _analyzerService.analyzeWithImage(imageBytes, locale: widget.locale);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
