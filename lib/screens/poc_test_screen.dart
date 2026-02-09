import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/supplement_analysis.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';

class PocTestScreen extends StatefulWidget {
  const PocTestScreen({super.key});

  @override
  State<PocTestScreen> createState() => _PocTestScreenState();
}

class _PocTestScreenState extends State<PocTestScreen> {
  final GeminiAnalyzerService _analyzerService = GeminiAnalyzerService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  AnalyzeResult? _analysisResult;
  Map<String, dynamic>? _consistencyResult;

  // Consultant Mode State
  bool _isConsultantMode = false;
  String? _consultantReport;

  bool _isLoading = false;
  String? _error;
  Duration? _elapsedTime;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _analysisResult = null;
          _consistencyResult = null;
          _consultantReport = null;
          _error = null;
        });
      }
    } catch (e) {
      _showError('이미지 선택 실패: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _analysisResult = null;
      _consistencyResult = null;
      _consultantReport = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      if (_isConsultantMode) {
        if (_analysisResult == null) {
          setState(() {
            _error = '먼저 일반 모드에서 분석을 실행해주세요.';
          });
          return;
        }
        final report = await _analyzerService.analyzeImageWithConsultantMode(
          _selectedImageBytes!,
          previousAnalysis: _analysisResult!,
        );
        setState(() {
          _consultantReport = report;
          _elapsedTime = stopwatch.elapsed;
        });
      } else {
        final result =
            await _analyzerService.analyzeImage(_selectedImageBytes!);
        setState(() {
          _analysisResult = result;
          _elapsedTime = stopwatch.elapsed;
        });
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      stopwatch.stop();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runConsistencyTest() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _consistencyResult = null;
    });

    try {
      final result =
          await _analyzerService.consistencyTest(_selectedImageBytes!);
      setState(() {
        _consistencyResult = result;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Gemini 2.5 PoC'),
        backgroundColor: _isConsultantMode ? Colors.purple : Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Section
            _buildImageSection(),
            const SizedBox(height: 16),

            // 2. Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // 3. Status/Error
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade50,
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 16),

            // 4. Results
            if (_analysisResult != null) _buildResultSection(),
            if (_consultantReport != null) _buildReportSection(),
            if (_consistencyResult != null) _buildConsistencySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _selectedImageBytes == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('이미지를 선택해주세요'),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _selectedImageBytes!,
                fit: BoxFit.contain,
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('카메라'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    _isLoading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Mode Toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false,
                label: Text('분석 (JSON)'),
                icon: Icon(Icons.data_object)),
            ButtonSegment(
                value: true,
                label: Text('상담 (Report)'),
                icon: Icon(Icons.health_and_safety)),
          ],
          selected: {_isConsultantMode},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isConsultantMode = newSelection.first;
              // 모드 전환 시 기존 결과 유지 (데이터 재사용을 위해)
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return _isConsultantMode
                      ? Colors.purple.shade100
                      : Colors.indigo.shade100;
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _selectedImageBytes == null || _isLoading
                    ? null
                    : _analyzeImage,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.analytics),
                label: Text(_isConsultantMode ? '상담 리포트 생성' : '분석 실행'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _isConsultantMode ? Colors.purple : Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!_isConsultantMode)
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _selectedImageBytes == null || _isLoading
                      ? null
                      : _runConsistencyTest,
                  child: const Text('일관성 테스트'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    final result = _analysisResult!;
    final usage = result.usageMetadata;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 분석 결과',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Metrics Card
        Card(
          elevation: 2,
          color: Colors.indigo.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem('소요 시간',
                        '${_elapsedTime?.inMilliseconds}ms', Icons.timer),
                    _buildMetricItem(
                      'Confidence',
                      result.confidence,
                      Icons.check_circle_outline,
                      color: result.confidence == 'high'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem('Tokens', '${usage?.totalTokenCount ?? 0}',
                        Icons.token),
                    _buildMetricItem(
                      'Est. Cost',
                      '\$${usage?.estimatedCost.toStringAsFixed(6)}',
                      Icons.attach_money,
                      color: Colors.green.shade800,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Product List
        ...result.products.map((product) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ExpansionTile(
                title: Text(product.nameKo ?? product.name),
                subtitle: Text('${product.brand} | ${product.servingSize}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: product.ingredients.map((ing) {
                        return ListTile(
                          title: Text(ing.nameKo ?? ing.name),
                          trailing: Text('${ing.amount}${ing.unit}'),
                          subtitle: ing.dailyValuePercent != null
                              ? Text('DV: ${ing.dailyValuePercent}%')
                              : null,
                          dense: true,
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            )),

        const SizedBox(height: 8),

        // Raw JSON Viewer
        ExpansionTile(
          title: const Text('Raw JSON Data', style: TextStyle(fontSize: 14)),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade900,
              child: Text(
                const JsonEncoder.withIndent('  ').convert({
                  'products': result.products
                      .map((p) => {
                            'brand': p.brand,
                            'name': p.name,
                            'ingredients': p.ingredients
                                .map((i) => '${i.name} (${i.amount}${i.unit})')
                                .toList()
                          })
                      .toList(),
                  'confidence': result.confidence,
                  'usage': usage != null
                      ? {
                          'prompt': usage.promptTokenCount,
                          'output': usage.candidatesTokenCount
                        }
                      : null
                }),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildReportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📑 상담 리포트',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_elapsedTime != null)
              Text(
                '⏱️ ${_elapsedTime!.inMilliseconds}ms',
                style: const TextStyle(color: Colors.grey),
              )
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: SelectableText(
            _consultantReport!,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildConsistencySection() {
    final data = _consistencyResult!;
    final score = data['consistency_score'] as double;
    final color =
        score >= 90 ? Colors.green : (score >= 70 ? Colors.orange : Colors.red);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: color),
              const SizedBox(width: 8),
              Text(
                '일관성 테스트 (5회 반복)',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('• 성공: ${data['success_count']} / ${data['total_attempts']}'),
          Text('• 일관성 점수: ${score.toStringAsFixed(1)}%'),
          Text(
              '• 평균 소요시간: ${data['average_duration_ms'].toStringAsFixed(0)}ms'),
          if ((data['errors'] as List).isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('에러 목록:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...(data['errors'] as List).map((e) => Text('- $e',
                style: const TextStyle(fontSize: 12, color: Colors.red))),
          ]
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
