import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/saved_product.dart';
import 'package:myapp/models/saved_stack.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/screens/subscription/paywall_screen.dart';
import 'package:myapp/services/gemini_analysis_service.dart';
import 'package:myapp/services/stack_service.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/theme/app_theme.dart';

class QuickCheckScreen extends StatefulWidget {
  const QuickCheckScreen({super.key});

  @override
  State<QuickCheckScreen> createState() => _QuickCheckScreenState();
}

class _QuickCheckScreenState extends State<QuickCheckScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiAnalysisService _analysisService = GeminiAnalysisService();
  final StackService _stackService = StackService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  SavedStack? _stack;
  XFile? _capturedImage;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isAnalyzing = false;

  // 분석 결과
  SuppleCutAnalysisResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    await _subscriptionService.initialize();
    final canAccess = await _subscriptionService.canUseQuickCheck();

    if (!canAccess && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              const PaywallScreen(trigger: PaywallTrigger.quickCheck),
        ),
      );
      if (result != true && mounted) {
        Navigator.of(context).pop();
        return;
      }
    }

    final stack = await _stackService.getStack();
    if (mounted) {
      setState(() {
        _stack = stack;
        _isLoading = false;
      });
    }
  }

  Future<void> _capturePhoto({ImageSource source = ImageSource.camera}) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _capturedImage = pickedFile;
        _imageBytes = bytes;
        _result = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _runQuickCheck() async {
    if (_imageBytes == null || _stack == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final onestopResult =
          await _analysisService.quickCheck(_imageBytes!, _stack!);
      final result = onestopResult.toSuppleCutAnalysisResult();
      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Analysis failed. Please try again.';
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _addToStack() async {
    if (_result == null || _stack == null) return;

    final newProducts = _result!.products.map((p) {
      return SavedProduct(
        name: p.name,
        ingredients: p.ingredients.map((i) => i.name).toList(),
        monthlyCost: p.monthlyCostUsd > 0 ? p.monthlyCostUsd : null,
      );
    }).toList();

    final updatedStack = SavedStack(
      products: [..._stack!.products, ...newProducts],
      lastAnalyzed: DateTime.now(),
      lastAnalysisJson: _stack!.lastAnalysisJson,
    );

    try {
      await _stackService.saveStack(updatedStack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to My Stack ✓'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Quick Check'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stack == null
              ? _buildNoStackState()
              : _buildContent(),
    );
  }

  Widget _buildNoStackState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'No saved stack yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            SizedBox(height: 8),
            Text(
              'Scan your supplements first to build your stack,\nthen use Quick Check to test new ones.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStackSummary(),
          const SizedBox(height: 16),
          _buildCaptureArea(),
          const SizedBox(height: 16),
          if (_capturedImage != null && _result == null && !_isAnalyzing)
            _buildCheckButton(),
          if (_isAnalyzing) _buildAnalyzingIndicator(),
          if (_errorMessage != null) _buildError(),
          if (_result != null) ...[
            _buildDiffResults(),
            const SizedBox(height: 16),
            _buildResultActions(),
          ],
        ],
      ),
    );
  }

  // ── 상단: 기존 스택 요약 ──

  Widget _buildStackSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your current stack: ${_stack!.products.length} supplements',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _stack!.products.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    label: Text(p.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: const Color(0xFFF1F8E9),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 중앙: 사진 촬영 영역 ──

  Widget _buildCaptureArea() {
    if (_capturedImage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                File(_capturedImage!.path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _capturePhoto(source: ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Re-take'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _capturePhoto(source: ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded,
                  size: 48, color: AppTheme.primaryColor),
              SizedBox(height: 12),
              Text(
                '📸 Scan a new supplement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Take a photo or choose from gallery',
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _capturePhoto(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _capturePhoto(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Check 버튼 ──

  Widget _buildCheckButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _runQuickCheck,
        icon: const Text('⚡', style: TextStyle(fontSize: 18)),
        label: const Text('Check Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Checking compatibility...',
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diff 결과 ──

  Widget _buildDiffResults() {
    final hasNewIssues = _result!.duplicates.isNotEmpty ||
        _result!.singleProductUlExcess.isNotEmpty ||
        _result!.safetyAlerts.isNotEmpty;
    final hasExistingIssues = _result!.ulAtLimit.isNotEmpty;
    final hasSynergies =
        _result!.functionalOverlaps.any((fo) => fo.severity == 'low');
    final isSafe = !hasNewIssues && !hasExistingIssues;

    final totalNewCost = _result!.products.fold<double>(
      0,
      (sum, p) => sum + p.monthlyCostUsd,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Check Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // 🔴 New Issues
          if (hasNewIssues) ...[
            _buildDiffSection(
              '🔴',
              'New Issues',
              Colors.red,
              [
                ..._result!.duplicates
                    .map((d) => '${d.ingredient}: overlap detected'),
                ..._result!.singleProductUlExcess.map((u) =>
                    '${u.ingredient}: exceeds UL (${u.amount} / ${u.ul})'),
                ..._result!.safetyAlerts.map((a) => a.summary),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 🟡 Existing Issues worsened
          if (hasExistingIssues) ...[
            _buildDiffSection(
              '🟡',
              'Existing Issues',
              Colors.orange,
              _result!.ulAtLimit
                  .map((u) =>
                      '${u.ingredient}: now at ${u.percentageOfUl.round()}% UL')
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // 🟢 Safe to Add
          if (isSafe)
            _buildDiffSection(
              '🟢',
              'Safe to Add',
              AppTheme.primaryColor,
              [
                'No new issues detected. This supplement is compatible with your stack.'
              ],
            ),

          // ⭐ Synergies
          if (hasSynergies) ...[
            const SizedBox(height: 12),
            _buildDiffSection(
              '⭐',
              'Synergies',
              const Color(0xFFF9A825),
              _result!.functionalOverlaps
                  .where((fo) => fo.severity == 'low')
                  .map((fo) => fo.warning)
                  .toList(),
            ),
          ],

          // 💰 Cost Impact
          if (totalNewCost > 0) ...[
            const SizedBox(height: 12),
            _buildDiffSection(
              '💰',
              'Cost Impact',
              Colors.blueGrey,
              ['+\$${totalNewCost.toStringAsFixed(2)}/mo'],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffSection(
      String emoji, String title, Color color, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            )),
      ],
    );
  }

  // ── 결과 하단 액션 ──

  Widget _buildResultActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: const BorderSide(color: Colors.black26),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Skip', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _addToStack,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add to My Stack'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }
}
