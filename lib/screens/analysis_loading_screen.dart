import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/screens/analysis_result_screen.dart';
import 'package:myapp/data/local/recent_analysis_storage.dart';
import 'package:myapp/data/models/recent_analysis_model.dart';
import 'package:uuid/uuid.dart';
import 'package:myapp/l10n/app_localizations.dart';

enum AnalysisStep {
  imageRecognition, // 이미지 인식 (0-5초)
  ingredientSearch, // 성분 정보 검색 (5-15초)
  duplicateAnalysis, // 중복 성분 분석 (15-25초)
  reportGeneration, // 리포트 생성 (25-30초)
  complete, // 완료
}

class StepInfo {
  final AnalysisStep step;
  final String label;
  final int duration; // seconds

  StepInfo({required this.step, required this.label, required this.duration});
}

class AnalysisLoadingScreen extends StatefulWidget {
  final Future<SuppleCutAnalysisResult> analysisFuture;

  const AnalysisLoadingScreen({super.key, required this.analysisFuture});

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen> {
  AnalysisStep _currentStep = AnalysisStep.imageRecognition;
  int _currentTipIndex = 0;
  double _progress = 0.0;
  Timer? _stepTimer;
  Timer? _tipTimer;

  late final List<StepInfo> _steps = [
    StepInfo(
        step: AnalysisStep.imageRecognition,
        label: AppLocalizations.of(context)!.loadingStep1,
        duration: 5),
    StepInfo(
        step: AnalysisStep.ingredientSearch,
        label: AppLocalizations.of(context)!.loadingStep2,
        duration: 10),
    StepInfo(
        step: AnalysisStep.duplicateAnalysis,
        label: AppLocalizations.of(context)!.loadingStep3,
        duration: 10),
    StepInfo(
        step: AnalysisStep.reportGeneration,
        label: AppLocalizations.of(context)!.loadingStep4,
        duration: 5),
  ];

  late final List<String> _healthTips = [
    AppLocalizations.of(context)!.loadingTip1,
    AppLocalizations.of(context)!.loadingTip2,
    AppLocalizations.of(context)!.loadingTip3,
    AppLocalizations.of(context)!.loadingTip4,
    AppLocalizations.of(context)!.loadingTip5,
    AppLocalizations.of(context)!.loadingTip6,
    AppLocalizations.of(context)!.loadingTip7,
    AppLocalizations.of(context)!.loadingTip8,
    AppLocalizations.of(context)!.loadingTip9,
    AppLocalizations.of(context)!.loadingTip10,
  ];

  @override
  void initState() {
    super.initState();
    _startStepTimer();
    _startTipTimer();
    _waitForAnalysis();
  }

  void _startStepTimer() {
    int totalElapsed = 0;
    _stepTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) return;
      totalElapsed++;

      // 총 진행률 시뮬레이션 (약 20초 = 40틱)
      // 초반에 빠르게 차오르고 뒤로 갈수록 천천히 오르도록 설정
      double expectedProgress = (totalElapsed / 40.0).clamp(0.0, 0.95);

      setState(() {
        _progress = expectedProgress;

        if (_progress < 0.2) {
          _currentStep = AnalysisStep.imageRecognition;
        } else if (_progress < 0.5) {
          _currentStep = AnalysisStep.ingredientSearch;
        } else if (_progress < 0.8) {
          _currentStep = AnalysisStep.duplicateAnalysis;
        } else {
          _currentStep = AnalysisStep.reportGeneration;
        }
      });
    });
  }

  void _startTipTimer() {
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % _healthTips.length;
      });
    });
  }

  Future<void> _waitForAnalysis() async {
    try {
      final result = await widget.analysisFuture;
      _stepTimer?.cancel();
      _tipTimer?.cancel();

      // 분석 완료 즉시 로컬 스토리지에 결과 저장
      await _saveRecentAnalysis(result);

      if (!mounted) return;

      // 분석이 성공적으로 끝나면 무조건 진행률 100%와 완료 단계로 강제 설정
      setState(() {
        _currentStep = AnalysisStep.complete;
        _progress = 1.0;
      });

      // 완료 이펙트를 잠깐 보여주기 위한 대기시간
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: result),
        ),
        (route) => route.isFirst, // HomeScreen만 남기고 중간 라우트 제거
      );
    } catch (e) {
      // 에러 처리
      if (!mounted) return;
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _saveRecentAnalysis(SuppleCutAnalysisResult result) async {
    try {
      final analysisModel = RecentAnalysisModel(
        id: const Uuid().v4(),
        analyzedAt: DateTime.now(),
        productNames: result.products.map((p) => p.name).toList(),
        overallRisk: result.overallRisk,
        riskSummary: result.summary,
        productCount: result.products.length,
        analysisJson: jsonEncode(result.toJson()),
      );
      await RecentAnalysisStorage.save(analysisModel);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to save recent analysis: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('분석 오류'),
        content: Text('분석 중 오류가 발생했습니다.\n$message'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog 닫기
              Navigator.of(context).pop(); // LoadingScreen 닫기 (이전 화면으로)
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4050 타겟 UI: 폰트 사이즈 Up, 명확한 색상 대비
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 메인 아이콘 + 애니메이션
              _buildMainAnimation(),

              const SizedBox(height: 32),

              // 2. 제목
              Text(
                '🔍 ${AppLocalizations.of(context)!.loadingAnalyzing}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // 3. 단계별 체크리스트
              _buildStepChecklist(),

              const SizedBox(height: 32),

              // 4. 프로그레스 바
              _buildProgressBar(),

              const Spacer(),

              // 5. 건강 팁
              _buildHealthTip(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainAnimation() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9), // Light Green
        shape: BoxShape.circle,
      ),
      child: Center(
        child: _currentStep == AnalysisStep.complete
            ? const Icon(Icons.check_circle, size: 60, color: Color(0xFF4CAF50))
            : const CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
      ),
    );
  }

  Widget _buildStepChecklist() {
    return Column(
      children: _steps.map((stepInfo) {
        bool isCompleted = _currentStep.index > stepInfo.step.index;
        bool isCurrent = _currentStep == stepInfo.step;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // 상태 아이콘
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF4CAF50) // Green
                      : (isCurrent
                          ? const Color(0xFFFF9800) // Orange
                          : Colors.grey[300]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : (isCurrent
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : null),
                ),
              ),

              const SizedBox(width: 16),

              // 단계 텍스트
              Text(
                stepInfo.label,
                style: TextStyle(
                  fontSize: 18, // 4050 타겟: 폰트 키움
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted || isCurrent
                      ? Colors.black87
                      : Colors.grey[500],
                ),
              ),

              // 완료 표시
              if (isCompleted) ...[
                const Spacer(),
                const Text('✅', style: TextStyle(fontSize: 18)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // 퍼센트 표시
        Text(
          '${(_progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),

        const SizedBox(height: 12),

        // 프로그레스 바
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 16, // 높이 키움
            backgroundColor: Colors.grey[200],
            valueColor:
                const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)), // Green
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTip() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey<int>(_currentTipIndex),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1), // Light Amber
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
        ),
        child: Row(
          children: [
            const Text('💊', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _healthTips[_currentTipIndex],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown[800],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
