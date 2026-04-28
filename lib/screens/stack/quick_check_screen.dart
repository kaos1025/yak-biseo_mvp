import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/l10n/app_localizations.dart';
import 'package:myapp/models/saved_product.dart';
import 'package:myapp/models/saved_stack.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';
import 'package:myapp/screens/subscription/paywall_screen.dart';
import 'package:myapp/services/gemini_analysis_service.dart';
import 'package:myapp/services/stack_service.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/theme/supplecut_tokens.dart';

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
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.quickCheckErrorRetry;
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _addToStack() async {
    if (_result == null || _stack == null) return;
    final l10n = AppLocalizations.of(context)!;

    final existingNames =
        _stack!.products.map((p) => p.name.trim().toLowerCase()).toSet();

    final newProducts = _result!.products
        .where((p) => !existingNames.contains(p.name.trim().toLowerCase()))
        .map((p) => SavedProduct(
              name: p.name,
              ingredients: p.ingredients.map((i) => i.name).toList(),
              monthlyCost: p.monthlyCostUsd > 0 ? p.monthlyCostUsd : null,
            ))
        .toList();

    if (newProducts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quickCheckSnackAlreadyInStack),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(false);
      }
      return;
    }

    final updatedStack = SavedStack(
      products: [..._stack!.products, ...newProducts],
      lastAnalyzed: DateTime.now(),
      lastAnalysisJson: _stack!.lastAnalysisJson,
    );

    try {
      await _stackService.saveStack(updatedStack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quickCheckSnackAdded),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.quickCheckSnackFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ScColors.surface2,
      appBar: AppBar(
        title: Text(l10n.quickCheckTitle),
        backgroundColor: ScColors.surface2,
        foregroundColor: ScColors.ink,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ScColors.brand),
            )
          : _stack == null
              ? _buildNoStackState(l10n)
              : _buildContent(l10n),
    );
  }

  // ── 분기 1: 저장된 스택 없음 ──

  Widget _buildNoStackState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ScSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: ScColors.textTer,
            ),
            const SizedBox(height: ScSpace.lg),
            Text(
              l10n.quickCheckNoStackTitle,
              style: ScText.h1.copyWith(color: ScColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ScSpace.sm),
            Text(
              l10n.quickCheckNoStackHint,
              style: ScText.body.copyWith(color: ScColors.textSec),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── 분기 2: 본문 (empty / captured / result) ──

  Widget _buildContent(AppLocalizations l10n) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ScSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStackSummary(l10n),
            const SizedBox(height: ScSpace.lg),
            _buildCaptureArea(l10n),
            const SizedBox(height: ScSpace.lg),
            if (_capturedImage != null && _result == null && !_isAnalyzing)
              _buildCheckButton(l10n),
            if (_isAnalyzing) _buildAnalyzingIndicator(l10n),
            if (_errorMessage != null) _buildError(),
            if (_result != null) ...[
              _buildDiffResults(l10n),
              const SizedBox(height: ScSpace.lg),
              _buildResultActions(l10n),
            ],
          ],
        ),
      ),
    );
  }

  // ── 상단: 기존 스택 요약 (BL-44 D1=A — chip text overflow fix) ──

  Widget _buildStackSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(ScSpace.lg),
      decoration: BoxDecoration(
        color: ScColors.surface,
        borderRadius: BorderRadius.circular(ScRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickCheckCurrentStack(_stack!.products.length),
            style: ScText.h2.copyWith(color: ScColors.ink),
          ),
          const SizedBox(height: ScSpace.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _stack!.products
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: ScSpace.xs),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Chip(
                          label: Text(
                            p.name,
                            style: ScText.caption
                                .copyWith(color: ScColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          backgroundColor: ScColors.brandTint,
                          side: BorderSide.none,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          elevation: 0,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── 중앙: 사진 촬영 영역 (empty 드롭존 / captured 프리뷰) ──

  Widget _buildCaptureArea(AppLocalizations l10n) {
    if (_capturedImage != null) {
      return Container(
        decoration: BoxDecoration(
          color: ScColors.surface,
          borderRadius: BorderRadius.circular(ScRadius.md),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(ScRadius.md),
              ),
              child: Image.file(
                File(_capturedImage!.path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ScSpace.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _capturePhoto(source: ImageSource.camera),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: ScColors.brand,
                    ),
                    label: Text(
                      l10n.quickCheckRetake,
                      style:
                          ScText.caption.copyWith(color: ScColors.brand),
                    ),
                  ),
                  const SizedBox(width: ScSpace.lg),
                  TextButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () =>
                            _capturePhoto(source: ImageSource.gallery),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 18,
                      color: ScColors.brand,
                    ),
                    label: Text(
                      l10n.quickCheckGallery,
                      style:
                          ScText.caption.copyWith(color: ScColors.brand),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: ScColors.brandTint,
          borderRadius: BorderRadius.circular(ScRadius.md),
          border: Border.all(color: ScColors.border, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: ScColors.brand,
              ),
              const SizedBox(height: ScSpace.md),
              Text(
                l10n.quickCheckScanNew,
                style: ScText.h2.copyWith(color: ScColors.ink),
              ),
              const SizedBox(height: ScSpace.xs),
              Text(
                l10n.quickCheckScanHint,
                style: ScText.caption.copyWith(color: ScColors.textSec),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: ScColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: ScColors.ink,
              ),
              title: Text(
                l10n.quickCheckCamera,
                style: ScText.body.copyWith(color: ScColors.ink),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _capturePhoto(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: ScColors.ink,
              ),
              title: Text(
                l10n.quickCheckGallery,
                style: ScText.body.copyWith(color: ScColors.ink),
              ),
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

  Widget _buildCheckButton(AppLocalizations l10n) {
    return SizedBox(
      height: ScTouch.primaryCta,
      child: ElevatedButton.icon(
        onPressed: _runQuickCheck,
        icon: const Icon(Icons.bolt_outlined, size: 20),
        label: Text(l10n.quickCheckCheckNow),
        style: ElevatedButton.styleFrom(
          backgroundColor: ScColors.brand,
          foregroundColor: ScColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ScRadius.md),
          ),
          textStyle: ScText.h2,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAnalyzingIndicator(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(ScSpace.xl),
      decoration: BoxDecoration(
        color: ScColors.surface,
        borderRadius: BorderRadius.circular(ScRadius.md),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: ScColors.brand),
          const SizedBox(height: ScSpace.lg),
          Text(
            l10n.quickCheckChecking,
            style: ScText.body.copyWith(color: ScColors.textSec),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(ScSpace.lg),
      decoration: BoxDecoration(
        color: ScColors.dangerBg,
        borderRadius: BorderRadius.circular(ScRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: ScColors.dangerAccent),
          const SizedBox(width: ScSpace.md),
          Expanded(
            child: Text(
              _errorMessage!,
              style: ScText.body.copyWith(color: ScColors.dangerText),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diff 결과 — 5섹션 additive Column (PATCH-15) ──

  Widget _buildDiffResults(AppLocalizations l10n) {
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

    final sections = <Widget>[];

    if (hasNewIssues) {
      sections.add(_buildDiffSection(
        icon: Icons.warning_amber_outlined,
        accent: ScColors.dangerAccent,
        title: l10n.quickCheckNewIssues,
        items: [
          ..._result!.duplicates
              .map((d) => l10n.quickCheckOverlapDetected(d.ingredient)),
          ..._result!.singleProductUlExcess.map(
            (u) => l10n.quickCheckUlExceeded(u.ingredient, u.amount, u.ul),
          ),
          ..._result!.safetyAlerts.map((a) => a.summary),
        ],
      ));
    }

    if (hasExistingIssues) {
      sections.add(_buildDiffSection(
        icon: Icons.priority_high,
        accent: ScColors.warnAccent,
        title: l10n.quickCheckExistingIssues,
        items: _result!.ulAtLimit
            .map(
              (u) => l10n.quickCheckUlAtPercent(
                u.ingredient,
                u.percentageOfUl.round(),
              ),
            )
            .toList(),
      ));
    }

    if (isSafe) {
      sections.add(_buildDiffSection(
        icon: Icons.check_circle_outline,
        accent: ScColors.brand,
        title: l10n.quickCheckSafeToAddTitle,
        items: [l10n.quickCheckSafeToAddBody],
      ));
    }

    if (hasSynergies) {
      sections.add(_buildDiffSection(
        icon: Icons.auto_awesome_outlined,
        accent: ScColors.warnAccent,
        title: l10n.quickCheckSynergies,
        items: _result!.functionalOverlaps
            .where((fo) => fo.severity == 'low')
            .map((fo) => fo.warning)
            .toList(),
      ));
    }

    if (totalNewCost > 0) {
      sections.add(_buildDiffSection(
        icon: Icons.savings_outlined,
        accent: ScColors.warnAccent,
        title: l10n.quickCheckCostImpact,
        items: [
          l10n.quickCheckCostMonthly(totalNewCost.toStringAsFixed(2)),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(ScSpace.lg),
      decoration: BoxDecoration(
        color: ScColors.surface,
        borderRadius: BorderRadius.circular(ScRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickCheckResultsHeader,
            style: ScText.h2.copyWith(color: ScColors.ink),
          ),
          const SizedBox(height: ScSpace.lg),
          for (var i = 0; i < sections.length; i++) ...[
            sections[i],
            if (i < sections.length - 1)
              const SizedBox(height: ScSpace.md),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffSection({
    required IconData icon,
    required Color accent,
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: ScSpace.sm),
            Text(title, style: ScText.h2.copyWith(color: accent)),
          ],
        ),
        const SizedBox(height: ScSpace.xs),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(
              left: 28,
              bottom: ScSpace.xs,
            ),
            child: Text(
              item,
              style: ScText.body.copyWith(color: ScColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  // ── 결과 하단 액션 ──

  Widget _buildResultActions(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: ScTouch.primaryCta,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: ScColors.textSec,
                side: const BorderSide(color: ScColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScRadius.md),
                ),
                textStyle: ScText.body,
              ),
              child: Text(l10n.quickCheckSkip),
            ),
          ),
        ),
        const SizedBox(width: ScSpace.md),
        Expanded(
          child: SizedBox(
            height: ScTouch.primaryCta,
            child: ElevatedButton.icon(
              onPressed: _addToStack,
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.quickCheckAddToMyStack),
              style: ElevatedButton.styleFrom(
                backgroundColor: ScColors.brand,
                foregroundColor: ScColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ScRadius.md),
                ),
                textStyle: ScText.body,
                elevation: 0,
              ),
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
