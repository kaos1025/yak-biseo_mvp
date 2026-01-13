import 'package:flutter/material.dart';
import '../../core/utils/unit_converter.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Internally stored in Metric units (cm, kg)
  double _heightCm = 170.0;
  double _weightKg = 70.0;

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _inchesController; // for US height

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _inchesController = TextEditingController();
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

    // Initial sync
    if (_heightController.text.isEmpty) {
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
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
            ],
          ),
        ),
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
