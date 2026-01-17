import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/result_screen.dart';
import 'package:myapp/screens/search_screen.dart';
import 'package:myapp/services/analytics_service.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/screens/profile/profile_screen.dart';
import 'package:myapp/widgets/us_recommendation_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _analyticsService.logAppOpen();
    _checkDisclaimer();
  }

  Future<void> _checkDisclaimer() async {
    // Wait for the locale to be available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locale = Localizations.localeOf(context);
      if (locale.languageCode == 'en') {
        final prefs = await SharedPreferences.getInstance();
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
      builder: (context) => AlertDialog(
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
              if (mounted) Navigator.pop(context);
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(image: pickedFile),
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    _analyticsService.logGalleryClick();
    developer.log('갤러리 버튼 클릭됨', name: 'com.example.myapp.ui');
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(image: pickedFile),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.homeAppBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
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
      body: SafeArea(
        child: SingleChildScrollView(
          // Changed from Padding to SingleChildScrollView to prevent overflow
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeMainQuestion,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.homeSubQuestion,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Insert US Recommendation Section here
                const USRecommendationSection(),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E7D32)),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                    height:
                        40), // Added spacing instead of Spacer since we are in SingleChildScrollView
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt_rounded, size: 28),
                    label: Text(l10n.homeBtnCamera),
                    onPressed: _pickImageFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(l10n.homeBtnGallery),
                    onPressed: _pickImageFromGallery,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.homeDisclaimer,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
