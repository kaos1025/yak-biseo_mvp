import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/result_screen.dart';
import 'package:myapp/services/analytics_service.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/screens/stack/my_stack_screen.dart';
import 'package:myapp/screens/stack/quick_check_screen.dart';
import 'package:myapp/theme/supplecut_tokens.dart';

import 'package:myapp/presentation/home/home_view_model.dart';
import 'package:myapp/presentation/home/widgets/health_tip_modal.dart';
import 'package:myapp/presentation/home/widgets/recent_analysis_card.dart';
import 'package:myapp/widgets/home/content_question_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final HomeViewModel _viewModel = HomeViewModel();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _analyticsService.logAppOpen();
    _checkDisclaimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refreshMyPills();
  }

  void _refreshMyPills() {
    _viewModel.loadData();
  }

  Future<void> _checkDisclaimer() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'en') {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) {
          return;
        }
        final agreed = prefs.getBool('fda_disclaimer_agreed') ?? false;
        if (!agreed) {
          _showDisclaimerDialog();
        }
      }
    });
  }

  void _showDisclaimerDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.disclaimerTitle),
        content: const SingleChildScrollView(
          child: Text(
            'This application provides information for educational purposes only. '
            'The contents are not intended to be a substitute for professional medical advice, diagnosis, or treatment. '
            'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition. '
            '\n\nThese statements have not been evaluated by the Food and Drug Administration. '
            'This product is not intended to diagnose, treat, cure, or prevent any disease.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('fda_disclaimer_agreed', true);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n.disclaimerAgree),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera({bool forceRefresh = false}) async {
    _analyticsService.logCameraClick();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            image: pickedFile,
            locale: l10n.localeName,
            forceRefresh: forceRefresh,
          ),
        ),
      );
      if (mounted) {
        _refreshMyPills();
      }
    }
  }

  Future<void> _pickImageFromGallery({bool forceRefresh = false}) async {
    _analyticsService.logGalleryClick();
    developer.log('갤러리 버튼 클릭됨', name: 'com.example.myapp.ui');
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            image: pickedFile,
            locale: l10n.localeName,
            forceRefresh: forceRefresh,
          ),
        ),
      );
      if (mounted) {
        _refreshMyPills();
      }
    }
  }

  void _openTipModal() {
    final tip = _viewModel.currentTip;
    if (tip == null) return;
    showDialog(
      context: context,
      builder: (_) => HealthTipModal(
        tip: tip,
        onCameraTap: _pickImageFromCamera,
        onGalleryTap: _pickImageFromGallery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: ScColors.surface2,
      appBar: AppBar(
        backgroundColor: ScColors.surface2,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.homeAppBarTitle,
          style: ScText.h1.copyWith(
            fontSize: 20,
            color: ScColors.brand,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_outline,
              size: 24,
              color: ScColors.ink,
            ),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: ScSpace.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ScSpace.lg,
            ScSpace.lg,
            ScSpace.lg,
            ScSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Text(
                l10n.homeMainQuestion,
                style: ScText.display.copyWith(color: ScColors.ink),
              ),
              const SizedBox(height: ScSpace.md),
              Text(
                l10n.homeSubQuestion,
                style: ScText.body.copyWith(color: ScColors.textSec),
              ),
              const SizedBox(height: ScSpace.xl),

              // Today's supplement question (Free 상태에서만 표시)
              AnimatedBuilder(
                animation: _viewModel,
                builder: (context, child) {
                  if (_viewModel.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: ScSpace.xl),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (_viewModel.recentAnalysis != null) {
                    return Column(
                      children: [
                        RecentAnalysisCard(
                          analysis: _viewModel.recentAnalysis!,
                        ),
                        const SizedBox(height: ScSpace.xl),
                      ],
                    );
                  }

                  final tip = _viewModel.currentTip;
                  if (tip != null) {
                    return Column(
                      children: [
                        ContentQuestionCard(
                          question: tip.getQuestion(locale),
                          onCtaTap: _openTipModal,
                        ),
                        const SizedBox(height: ScSpace.xl),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              // Primary CTA
              SizedBox(
                width: double.infinity,
                height: ScTouch.primaryCta,
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: Text(l10n.homeBtnCamera),
                ),
              ),
              const SizedBox(height: ScSpace.md),

              // Secondary CTA — B 조합 brandTint Fill, no border
              SizedBox(
                width: double.infinity,
                height: ScTouch.primaryCta,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScColors.brandTint,
                    foregroundColor: ScColors.brand,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ScRadius.md),
                      side: BorderSide.none,
                    ),
                    textStyle: ScText.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(l10n.homeBtnGallery),
                ),
              ),
              const SizedBox(height: ScSpace.lg),

              // Disclaimer (CTA 하단)
              Center(
                child: Text(
                  l10n.homeDisclaimer,
                  style: ScText.caption.copyWith(color: ScColors.textTer),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── My Stack / Quick Check 진입 (Day 1 PM 분석 후 상태에서 부활 예정) ──

  // ignore: unused_element
  void _openMyStack() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyStackScreen()),
    );
  }

  // ignore: unused_element
  void _openQuickCheck() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuickCheckScreen()),
    );
  }

  // ignore: unused_element
  Widget _buildStackShortcutRow(AppLocalizations l10n) {
    final isKo = l10n.localeName == 'ko';
    return Row(
      children: [
        Expanded(
          child: _buildStackShortcutCard(
            icon: Icons.inventory_2_outlined,
            title: isKo ? '내 스택' : 'My Stack',
            subtitle: isKo ? '저장된 영양제 관리' : 'Your saved supplements',
            onTap: _openMyStack,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStackShortcutCard(
            icon: Icons.flash_on_rounded,
            title: isKo ? '퀵 체크' : 'Quick Check',
            subtitle: isKo ? '새 영양제 호환성 확인' : 'Test a new supplement',
            onTap: _openQuickCheck,
          ),
        ),
      ],
    );
  }

  Widget _buildStackShortcutCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 26, color: const Color(0xFF2E7D32)),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
