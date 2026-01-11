import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _textIndex = 0;
  final List<String> _loadingTexts = [
    "약을 확인하고 있어요... 💊",
    "성분을 분석하는 중... 🔍",
    "비용을 계산하는 중... 💰",
  ];

  @override
  void initState() {
    super.initState();
    // 스캔바 애니메이션 (위아래 반복)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -50, end: 50).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 텍스트 변경 애니메이션
    _startTextAnimation();
  }

  void _startTextAnimation() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) {
        setState(() {
          _textIndex = (_textIndex + 1) % _loadingTexts.length;
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 배경 아이콘
                Icon(
                  Icons.receipt_long_rounded,
                  size: 100,
                  color: Colors.grey[200],
                ),
                // 움직이는 스캔바
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animation.value),
                      child: Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            // 로딩 텍스트 (AnimatedSwitcher로 부드럽게 변경)
            SizedBox(
              height: 30, // 텍스트 높이 고정
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _loadingTexts[_textIndex],
                  key: ValueKey<int>(_textIndex),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "잠시만 기다려주세요",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
