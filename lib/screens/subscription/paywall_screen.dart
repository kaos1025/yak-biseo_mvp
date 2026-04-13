import 'package:flutter/material.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/theme/app_theme.dart';

enum PaywallTrigger { myStack, quickCheck, reportUpsell }

class PaywallScreen extends StatefulWidget {
  final PaywallTrigger trigger;

  /// reportUpsell 트리거일 때만 사용 — 사용자가 지금까지 쓴 금액
  final double? amountSpent;

  const PaywallScreen({
    super.key,
    required this.trigger,
    this.amountSpent,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subscriptionService.initialize();
  }

  String get _subtitle {
    switch (widget.trigger) {
      case PaywallTrigger.myStack:
        return 'Save your stack. Never re-scan again.';
      case PaywallTrigger.quickCheck:
        return 'Check new supplements against your saved stack.';
      case PaywallTrigger.reportUpsell:
        final spent = widget.amountSpent?.toStringAsFixed(2) ?? '0.00';
        return "You've spent \$$spent. Basic includes unlimited reports.";
    }
  }

  Future<void> _handlePurchase(
      Future<PurchaseResult> Function() purchase) async {
    setState(() => _isLoading = true);
    try {
      final result = await purchase();
      if (!mounted) return;
      switch (result) {
        case PurchaseResult.success:
        case PurchaseResult.alreadyOwned:
          Navigator.of(context).pop(true);
          break;
        case PurchaseResult.cancelled:
          break;
        case PurchaseResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase failed. Please try again.')),
          );
          break;
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.restorePurchases();
      if (!mounted) return;
      final tier = await _subscriptionService.getCurrentTier();
      if (!mounted) return;
      if (tier == SubscriptionTier.basic) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildFeatureList(),
                  const SizedBox(height: 32),
                  _buildSubscriptionButtons(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'SuppleCut Basic',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    const features = [
      ('My Profile', 'personalized analysis'),
      ('My Stack', 'save & manage your supplements'),
      ('Quick Check', 'scan new supplements instantly'),
      ('Unlimited Detail Reports', null),
      ('Full Drug Interaction Database', null),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: features.map((f) {
          final (title, desc) = f;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      children: desc != null
                          ? [
                              TextSpan(
                                text: ' — $desc',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black54,
                                ),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubscriptionButtons() {
    final monthlyDisplayPrice = _subscriptionService.monthlyPrice ?? '\$2.99';
    final yearlyDisplayPrice = _subscriptionService.yearlyPrice ?? '\$29.99';

    return Column(
      children: [
        // Yearly — Best Value
        _buildPlanButton(
          onTap: () =>
              _handlePurchase(_subscriptionService.purchaseBasicYearly),
          label: 'Best Value — $yearlyDisplayPrice/yr',
          sub: 'Just \$2.50/mo',
          isPrimary: true,
        ),
        const SizedBox(height: 12),
        // Monthly
        _buildPlanButton(
          onTap: () =>
              _handlePurchase(_subscriptionService.purchaseBasicMonthly),
          label: 'Start for $monthlyDisplayPrice/mo',
          sub: 'Then \$4.99/mo after 3 months',
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildPlanButton({
    required VoidCallback onTap,
    required String label,
    required String sub,
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        TextButton(
          onPressed: _isLoading ? null : _handleRestore,
          child: const Text(
            'Restore Purchases',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Not now',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black38,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cancel anytime. Billed by Google Play.',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black38,
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
