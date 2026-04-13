import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/models/user_profile.dart';
import 'package:myapp/services/profile_service.dart';
import 'package:myapp/theme/app_theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final ProfileService _profileService = ProfileService();

  int _currentStep = 0;
  static const int _totalSteps = 3;

  // ── Step 1: 기본 정보 ──
  String? _gender;
  int _birthYear = 1975;
  final TextEditingController _weightController = TextEditingController();
  bool _isLb = false;

  // ── Step 2: 복용 약물 ──
  final TextEditingController _medicationController = TextEditingController();
  final List<String> _medications = [];

  // ── Step 3: 건강 목표 ──
  final Set<String> _selectedGoals = {};

  static const List<String> _goalOptions = [
    'Sleep',
    'Energy',
    'Joint Health',
    'Immunity',
    'Stress & Calm',
    'Focus',
    'Skin & Hair',
    'Digestive Health',
    'Athletic Performance',
    'Heart Health',
    'Weight Management',
  ];

  bool get _isStep1Valid =>
      _gender != null && _weightController.text.trim().isNotEmpty;

  bool get _isLastStep => _currentStep == _totalSteps - 1;

  void _nextStep() {
    if (_isLastStep) {
      _saveAndFinish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveAndFinish() async {
    double weightKg;
    final rawWeight = double.tryParse(_weightController.text.trim());
    if (rawWeight == null) return;
    weightKg = _isLb ? rawWeight * 0.453592 : rawWeight;

    final profile = UserProfile(
      birthYear: _birthYear,
      gender: _gender!,
      weightKg: weightKg,
      medications: List.unmodifiable(_medications),
      goals: _selectedGoals.toList(),
    );

    try {
      await _profileService.saveProfile(profile);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previousStep();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
          title: Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── 단계 인디케이터 ──

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalSteps, (i) {
          final isActive = i <= _currentStep;
          return Container(
            width: isActive ? 28 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }

  // ── 하단 바 ──

  Widget _buildBottomBar() {
    final canProceed = _currentStep == 0 ? _isStep1Valid : true;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              TextButton(
                onPressed: _isLastStep ? _nextStep : null,
                child: Text(
                  _isLastStep ? 'Skip' : '',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const Spacer(),
            ] else
              const Spacer(),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: canProceed ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isLastStep ? 'Done' : 'Next',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Step 1 — 기본 정보
  // ══════════════════════════════════════════════

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGenderSelector(),
          const SizedBox(height: 32),
          _buildBirthYearPicker(),
          const SizedBox(height: 32),
          _buildWeightInput(),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your sex?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildGenderCard('male', Icons.male, 'Male'),
            const SizedBox(width: 12),
            _buildGenderCard('female', Icons.female, 'Female'),
            const SizedBox(width: 12),
            _buildGenderCard('other', Icons.transgender, 'Other'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(String value, IconData icon, String label) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? AppTheme.primaryColor : Colors.black45,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBirthYearPicker() {
    final currentYear = DateTime.now().year;
    final age = currentYear - _birthYear;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What year were you born?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListWheelScrollView.useDelegate(
            controller: FixedExtentScrollController(
              initialItem: _birthYear - 1930,
            ),
            itemExtent: 48,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              setState(() => _birthYear = 1930 + index);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final year = 1930 + index;
                final isSelected = year == _birthYear;
                return Center(
                  child: Text(
                    '$year',
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 20,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected ? AppTheme.primaryColor : Colors.black38,
                    ),
                  ),
                );
              },
              childCount: currentYear - 1930 + 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Age: $age',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's your weight?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  hintText: _isLb ? 'e.g. 154' : 'e.g. 70',
                  hintStyle: const TextStyle(color: Colors.black26),
                  suffix: Text(
                    _isLb ? 'lb' : 'kg',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            _buildUnitToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildUnitButton('kg', !_isLb),
          _buildUnitButton('lb', _isLb),
        ],
      ),
    );
  }

  Widget _buildUnitButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isLb = label == 'lb'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Step 2 — 복용 약물
  // ══════════════════════════════════════════════

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Any medications?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Helps detect supplement-drug interactions',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _medicationController,
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addMedication(),
                  decoration: InputDecoration(
                    hintText: 'e.g. Metformin',
                    hintStyle: const TextStyle(color: Colors.black26),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _addMedication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Add', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _medications.map((med) {
              return Chip(
                label: Text(med, style: const TextStyle(fontSize: 14)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => setState(() => _medications.remove(med)),
                backgroundColor: const Color(0xFFF1F8E9),
                side: BorderSide(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
          if (_medications.isEmpty) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.medication_outlined,
                      size: 48, color: Colors.black.withValues(alpha: 0.12)),
                  const SizedBox(height: 8),
                  const Text(
                    'No medications added',
                    style: TextStyle(fontSize: 14, color: Colors.black38),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addMedication() {
    final text = _medicationController.text.trim();
    if (text.isEmpty) return;
    if (_medications.contains(text)) return;
    setState(() {
      _medications.add(text);
      _medicationController.clear();
    });
  }

  // ══════════════════════════════════════════════
  // Step 3 — 건강 목표
  // ══════════════════════════════════════════════

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your health goals?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select all that apply',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _goalOptions.map((goal) {
              final isSelected = _selectedGoals.contains(goal);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(goal);
                    } else {
                      _selectedGoals.add(goal);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Text(
                    goal,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _medicationController.dispose();
    super.dispose();
  }
}
