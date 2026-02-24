import 'package:flutter/material.dart';
import '../../../../data/models/recent_analysis_model.dart';
import 'payment_bottom_sheet.dart';
import 'package:myapp/l10n/app_localizations.dart';

class RecentAnalysisCard extends StatelessWidget {
  final RecentAnalysisModel analysis;

  const RecentAnalysisCard({
    super.key,
    required this.analysis,
  });

  void _showPaymentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PaymentBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Color getRiskColor() {
      switch (analysis.overallRisk) {
        case 'safe':
          return Colors.green;
        case 'warning':
          return Colors.orange;
        case 'danger':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String getRiskIcon() {
      switch (analysis.overallRisk) {
        case 'safe':
          return '🟢';
        case 'warning':
          return '🟡';
        case 'danger':
          return '🔴';
        default:
          return '⚪';
      }
    }

    final String dateString =
        '${analysis.analyzedAt.year}.${analysis.analyzedAt.month.toString().padLeft(2, '0')}.${analysis.analyzedAt.day.toString().padLeft(2, '0')}';

    String productsString = '';
    if (analysis.productNames.isNotEmpty) {
      productsString = analysis.productNames.first;
      if (analysis.productCount > 1) {
        // Here we could use l10n.analyzedProducts + count, but sticking to minor changes
        productsString += ' 외 ${analysis.productCount - 1}개 제품';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                l10n.recentAnalysisTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(getRiskIcon(), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              if (analysis.riskSummary != null)
                Expanded(
                  child: Text(
                    analysis.riskSummary!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: getRiskColor(),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            productsString,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.recentAnalysisDate(dateString),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _showPaymentBottomSheet(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.btnReanalyze,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
