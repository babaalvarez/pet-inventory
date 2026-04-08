import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../widgets/item_visual.dart';

class ReceiptsPanel extends StatelessWidget {
  const ReceiptsPanel({
    super.key,
    required this.receipts,
    required this.availableDates,
    required this.selectedDateFilter,
    required this.onDateFilterChanged,
    required this.selectedReceiptId,
    required this.onSelect,
    this.isEmbedded = false,
    this.title = 'Recent Receipts',
    this.description,
    this.showTotalSalesSummary = false,
  });

  final List<ReceiptItem> receipts;
  final List<String> availableDates;
  final String? selectedDateFilter;
  final ValueChanged<String?> onDateFilterChanged;
  final int? selectedReceiptId;
  final ValueChanged<ReceiptItem> onSelect;
  final bool isEmbedded;
  final String title;
  final String? description;
  final bool showTotalSalesSummary;

  @override
  Widget build(BuildContext context) {
    final totalSales = receipts.fold<double>(
      0,
      (sum, receipt) => sum + receipt.total,
    );
    final content = Container(
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (description != null) ...[
                  Text(
                    description!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String?>(
                  initialValue: selectedDateFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by Date',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4EADF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4EADF)),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Dates'),
                    ),
                    ...availableDates.map(
                      (date) => DropdownMenuItem<String?>(
                        value: date,
                        child: Text(_formatReceiptDateLabel(date)),
                      ),
                    ),
                  ],
                  onChanged: onDateFilterChanged,
                ),
                if (showTotalSalesSummary) ...[
                  const SizedBox(height: 14),
                  _ReceiptMetricChip(
                    label: 'Total Sales',
                    value: '₱${totalSales.toStringAsFixed(2)}',
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            color: Colors.white,
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Receipt',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Time',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Items',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Cashier',
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
                      'Total',
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
          if (receipts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4EADF)),
                ),
                child: Text(
                  selectedDateFilter == null
                      ? 'Successful charges will appear here as receipts.'
                      : 'No receipts found for ${_formatReceiptDateLabel(selectedDateFilter!)}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else if (isEmbedded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(0),
              itemCount: receipts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => ReceiptRow(
                receipt: receipts[index],
                isSelected: selectedReceiptId == receipts[index].id,
                onTap: () => onSelect(receipts[index]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(0),
                itemCount: receipts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => ReceiptRow(
                  receipt: receipts[index],
                  isSelected: selectedReceiptId == receipts[index].id,
                  onTap: () => onSelect(receipts[index]),
                ),
              ),
            ),
        ],
      ),
    );

    return content;
  }
}

class MengStoreReceiptsPanel extends StatelessWidget {
  const MengStoreReceiptsPanel({
    super.key,
    required this.receipts,
    required this.availableDates,
    required this.selectedDateFilter,
    required this.onDateFilterChanged,
    required this.selectedReceiptId,
    required this.onSelect,
    this.isEmbedded = false,
  });

