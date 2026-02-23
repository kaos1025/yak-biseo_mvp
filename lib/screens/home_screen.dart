import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/result_screen.dart';
import 'package:myapp/services/analytics_service.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/screens/profile/profile_screen.dart';

import 'package:myapp/presentation/home/home_view_model.dart';
import 'package:myapp/presentation/home/widgets/health_tip_banner.dart';
import 'package:myapp/presentation/home/widgets/recent_analysis_card.dart';
import 'package:myapp/widgets/bottom_action_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeViewModel _viewModel = HomeViewModel();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _analyticsService.logAppOpen();
    _checkDisclaimer();
  }

  void _refreshMyPills() {
    _viewModel.loadData();
  }

  Future<void> _checkDisclaimer() async {
    // Wait for the locale to be available
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

  Future<void> _pickImageFromCamera() async {
    _analyticsService.logCameraClick();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800, // Resize to max 800px width
      imageQuality: 85, // Compress lightly
    );
    if (pickedFile != null) {
      if (!mounted) {
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(image: pickedFile),
        ),
      );
      if (mounted) {
        _refreshMyPills();
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    _analyticsService.logGalleryClick();
    developer.log('갤러리 버튼 클릭됨', name: 'com.example.myapp.ui');
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Resize to max 800px width
      imageQuality: 85, // Compress lightly
    );
    if (pickedFile != null) {
      if (!mounted) {
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(image: pickedFile),
        ),
      );
      if (mounted) {
        _refreshMyPills();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          l10n.homeAppBarTitle,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Color(0xFF2E7D32)),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Global Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FBF4), Color(0xFFE8F5E9)],
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeMainQuestion,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: Colors.black87,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.homeSubQuestion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // [건강 팁 또는 최근 분석 결과 섹션]
                          AnimatedBuilder(
                            animation: _viewModel,
                            builder: (context, child) {
                              if (_viewModel.isLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (_viewModel.recentAnalysis != null) {
                                return Column(
                                  children: [
                                    RecentAnalysisCard(
                                      analysis: _viewModel.recentAnalysis!,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }

                              if (_viewModel.currentTip != null) {
                                return Column(
                                  children: [
                                    HealthTipBanner(
                                      tip: _viewModel.currentTip!,
                                      onCameraTap: _pickImageFromCamera,
                                      onGalleryTap: _pickImageFromGallery,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF2E7D32), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8BC34A)
                                      .withValues(alpha: 0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.savings_rounded,
                                    color: Color(0xFF2E7D32)),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.homeSavingEstimate,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomActionArea(
              onCameraTap: _pickImageFromCamera,
              onGalleryTap: _pickImageFromGallery,
              cameraLabel: l10n.homeBtnCamera,
              galleryLabel: l10n.homeBtnGallery,
              disclaimerText: l10n.homeDisclaimer,
            ),
          ),
        ],
      ),
    );
  }
}
