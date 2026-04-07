import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/item_visual.dart';

class ProductPanel extends StatelessWidget {
  const ProductPanel({
    super.key,
    required this.items,
    required this.onItemTap,
    this.activeCategoryName,
    this.isEmbedded = false,
  });

  final List<CatalogItem> items;
  final ValueChanged<CatalogItem> onItemTap;
  final String? activeCategoryName;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3E8E0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 44,
                color: Color(0xFF9E9E9E),
              ),
              const SizedBox(height: 14),
              Text(
                activeCategoryName == null
                    ? 'No items available.'
                    : 'No items found for $activeCategoryName yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add products for this category to see them in the sales grid.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        itemCount: items.length,
        shrinkWrap: isEmbedded,
        physics: isEmbedded
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isEmbedded ? 3 : 5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: isEmbedded ? 1.0 : 1.02,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          if (item.isActionTile) {
            return ActionTile(item: item);
          }
          return ProductTile(item: item, onTap: () => onItemTap(item));
        },
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = item.displayColor ?? _accentForName(item.name);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _TileVisual(item: item, accent: accent),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  color: Colors.black45,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.price != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '₱${item.price!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentForName(String name) {
    const palette = [
      Color(0xFF26A69A),
      Color(0xFF5C6BC0),
      Color(0xFF66BB6A),
      Color(0xFFFF7043),
      Color(0xFF42A5F5),
      Color(0xFFAB47BC),
    ];
    return palette[name.length % palette.length];
  }
}

class _TileVisual extends StatelessWidget {
  const _TileVisual({required this.item, required this.accent});

