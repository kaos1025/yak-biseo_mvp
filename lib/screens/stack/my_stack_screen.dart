import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/saved_product.dart';
import 'package:myapp/models/saved_stack.dart';
import 'package:myapp/screens/subscription/paywall_screen.dart';
import 'package:myapp/services/stack_service.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/screens/stack/quick_check_screen.dart';
import 'package:myapp/theme/app_theme.dart';

class MyStackScreen extends StatefulWidget {
  const MyStackScreen({super.key});

  @override
  State<MyStackScreen> createState() => _MyStackScreenState();
}

class _MyStackScreenState extends State<MyStackScreen> {
  final StackService _stackService = StackService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  SavedStack? _stack;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoad();
  }

  Future<void> _checkAccessAndLoad() async {
    await _subscriptionService.initialize();
    final canAccess = await _subscriptionService.canUseMyStack();

    if (!canAccess && mounted) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(trigger: PaywallTrigger.myStack),
        ),
      );
      if (result != true && mounted) {
        Navigator.of(context).pop();
        return;
      }
    }

    await _loadStack();
  }

  Future<void> _loadStack() async {
    setState(() => _isLoading = true);
    final stack = await _stackService.getStack();
    if (mounted) {
      setState(() {
        _stack = stack;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeProduct(int index) async {
    final product = _stack!.products[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove supplement'),
        content: Text('Remove "${product.name}" from your stack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updatedProducts = List<SavedProduct>.from(_stack!.products)
      ..removeAt(index);

    if (updatedProducts.isEmpty) {
      await _stackService.deleteStack();
      if (mounted) setState(() => _stack = null);
    } else {
      final updatedStack = SavedStack(
        products: updatedProducts,
        lastAnalyzed: _stack!.lastAnalyzed,
        lastAnalysisJson: _stack!.lastAnalysisJson,
      );
      await _stackService.saveStack(updatedStack);
      if (mounted) setState(() => _stack = updatedStack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Stack'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stack == null
              ? _buildEmptyState()
              : _buildStackContent(),
    );
  }

  // ── 빈 상태 ──

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.black.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 20),
            const Text(
              'No supplements saved yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan your supplements to build your stack',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // HomeScreen으로 돌아가서 스캔
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Supplements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 스택 콘텐츠 ──

  Widget _buildStackContent() {
    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _stack!.products.length,
            itemBuilder: (context, index) =>
                _buildProductTile(_stack!.products[index], index),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  // ── 상단 요약 카드 ──

  Widget _buildSummaryCard() {
    final productCount = _stack!.products.length;
    final totalMonthlyCost = _stack!.products.fold<double>(
      0,
      (sum, p) => sum + (p.monthlyCost ?? 0),
    );
    final lastDate = DateFormat.yMMMd().format(_stack!.lastAnalyzed);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            '$productCount',
            productCount == 1 ? 'supplement' : 'supplements',
            Icons.medication_rounded,
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE0E0E0),
          ),
          _buildSummaryItem(
            totalMonthlyCost > 0
                ? '\$${totalMonthlyCost.toStringAsFixed(2)}'
                : '—',
            '/mo',
            Icons.attach_money_rounded,
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE0E0E0),
          ),
          _buildSummaryItem(
            lastDate,
            'last analyzed',
            Icons.schedule_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 제품 타일 ──

  Widget _buildProductTile(SavedProduct product, int index) {
    final ingredientPreview = product.ingredients.take(3).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          product.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ingredientPreview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ingredientPreview,
                style: const TextStyle(fontSize: 13, color: Colors.black45),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (product.monthlyCost != null && product.monthlyCost! > 0) ...[
              const SizedBox(height: 4),
              Text(
                '\$${product.monthlyCost!.toStringAsFixed(2)}/mo',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.black38),
          onPressed: () => _removeProduct(index),
          tooltip: 'Remove',
        ),
      ),
    );
  }

  // ── 하단 액션 버튼 ──

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => const QuickCheckScreen(),
                        ),
                      )
                      .then((_) => _loadStack());
                },
                icon: const Text('⚡', style: TextStyle(fontSize: 16)),
                label: const Text('Quick Check'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // HomeScreen으로 돌아가서 스캔
                },
                icon: const Text('🔄', style: TextStyle(fontSize: 16)),
                label: const Text('Re-analyze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }
}
