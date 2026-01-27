import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final String name;
  final String? brand;
  final String? description;
  final String? imageUrl;
  final String status; // 'SAFE', 'WARNING', 'REDUNDANT', 'UNKNOWN'
  final bool isExpandedDefault;
  final VoidCallback? onTap;

  // Additional details
  final String? ingredients;
  final String? dosage;
  final int? price;

  // UX Improvement: Add Button support
  final bool isAdded;
  final VoidCallback? onAdd;

  const ProductCard({
    super.key,
    required this.name,
    this.brand,
    this.description,
    this.imageUrl,
    this.status = 'SAFE',
    this.isExpandedDefault = false,
    this.onTap,
    this.ingredients,
    this.dosage,
    this.price,
    this.isAdded = false, // Default false
    this.onAdd,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpandedDefault;
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case 'WARNING':
      case 'REDUNDANT':
        return Colors.orange;
      case 'UNKNOWN':
        return Colors.grey;
      case 'SAFE':
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusText() {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    switch (widget.status) {
      case 'WARNING':
        return isEnglish ? 'Warning' : '주의';
      case 'REDUNDANT':
        return isEnglish ? 'Redundant' : '중복';
      case 'UNKNOWN':
        return isEnglish ? 'Unknown' : '정보 없음';
      case 'SAFE':
      default:
        return isEnglish ? 'KFDA Certified' : '식약처 인증';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isWarning =
        widget.status == 'WARNING' || widget.status == 'REDUNDANT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? Colors.orange.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: widget.isExpandedDefault,
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
            if (widget.onTap != null) widget.onTap!();
          },
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.status == 'SAFE'
                              ? Icons.check_circle
                              : Icons.info,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.brand != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  // Add Button if onAdd is provided
                  if (widget.onAdd != null) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 32,
                      child: widget.isAdded
                          ? TextButton.icon(
                              onPressed: null, // Disabled
                              icon: const Icon(Icons.check,
                                  size: 16, color: Colors.grey),
                              label: Text(
                                  Localizations.localeOf(context)
                                              .languageCode ==
                                          'en'
                                      ? "Added"
                                      : "담김",
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            )
                          : OutlinedButton.icon(
                              onPressed: widget.onAdd,
                              icon: const Icon(Icons.add,
                                  size: 16, color: AppTheme.primaryColor),
                              label: Text(
                                  Localizations.localeOf(context)
                                              .languageCode ==
                                          'en'
                                      ? "Add"
                                      : "담기",
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                side: const BorderSide(
                                    color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          subtitle: !_isExpanded && widget.description != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                )
              : null,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                  image: DecorationImage(
                    image: NetworkImage(widget.imageUrl!),
                    fit: BoxFit.contain,
                    onError: (_, __) {},
                  ),
                ),
                child: widget.imageUrl!.isEmpty
                    ? const Icon(Icons.broken_image,
                        size: 50, color: Colors.grey)
                    : null,
              ),
            if (widget.ingredients != null) ...[
              _buildDetailRow(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Ingredients'
                      : '원재료',
                  widget.ingredients!),
              const SizedBox(height: 12),
            ],
            if (widget.dosage != null) ...[
              _buildDetailRow(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Usage'
                      : '섭취방법',
                  widget.dosage!),
              const SizedBox(height: 12),
            ],
            if (widget.description != null &&
                widget.description!.isNotEmpty) ...[
              _buildDetailRow(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Description'
                      : '내용',
                  widget.description!),
              const SizedBox(height: 12),
            ],
            if (widget.price != null && widget.price! > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  Localizations.localeOf(context).languageCode == 'en'
                      ? 'Est. Price: \$${widget.price}'
                      : '예상 가격: ${widget.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
