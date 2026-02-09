import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myapp/l10n/app_localizations.dart';

class ExpandableProductCard extends StatefulWidget {
  final String brand;
  final String name;
  final String price;
  final List<String> tags;
  final Map<String, Color> tagColors; // Map tag text to background color
  final Map<String, Color> tagTextColors; // Map tag text to text color
  final String? ingredients;
  final String? dosage;
  final bool isAdded;
  final VoidCallback? onAdd;
  final Color? backgroundColor; // [NEW] Allow custom glass color
  final String? imageUrl;

  const ExpandableProductCard({
    super.key,
    required this.brand,
    required this.name,
    required this.price,
    required this.tags,
    required this.tagColors,
    required this.tagTextColors,
    this.ingredients,
    this.dosage,
    this.isAdded = false,
    this.onAdd,
    this.backgroundColor,
    this.imageUrl,
    this.isRecommendedToRemove = false,
    this.removalSavingsAmount = 0,
    this.onRemoveCheckChanged,
  });

  final bool isRecommendedToRemove;
  final int removalSavingsAmount;
  final ValueChanged<bool?>? onRemoveCheckChanged;

  @override
  State<ExpandableProductCard> createState() => _ExpandableProductCardState();
}

class _ExpandableProductCardState extends State<ExpandableProductCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5), // Keep transparent glass effect
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                      // Product Image (Placeholder)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: (widget.imageUrl != null &&
                                widget.imageUrl!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.medication,
                                        color: Colors.grey, size: 30);
                                  },
                                ),
                              )
                            : const Icon(Icons.medication,
                                color: Colors.grey, size: 30),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.brand,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C7F6D),
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
                                return _buildTag(tag);
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

              // Action Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.isRecommendedToRemove)
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: false, // Visual only for now
                              onChanged: widget.onRemoveCheckChanged,
                              activeColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            Expanded(
                              child: Text(
                                "빼면 월 ${widget.removalSavingsAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원 절감",
                                style: const TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.price.isNotEmpty)
                      Text(
                        widget.price,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF131613)),
                      )
                    else
                      const SizedBox
                          .shrink(), // Empty placeholder if price is empty

                    if (!widget.isRecommendedToRemove && widget.onAdd != null)
                      _buildAddButton(),
                  ],
                ),
              ),

              // Expanded Content
              if (_isExpanded) _buildExpandedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    final bgColor = widget.tagColors[text] ?? Colors.grey.shade100;
    final txtColor = widget.tagTextColors[text] ?? Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10, color: txtColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: widget.isAdded ? null : widget.onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isAdded ? Colors.grey.shade200 : Colors.transparent,
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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white)),
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
