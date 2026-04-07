import 'package:flutter/material.dart';

import '../models/app_models.dart';

class DiscountsPanel extends StatelessWidget {
  const DiscountsPanel({
    super.key,
    required this.discounts,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.isEmbedded = false,
  });

  final List<DiscountItem> discounts;
  final VoidCallback onAdd;
  final ValueChanged<DiscountItem> onEdit;
  final ValueChanged<DiscountItem> onDelete;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Discounts',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Discount'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            color: Colors.white,
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Value',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 108,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildBody(),
        ],
      ),
    );

    return content;
  }

  Widget _buildBody() {
    if (discounts.isEmpty) {
      final emptyState = Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EADF)),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sell_outlined, size: 42, color: Color(0xFF9E9E9E)),
              SizedBox(height: 14),
              Text(
                'No discounts yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Create percentage-based or exact-amount discounts to manage promotions here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );

      if (isEmbedded) {
        return emptyState;
      }

      return Expanded(
        child: Align(alignment: Alignment.topCenter, child: emptyState),
      );
    }

    if (isEmbedded) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: discounts.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => DiscountRow(
          discount: discounts[index],
          onEdit: () => onEdit(discounts[index]),
          onDelete: () => onDelete(discounts[index]),
        ),
      );
    }

    return Expanded(
      child: ListView.separated(
        itemCount: discounts.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => DiscountRow(
          discount: discounts[index],
          onEdit: () => onEdit(discounts[index]),
          onDelete: () => onDelete(discounts[index]),
        ),
      ),
    );
  }
}

class DiscountRow extends StatelessWidget {
  const DiscountRow({
    super.key,
    required this.discount,
    required this.onEdit,
    required this.onDelete,
  });

  final DiscountItem discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final previewSavings = discount.savingsForSubtotal(100);
    final badgeColor = discount.type == DiscountType.percentage
        ? const Color(0xFF1E88E5)
        : const Color(0xFFF57C00);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              discount.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  discount.type.label,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                discount.formattedValue,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Saves ₱${previewSavings.toStringAsFixed(2)} on ₱100',
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
          SizedBox(
            width: 108,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit discount',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Delete discount',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
