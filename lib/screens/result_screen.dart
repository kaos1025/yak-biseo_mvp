import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/analyzing_screen.dart';
import 'package:myapp/screens/analysis_result_screen.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';
import 'package:myapp/l10n/app_localizations.dart';

class ResultScreen extends StatefulWidget {
  final XFile image;

  const ResultScreen({super.key, required this.image});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final GeminiAnalyzerService _analyzerService = GeminiAnalyzerService();
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Image Encoding
      final Uint8List imageBytes = await widget.image.readAsBytes();

      // 2. Step 1: Analyze Ingredients (JSON)
      // This is the "Fast" step (relatively)
      final jsonResult = await _analyzerService.analyzeImage(imageBytes);

      // 3. Step 2: Consultant Report (Markdown)
      // This uses the previous JSON result for consistency and adds "Advice"
      final String report =
          await _analyzerService.analyzeImageWithConsultantMode(
        imageBytes,
        previousAnalysis: jsonResult,
      );

      if (!mounted) return;

      // 4. Navigate to Result Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            result: jsonResult,
            report: report,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AnalyzingScreen();
    }

    // Error State UI
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                "Analysis Failed",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? "Unknown error occurred.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _startAnalysis,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? "Retry"
                          : "다시 시도"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
