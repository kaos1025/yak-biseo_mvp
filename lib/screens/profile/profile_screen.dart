import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_profile.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../onboarding_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getProfile();
    if (!mounted) return;

    if (profile == null) {
      // 프로필 없음 → SetupScreen으로 바로 이동
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
      if (!mounted) return;
      if (result == true) {
        // 설정 완료 → 홈으로 바로 복귀
        if (mounted) Navigator.pop(context);
        return;
      } else {
        // X로 닫음 → 홈으로 복귀
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(initialProfile: _profile),
      ),
    );
    if (result == true && mounted) {
      final saved = await _profileService.getProfile();
      if (mounted) setState(() => _profile = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _editProfile,
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 정보 카드
            if (_profile != null) _buildProfileCard(_profile!),

            const SizedBox(height: 24),

            // 프로필 삭제
            if (_profile != null)
              Center(
                child: TextButton(
                  onPressed: _confirmDeleteProfile,
                  child: const Text(
                    'Delete My Health Profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Legal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            _buildLegalTile(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              onTap: () => _launchUrl(
                  'https://temporal-guppy-37e.notion.site/Privacy-Policy-SuppleCut-312c5710750781368e50f9682a70a76c'),
            ),
            _buildLegalTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => _launchUrl(
                  'https://temporal-guppy-37e.notion.site/Terms-of-Service-SuppleCut-312c571075078197a122dcf42e646399'),
            ),
            _buildLegalTile(
              icon: Icons.medical_information_outlined,
              title: 'FDA Disclaimer',
              onTap: () => _showFdaDisclaimer(context),
            ),
            _buildLegalTile(
              icon: Icons.school_outlined,
              title: 'View Tutorial',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnboardingScreen(
                      onComplete: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    final genderLabel = switch (profile.gender) {
      'male' => 'Male',
      'female' => 'Female',
      _ => 'Other',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기본 정보
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '$genderLabel · ${profile.age} years old · ${profile.weightKg.toStringAsFixed(1)}kg',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // 약물
          if (profile.medications.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.medication_outlined,
              'Medications',
              profile.medications.join(', '),
            ),
          ],

          // 건강 상태
          if (profile.conditions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.health_and_safety_outlined,
              'Conditions',
              profile.conditions.join(', '),
            ),
          ],

          // 건강 목표
          if (profile.goals.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.flag_outlined,
              'Goals',
              profile.goals.join(', '),
            ),
          ],

          // 임신 여부
          if (profile.isPregnant) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.pregnant_woman,
              'Pregnant / Nursing',
              'Yes',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2E7D32)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDeleteProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your health profile?'),
        content: const Text(
          'Your age, weight, medications and health goals will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _profileService.deleteProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health profile deleted')),
      );
      Navigator.pop(context);
    }
  }

  void _showFdaDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('FDA Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'This application provides information for educational purposes only. '
            'The contents are not intended to be a substitute for professional medical advice, diagnosis, or treatment. '
            'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.'
            '\n\nThese statements have not been evaluated by the Food and Drug Administration. '
            'This product is not intended to diagnose, treat, cure, or prevent any disease.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
