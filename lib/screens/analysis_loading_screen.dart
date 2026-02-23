import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/screens/analysis_result_screen.dart';

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

  final List<StepInfo> _steps = [
    StepInfo(step: AnalysisStep.imageRecognition, label: '이미지 인식', duration: 5),
    StepInfo(
        step: AnalysisStep.ingredientSearch, label: '성분 정보 검색', duration: 10),
    StepInfo(
        step: AnalysisStep.duplicateAnalysis, label: '중복 성분 분석', duration: 10),
    StepInfo(step: AnalysisStep.reportGeneration, label: '리포트 생성', duration: 5),
  ];

  final List<String> _healthTips = [
    '💡 비타민D는 지용성이라 식후 섭취가 좋아요',
    '💡 칼슘과 철분은 함께 먹으면 흡수율이 떨어져요',
    '💡 마그네슘은 취침 전 섭취 시 수면에 도움돼요',
    '💡 오메가-3는 냉장 보관하면 산패를 막을 수 있어요',
    '💡 유산균은 위산이 적은 식후에 섭취하세요',
    '💡 비타민C는 철분 흡수를 도와줘요',
    '💡 아연과 구리는 함께 섭취하면 경쟁해요',
    '💡 비타민B군은 아침에 섭취하면 에너지에 도움돼요',
    '💡 루테인은 기름과 함께 먹으면 흡수율이 높아져요',
    '💡 코엔자임Q10은 식사와 함께 드세요',
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
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      totalElapsed++;

      // 단계 업데이트
      int accumulated = 0;
      for (var stepInfo in _steps) {
        accumulated += stepInfo.duration;
        if (totalElapsed <= accumulated) {
          setState(() {
            _currentStep = stepInfo.step;
            _progress = totalElapsed / 30.0; // 30초 기준
          });
          break;
        }
      }

      // 30초 넘으면 마지막 단계 유지
      if (totalElapsed >= 30) {
        setState(() {
          _progress = 0.95; // 95%에서 대기 (완료 시 100%)
          _currentStep = AnalysisStep.reportGeneration;
        });
      }
    });
  }

  void _startTipTimer() {
    _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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

      if (!mounted) return;

      setState(() {
        _currentStep = AnalysisStep.complete;
        _progress = 1.0;
      });

      // 결과 화면으로 이동
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: result),
        ),
      );
    } catch (e) {
      // 에러 처리
      if (!mounted) return;
      // 에러는 상위 위젯(ResultScreen)에서 처리하거나 여기서 Dialog를 띄울 수 있음.
      // 여기서는 ResultScreen의 에러 처리를 위해 예외를 다시 던지는 대신,
      // Error Dialog를 직접 보여주고 화면을 닫는 방식을 선택.
      _showErrorDialog(e.toString());
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
              const Text(
                '🔍 영양제 분석 중...',
                style: TextStyle(
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
