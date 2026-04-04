import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  static const String _heightCmKey = 'profile_height_cm';
  static const String _weightKgKey = 'profile_weight_kg';

  // Internally stored in Metric units (cm, kg)
  double _heightCm = 170.0;
  double _weightKg = 70.0;
  bool _loaded = false;

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _inchesController; // for US height

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _inchesController = TextEditingController();
    _loadSavedValues();
  }

  Future<void> _loadSavedValues() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHeight = prefs.getDouble(_heightCmKey);
    final savedWeight = prefs.getDouble(_weightKgKey);
    if (savedHeight != null) _heightCm = savedHeight;
    if (savedWeight != null) _weightKg = savedWeight;
    if (!mounted) return;
    setState(() {
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _updateControllers(bool isEn) {
    if (isEn) {
      final ftIn = UnitConverter.cmToFeetInches(_heightCm);
      _heightController.text = ftIn['feet'].toString();
      _inchesController.text = ftIn['inches'].toString();
      _weightController.text =
          UnitConverter.kgToLb(_weightKg).toStringAsFixed(1);
    } else {
      _heightController.text = _heightCm.toStringAsFixed(1);
      _weightController.text = _weightKg.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    // Sync controllers once after saved values are loaded
    if (_loaded) {
      _loaded = false;
      _updateControllers(isEn);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEn ? 'Personal Information' : '개인 정보 입력',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Height Input
              Text(l10n.heightLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (isEn)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixText: 'ft',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _saveMetric(isEn),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _inchesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixText: 'in',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _saveMetric(isEn),
                      ),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: 'cm',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => _saveMetric(isEn),
                ),

              const SizedBox(height: 20),

              // Weight Input
              Text(l10n.weightLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: isEn ? 'lb' : 'kg',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) => _saveMetric(isEn),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setDouble(_heightCmKey, _heightCm);
                      await prefs.setDouble(_weightKgKey, _weightKg);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(isEn
                                ? 'Saved! (Metric: ${_heightCm.toStringAsFixed(1)}cm, ${_weightKg.toStringAsFixed(1)}kg)'
                                : '저장되었습니다!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.saveBtn),
                ),
              ),

              const SizedBox(height: 32),
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
      ),
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

  void _saveMetric(bool isEn) {
    setState(() {
      if (isEn) {
        int ft = int.tryParse(_heightController.text) ?? 0;
        int inch = int.tryParse(_inchesController.text) ?? 0;
        _heightCm = UnitConverter.feetInchesToCm(ft, inch);

        double lb = double.tryParse(_weightController.text) ?? 0;
        _weightKg = UnitConverter.lbToKg(lb);
      } else {
        _heightCm = double.tryParse(_heightController.text) ?? 0;
        _weightKg = double.tryParse(_weightController.text) ?? 0;
      }
    });
  }
}
