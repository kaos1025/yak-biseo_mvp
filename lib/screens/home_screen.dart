import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/result_screen.dart';
import 'package:myapp/screens/search_screen.dart';
import 'package:myapp/services/analytics_service.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/screens/profile/profile_screen.dart';

import 'package:myapp/services/my_pill_service.dart';
import 'package:myapp/models/pill.dart';
import 'package:myapp/widgets/bottom_action_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<KoreanPill>> _myPillsFuture;
  final AnalyticsService _analyticsService = AnalyticsService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _myPillsFuture = MyPillService.loadMyPills();
    _analyticsService.logAppOpen();
    _checkDisclaimer();
  }

  void _refreshMyPills() {
    setState(() {
      _myPillsFuture = MyPillService.loadMyPills();
    });
  }

  Future<void> _checkDisclaimer() async {
    // Wait for the locale to be available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'en') {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
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
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(l10n.disclaimerAgree),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    _analyticsService.logCameraClick();
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      if (!mounted) return;
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
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (!mounted) return;
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
    final locale = Localizations.localeOf(context).languageCode;

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
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
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
                          // [나의 영양제 섹션]
                          FutureBuilder<List<KoreanPill>>(
                            future: _myPillsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final myPills = snapshot.data ?? [];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale == 'en'
                                        ? "💊 My Supplements"
                                        : "💊 나의 영양제",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (myPills.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 24),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.6)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 24,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(Icons.medication_outlined,
                                              size: 32,
                                              color: Colors.grey[400]),
                                          const SizedBox(height: 8),
                                          Text(
                                            locale == 'en'
                                                ? "Add your supplements +"
                                                : "영양제를 등록해보세요",
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      height: 96,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: myPills.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final pill = myPills[index];
                                          return Container(
                                            width: 220,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                              border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.6)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        pill.brand,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        pill.name,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          height: 1.2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () async {
                                                    await MyPillService
                                                        .removePill(pill.id);
                                                    _refreshMyPills();
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(locale ==
                                                                  'en'
                                                              ? "Supplement removed."
                                                              : "영양제가 삭제되었습니다."),
                                                          duration:
                                                              const Duration(
                                                                  seconds: 1),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                ],
                              );
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