  final List<ReceiptItem> receipts;
  final List<String> availableDates;
  final String? selectedDateFilter;
  final ValueChanged<String?> onDateFilterChanged;
  final int? selectedReceiptId;
  final ValueChanged<ReceiptItem> onSelect;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final entries = _mengStoreReceiptEntries(receipts);
    final filteredEntries = entries;
    final totalQuantity = filteredEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.quantity,
    );
    final totalSales = filteredEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.lineTotal,
    );

    final content = Container(
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Meng's Store Receipt Table",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Shows purchased items recorded under the Meng's Store category.",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedDateFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by Date',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4EADF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4EADF)),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Dates'),
                    ),
                    ...availableDates.map(
                      (date) => DropdownMenuItem<String?>(
                        value: date,
                        child: Text(_formatReceiptDateLabel(date)),
                      ),
                    ),
                  ],
                  onChanged: onDateFilterChanged,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MengStoreMetricChip(
                      label: 'Lines',
                      value: '${filteredEntries.length}',
                    ),
                    _MengStoreMetricChip(
                      label: 'Units Sold',
                      value: '$totalQuantity',
                    ),
                    _MengStoreMetricChip(
                      label: 'Sales',
                      value: '₱${totalSales.toStringAsFixed(2)}',
                    ),
                  ],
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
                  flex: 2,
                  child: Text(
                    'Receipt',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Cashier',
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
                      'Line Total',
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
          if (filteredEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4EADF)),
                ),
                child: Text(
                  selectedDateFilter == null
                      ? "No purchased items have been recorded yet for Meng's Store."
                      : "No Meng's Store purchases found for ${_formatReceiptDateLabel(selectedDateFilter!)}.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else if (isEmbedded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: filteredEntries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _MengStoreReceiptRow(
                entry: filteredEntries[index],
                isSelected:
                    selectedReceiptId == filteredEntries[index].receiptId,
                onTap: () {
                  final receipt = receipts.cast<ReceiptItem?>().firstWhere(
                    (item) => item?.id == filteredEntries[index].receiptId,
                    orElse: () => null,
                  );
                  if (receipt != null) {
                    onSelect(receipt);
                  }
                },
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: filteredEntries.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _MengStoreReceiptRow(
                  entry: filteredEntries[index],
                  isSelected:
                      selectedReceiptId == filteredEntries[index].receiptId,
                  onTap: () {
                    final receipt = receipts.cast<ReceiptItem?>().firstWhere(
                      (item) => item?.id == filteredEntries[index].receiptId,
                      orElse: () => null,
                    );
                    if (receipt != null) {
                      onSelect(receipt);
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );

    return content;
  }
}

class ReceiptRow extends StatelessWidget {
  const ReceiptRow({
    super.key,
    required this.receipt,
    required this.isSelected,
    required this.onTap,
  });

  final ReceiptItem receipt;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isSelected
        ? const Color(0xFFC8E6C9)
        : receipt.isHighlighted
        ? const Color(0xFFF1F8E9)
        : Colors.white;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  receipt.number,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF1B5E20) : null,
                  ),
                ),
              ),
              Expanded(child: Text(receipt.time)),
              Expanded(child: Text('${receipt.items} items')),
              Expanded(child: Text(receipt.cashier)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    receipt.total.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptSummaryPanel extends StatelessWidget {
  const ReceiptSummaryPanel({
    super.key,
    required this.selectedReceipt,
    this.isEmbedded = false,
  });

  final ReceiptItem? selectedReceipt;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final receipt = selectedReceipt;
    final content = receipt == null
        ? _buildEmptyState()
        : _buildSelectedReceiptContent(receipt);

    return Container(
      color: Colors.white,
      child: isEmbedded ? content : SingleChildScrollView(child: content),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
          child: Row(
            children: [
              const Text(
                'Receipt Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.receipt_long_outlined, color: Colors.grey),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EADF)),
            ),
            child: const Text(
              'Select a receipt to view its details.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedReceiptContent(ReceiptItem receipt) {
    final itemLabel = receipt.items == 1 ? 'item' : 'items';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
          child: Row(
            children: [
              const Text(
                'Receipt Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.receipt_long_outlined, color: Colors.grey),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _summaryCard(
                receipt.number,
                receipt.total,
                Icons.payments_outlined,
              ),
              const SizedBox(height: 12),
              _metricRow(
                'When',
                '${_formatReceiptDateLabel(receipt.date)} • ${receipt.time}',
              ),
              const SizedBox(height: 12),
              _metricRow('Cashier', receipt.cashier),
              const SizedBox(height: 12),
              _metricRow('Store', receipt.storeName),
              const SizedBox(height: 12),
              _metricRow('Items', '${receipt.items} $itemLabel'),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: const Text(
            'Purchased Items',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: receipt.purchasedItems.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4EADF)),
                  ),
                  child: const Text(
                    'This receipt does not have saved item details.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < receipt.purchasedItems.length;
                      index++
                    ) ...[
                      _purchasedItemRow(receipt.purchasedItems[index]),
                      if (index != receipt.purchasedItems.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _purchasedItemRow(ReceiptPurchase item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Row(
        children: [
          ItemVisual(
            name: item.name,
            representation: item.representation,
            displayColorValue: item.displayColorValue,
            displayShape: item.displayShape,
            imagePath: item.imagePath,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
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
            '₱${item.lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF43A047),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MengStoreReceiptEntry {
  const _MengStoreReceiptEntry({
    required this.receiptId,
    required this.receiptNumber,
    required this.date,
    required this.itemName,
    required this.quantity,
    required this.cashier,
    required this.lineTotal,
  });

  final int receiptId;
  final String receiptNumber;
  final String date;
  final String itemName;
  final int quantity;
  final String cashier;
  final double lineTotal;
}

List<_MengStoreReceiptEntry> _mengStoreReceiptEntries(
  List<ReceiptItem> receipts,
) {
  final entries = <_MengStoreReceiptEntry>[];

  for (final receipt in receipts) {
    for (final item in receipt.purchasedItems) {
      if (item.category != protectedCategoryName) {
        continue;
      }

      entries.add(
        _MengStoreReceiptEntry(
          receiptId: receipt.id,
          receiptNumber: receipt.number,
          date: receipt.date,
          itemName: item.name,
          quantity: item.quantity,
          cashier: receipt.cashier,
          lineTotal: item.lineTotal,
        ),
      );
    }
  }

  return entries;
}

class _MengStoreReceiptRow extends StatelessWidget {
  const _MengStoreReceiptRow({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  final _MengStoreReceiptEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFC8E6C9) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.receiptNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF1B5E20) : null,
                  ),
                ),
              ),
              Expanded(child: Text(_formatReceiptDateLabel(entry.date))),
              Expanded(
                flex: 2,
                child: Text(
                  entry.itemName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(child: Text('${entry.quantity}')),
              Expanded(child: Text(entry.cashier)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '₱${entry.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MengStoreMetricChip extends StatelessWidget {
  const _MengStoreMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ReceiptMetricChip extends StatelessWidget {
  const _ReceiptMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class BreakdownRow extends StatelessWidget {
  const BreakdownRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

String _formatReceiptDateLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${monthNames[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}