  final CatalogItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('product-visual-${item.id ?? item.name}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.16),
            accent.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 54),
        child: Center(
          child: ItemVisual(
            name: item.name,
            representation: item.representation,
            displayColorValue:
                item.displayColor?.toARGB32() ?? accent.toARGB32(),
            displayShape: item.displayShape,
            imagePath: item.imagePath ?? '',
            imageUrl: item.imageUrl,
            size: 108,
            borderRadius: 24,
          ),
        ),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.item});

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.tileColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(item.icon, size: 22, color: Colors.black54),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketPanel extends StatelessWidget {
  const TicketPanel({
    super.key,
    required this.cart,
    required this.onClear,
    required this.onRemoveItem,
    required this.onCharge,
    this.isEmbedded = false,
  });

  final List<CartItem> cart;
  final VoidCallback onClear;
  final ValueChanged<CartItem> onRemoveItem;
  final Future<String?> Function(List<CartItem> cart) onCharge;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.fold<double>(0, (sum, item) => sum + item.total);
    const appliedDiscount = 0.0;
    final total = subtotal - appliedDiscount;

    final content = Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
            child: Row(
              children: [
                const Text(
                  'Ticket',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                const Icon(Icons.person_add_alt_1, color: Colors.grey),
                const SizedBox(width: 14),
                const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              children: const [
                Text('Walk-in', style: TextStyle(fontSize: 17)),
                Spacer(),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),
          if (cart.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4EADF)),
                ),
                child: const Text(
                  'Tap an item in Sales to add it to this ticket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else if (isEmbedded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
              itemBuilder: (context, index) {
                final item = cart[index];
                return _ticketItemRow(item);
              },
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemCount: cart.length,
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return _ticketItemRow(item);
                },
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemCount: cart.length,
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
            child: Column(
              children: [
                _summaryRow('Discounts', appliedDiscount),
                const SizedBox(height: 24),
                _summaryRow('Total', total, isBold: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: cart.isEmpty ? null : onClear,
                    child: const Text('CLEAR'),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7CB342),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: cart.isEmpty
                        ? null
                        : () async {
                            final result = await showDialog<_ChargeResult>(
                              context: context,
                              builder: (_) => _ChargeDialog(total: total),
                            );
                            if (!context.mounted || result == null) {
                              return;
                            }

                            final errorMessage = await onCharge(cart);
                            if (!context.mounted) {
                              return;
                            }

                            if (errorMessage != null) {
                              await showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Charge Failed'),
                                  content: Text(errorMessage),
                                  actions: [
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            await showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Payment Successful'),
                                content: const Text(
                                  'The payment has been processed successfully.',
                                ),
                                actions: [
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: const Text('CHARGE'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return content;
  }

  Widget _ticketItemRow(CartItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ItemVisual(
          name: item.name,
          representation: item.representation,
          displayColorValue: item.displayColorValue,
          displayShape: item.displayShape,
          imagePath: item.imagePath,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Qty ${item.quantity}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '₱${item.total.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Remove item',
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          onPressed: () => onRemoveItem(item),
          icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    final style = TextStyle(
      fontSize: 16,
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value.toStringAsFixed(2), style: style),
      ],
    );
  }
}

class _ChargeResult {
  const _ChargeResult({required this.total, required this.change});

  final double total;
  final double change;
}

class _ChargeDialog extends StatefulWidget {
  const _ChargeDialog({required this.total});

  final double total;

  @override
  State<_ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<_ChargeDialog> {
  late final TextEditingController _amountReceivedController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _amountReceivedController = TextEditingController();
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    super.dispose();
  }

  Future<void> _charge() async {
    final amountReceived = double.tryParse(
      _amountReceivedController.text.trim(),
    );

    if (amountReceived == null || amountReceived <= 0) {
      setState(() {
        _errorText = 'Enter a valid amount received.';
      });
      return;
    }

    if (amountReceived < widget.total) {
      setState(() {
        _errorText = 'Amount received is less than the total due.';
      });
      return;
    }

    final change = amountReceived - widget.total;
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Do you want to proceed with this payment?'),
              const SizedBox(height: 16),
              _confirmationRow('Total Amount', widget.total),
              const SizedBox(height: 12),
              _confirmationRow('Change', change),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop(_ChargeResult(total: widget.total, change: change));
  }

  @override
  Widget build(BuildContext context) {
    final amountReceived =
        double.tryParse(_amountReceivedController.text.trim()) ?? 0.0;
    final change = amountReceived - widget.total;

    return AlertDialog(
      title: const Text('Charge Payment'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Amount to be Paid',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountReceivedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount Received',
                hintText: 'Enter amount received',
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                } else {
                  setState(() {});
                }
              },
              onSubmitted: (_) => _charge(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Change', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(
                  '₱${(change > 0 ? change : 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _charge, child: const Text('Charge')),
      ],
    );
  }

  Widget _confirmationRow(String label, double value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Text(
          '₱${value.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class BottomTabs extends StatefulWidget {
  const BottomTabs({
    super.key,
    required this.categories,
    this.selectedCategoryId,
    required this.onAllTap,
    required this.onCategoryTap,
  });

  final List<CategoryItem> categories;
  final int? selectedCategoryId;
  final VoidCallback onAllTap;
  final ValueChanged<CategoryItem> onCategoryTap;

  @override
  State<BottomTabs> createState() => _BottomTabsState();
}

class _BottomTabsState extends State<BottomTabs> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightedId = widget.selectedCategoryId;
    final orderedCategories = _orderedCategories(widget.categories);

    return Container(
      height: 74,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: orderedCategories.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _BottomTabChip(
                        label: 'ALL',
                        accentColor: const Color(0xFF43A047),
                        isSelected: highlightedId == null,
                        onTap: widget.onAllTap,
                      );
                    }

                    final category = orderedCategories[index - 1];
                    return _BottomTabChip(
                      label: category.name.toUpperCase(),
                      accentColor: category.color,
                      isSelected: category.id == highlightedId,
                      onTap: () => widget.onCategoryTap(category),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.grid_view, color: Colors.grey),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  List<CategoryItem> _orderedCategories(List<CategoryItem> categories) {
    final mengStoreCategories = categories
        .where((category) => category.name == protectedCategoryName)
        .toList();
    final otherCategories = categories
        .where((category) => category.name != protectedCategoryName)
        .toList();
    return [...mengStoreCategories, ...otherCategories];
  }
}

class _BottomTabChip extends StatelessWidget {
  const _BottomTabChip({
    required this.label,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE8F5E9)
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? accentColor : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
