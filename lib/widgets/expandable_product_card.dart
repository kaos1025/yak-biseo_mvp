import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/l10n/app_localizations.dart';

class ExpandableProductCard extends StatefulWidget {
  final String brand;
  final String name;
  final String price;
  final List<String> tags;
  final String? ingredients;
  final String? dosage;
  final bool isAdded;
  final VoidCallback? onAdd;
  final String? imageUrl;

  // New fields for specific design
  final String status; // 'danger', 'warning', 'safe'
  final int removalSavingsAmount;
  final int originalPrice;
  final num durationMonths;
  final bool isRecommendedToRemove;

  const ExpandableProductCard({
    super.key,
    required this.brand,
    required this.name,
    required this.price,
    required this.tags,
    this.ingredients,
    this.dosage,
    this.isAdded = false,
    this.onAdd,
    this.imageUrl,
    this.status = 'safe',
    this.isRecommendedToRemove = false,
    this.removalSavingsAmount = 0,
    this.originalPrice = 0,
    this.durationMonths = 1,
  });

  @override
  State<ExpandableProductCard> createState() => _ExpandableProductCardState();
}

class _ExpandableProductCardState extends State<ExpandableProductCard> {
  bool _isExpanded = false;

  Color _getBackgroundColor() {
    switch (widget.status) {
      case 'danger':
        return const Color(0xFFFFEBEE); // Light Red
      case 'warning':
        return const Color(0xFFFFF8E1); // Light Yellow
      case 'safe':
      default:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (widget.status) {
      case 'danger':
        return const Color(0xFFFFCDD2);
      case 'warning':
        return const Color(0xFFFFE0B2);
      case 'safe':
      default:
        return Colors.grey.withValues(alpha: 0.2);
    }
  }

  Widget _buildIcon() {
    IconData iconData = Icons.medication;
    Color iconColor = Colors.green;

    switch (widget.status) {
      case 'danger':
        iconColor = const Color(0xFFD32F2F); // Red 700
        break;
      case 'warning':
        iconColor = const Color(0xFFF57C00); // Orange 700
        break;
      case 'safe':
      default:
        iconColor = const Color(0xFF4CAF50); // Green 500
        break;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _getBackgroundColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getBorderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Collapsed Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon based on status
                  _buildIcon(),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.brand,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.name,
                          style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF131613),
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: widget.tags.map((tag) {
                            return _buildTag(tag, widget.status);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Expand Icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Price Section (Separated Logic)
          if (widget.status == 'danger' || widget.isRecommendedToRemove)
            _buildDangerPriceSection()
          else if (widget.status == 'warning')
            const SizedBox
                .shrink() // Warning items usually safe to eat but duplicate
          else if (widget.onAdd != null && !widget.isAdded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildAddButton(),
              ),
            ),

          // Expanded Content
          if (_isExpanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildDangerPriceSection() {
    final currencyFormat = NumberFormat('#,###');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFEBEE).withValues(alpha: 0.5), // Slightly darker
        border: const Border(top: BorderSide(color: Color(0xFFFFCDD2))),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on_outlined,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "${currencyFormat.format(widget.originalPrice)}원 (${widget.durationMonths}개월분)",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.savings_outlined,
                  size: 18, color: Color(0xFF2E7D32)), // Green
              const SizedBox(width: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold),
                  children: [
                    const TextSpan(text: "이 제품 빼면 "),
                    TextSpan(
                        text:
                            "월 ${currencyFormat.format(widget.removalSavingsAmount)}원 절감",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, String status) {
    Color bgColor;
    Color txtColor;

    switch (status) {
      case 'danger':
        bgColor = const Color(0xFFEF5350); // Red 400
        txtColor = Colors.white;
        break;
      case 'warning':
        bgColor = const Color(0xFFFF9800); // Orange 500
        txtColor = Colors.white;
        break;
      case 'safe':
      default:
        bgColor = Colors.grey.shade100;
        txtColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, color: txtColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: widget.isAdded ? null : widget.onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              widget.isAdded ? Colors.grey.shade200 : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.isAdded ? Colors.grey : const Color(0xFF4CAF50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.isAdded ? Icons.check : Icons.add,
                size: 16,
                color: widget.isAdded ? Colors.grey : const Color(0xFF4CAF50)),
            const SizedBox(width: 4),
            Text(
              widget.isAdded
                  ? AppLocalizations.of(context)!.added
                  : AppLocalizations.of(context)!.add,
              style: TextStyle(
                fontSize: 12,
                color: widget.isAdded ? Colors.grey : const Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.ingredients != null) ...[
            Text(AppLocalizations.of(context)!.ingredients,
                style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(widget.ingredients!,
                style: const TextStyle(color: Color(0xFF333333), fontSize: 13)),
            const SizedBox(height: 12),
          ],
          if (widget.dosage != null) ...[
            Text(AppLocalizations.of(context)!.usage,
                style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(widget.dosage!,
                style: const TextStyle(color: Color(0xFF333333), fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
