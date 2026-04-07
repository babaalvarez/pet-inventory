import 'package:flutter/material.dart';

import '../models/app_models.dart';

const _allDashboardDatesFilter = '__all_dashboard_dates__';

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({
    super.key,
    required this.inventoryItems,
    required this.categories,
    required this.discounts,
    required this.receipts,
    this.isEmbedded = false,
  });

  final List<InventoryItem> inventoryItems;
  final List<CategoryItem> categories;
  final List<DiscountItem> discounts;
  final List<ReceiptItem> receipts;
  final bool isEmbedded;

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  late String _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    _selectedDateFilter = _defaultDashboardDateFilter();
  }

  @override
  void didUpdateWidget(covariant DashboardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final availableDates = _availableDashboardDates(widget.receipts);
    if (_selectedDateFilter != _allDashboardDatesFilter &&
        !availableDates.contains(_selectedDateFilter)) {
      _selectedDateFilter = _defaultDashboardDateFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayDate = _storageDateString(DateTime.now());
    final availableDates = _availableDashboardDates(widget.receipts);
    final filteredReceipts = _selectedDateFilter == _allDashboardDatesFilter
        ? widget.receipts
        : widget.receipts
              .where((receipt) => receipt.date == _selectedDateFilter)
              .toList();
    final salesBreakdown = _buildSalesBreakdown(filteredReceipts);
    final totalUnits = widget.inventoryItems.fold<int>(
      0,
      (sum, item) => sum + item.stock,
    );
    final totalInventoryValue = widget.inventoryItems.fold<double>(
      0,
      (sum, item) => sum + (item.stock * item.unitCost),
    );
    final filteredSales = filteredReceipts.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
    final lowStockItems = widget.inventoryItems
        .where((item) => item.stock <= item.reorderLevel)
        .toList();
    lowStockItems.sort((left, right) {
      final leftRank = left.stock == 0 ? 0 : 1;
      final rightRank = right.stock == 0 ? 0 : 1;
      if (leftRank != rightRank) {
        return leftRank.compareTo(rightRank);
      }
      return left.stock.compareTo(right.stock);
    });
    final recentReceipts = filteredReceipts.take(4).toList();
    final salesLabel = _dashboardSalesLabel(
      selectedDateFilter: _selectedDateFilter,
      todayDate: todayDate,
    );
    final salesSubtitle = _dashboardSalesSubtitle(
      selectedDateFilter: _selectedDateFilter,
      todayDate: todayDate,
      receiptCount: filteredReceipts.length,
    );
    final receiptScopeText = _dashboardReceiptScopeText(
      selectedDateFilter: _selectedDateFilter,
      todayDate: todayDate,
    );
    final recentReceiptsTitle = _dashboardRecentReceiptsTitle(
      selectedDateFilter: _selectedDateFilter,
      todayDate: todayDate,
    );
    final emptyReceiptsMessage = _dashboardRecentReceiptsEmptyMessage(
      selectedDateFilter: _selectedDateFilter,
      todayDate: todayDate,
    );

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A quick look at sales activity, inventory health, and store readiness.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter Dashboard by Date',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            key: const ValueKey('dashboard-date-filter'),
                            value: _selectedDateFilter,
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(16),
                            items: [
                              const DropdownMenuItem<String>(
                                value: _allDashboardDatesFilter,
                                child: Text('All Dates'),
                              ),
                              ...availableDates.map(
                                (date) => DropdownMenuItem<String>(
                                  value: date,
                                  child: Text(
                                    _dashboardDateDropdownLabel(
                                      value: date,
                                      todayDate: todayDate,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedDateFilter = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MetricCard(
                label: 'Products',
                value: '${widget.inventoryItems.length}',
                subtitle: '$totalUnits units on hand',
                icon: Icons.inventory_2_outlined,
              ),
              _MetricCard(
                label: 'Categories',
                value: '${widget.categories.length}',
                subtitle: '${widget.discounts.length} discounts active',
                icon: Icons.category_outlined,
              ),
              _MetricCard(
                label: salesLabel,
                value: '₱${filteredSales.toStringAsFixed(2)}',
                subtitle: salesSubtitle,
                icon: Icons.receipt_long_outlined,
              ),
              _MetricCard(
                label: "Meng's Store Sales",
                value: '₱${salesBreakdown.mengStoreTotal.toStringAsFixed(2)}',
                subtitle:
                    '${salesBreakdown.mengStoreReceiptCount} receipt(s) $receiptScopeText with Meng\'s Store items',
                icon: Icons.storefront_outlined,
              ),
              _MetricCard(
                label: 'General Receipt Sales',
                value:
                    '₱${salesBreakdown.generalReceiptTotal.toStringAsFixed(2)}',
                subtitle:
                    '${salesBreakdown.generalReceiptCount} receipt(s) $receiptScopeText with non-Meng purchases',
                icon: Icons.receipt_long_outlined,
              ),
              _MetricCard(
                label: 'Inventory Value',
                value: '₱${totalInventoryValue.toStringAsFixed(2)}',
                subtitle: '${lowStockItems.length} stock alerts',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DashboardSection(
            title: recentReceiptsTitle,
            child: recentReceipts.isEmpty
                ? _EmptyStateMessage(message: emptyReceiptsMessage)
                : Column(
                    children: recentReceipts
                        .map(
                          (receipt) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReceiptHighlightRow(receipt: receipt),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _DashboardSection(
            title: 'Stock Alerts',
            child: lowStockItems.isEmpty
                ? const _EmptyStateMessage(
                    message: 'Inventory looks healthy right now.',
                  )
                : Column(
                    children: lowStockItems
                        .take(5)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _StockAlertRow(item: item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );

    return Container(
      color: const Color(0xFFF7F7F7),
      child: widget.isEmbedded ? content : content,
    );
  }
}

String _defaultDashboardDateFilter() {
  return _storageDateString(DateTime.now());
}

List<String> _availableDashboardDates(List<ReceiptItem> receipts) {
  final todayDate = _storageDateString(DateTime.now());
  final uniqueDates = <String>{todayDate};

  for (final receipt in receipts) {
    final date = receipt.date.trim();
    if (date.isNotEmpty) {
      uniqueDates.add(date);
    }
  }

  final dates = uniqueDates.toList()
    ..sort((left, right) => right.compareTo(left));
  return dates;
}

String _storageDateString(DateTime value) {
  final dateOnly = DateTime(value.year, value.month, value.day);
  return dateOnly.toIso8601String().split('T').first;
}

String _dashboardDateDropdownLabel({
  required String value,
  required String todayDate,
}) {
  final formattedDate = _formatDashboardDateLabel(value);
  if (value == todayDate) {
    return 'Today';
  }
  return formattedDate;
}

String _dashboardSalesLabel({
  required String selectedDateFilter,
  required String todayDate,
}) {
  if (selectedDateFilter == _allDashboardDatesFilter) {
    return 'All Sales';
  }
  if (selectedDateFilter == todayDate) {
    return "Today's Sales";
  }
  return 'Filtered Sales';
}

String _dashboardSalesSubtitle({
  required String selectedDateFilter,
  required String todayDate,
  required int receiptCount,
}) {
  if (selectedDateFilter == _allDashboardDatesFilter) {
    return '$receiptCount receipts across all dates';
  }
  if (selectedDateFilter == todayDate) {
    return '$receiptCount receipts today';
  }
  return '$receiptCount receipts on ${_formatDashboardDateLabel(selectedDateFilter)}';
}

String _dashboardReceiptScopeText({
  required String selectedDateFilter,
  required String todayDate,
}) {
  if (selectedDateFilter == _allDashboardDatesFilter) {
    return 'across all dates';
  }
  if (selectedDateFilter == todayDate) {
    return 'today';
  }
  return 'on ${_formatDashboardDateLabel(selectedDateFilter)}';
}

String _dashboardRecentReceiptsTitle({
  required String selectedDateFilter,
  required String todayDate,
}) {
  if (selectedDateFilter == _allDashboardDatesFilter) {
    return 'Recent Receipts';
  }
  if (selectedDateFilter == todayDate) {
    return "Today's Receipts";
  }
  return 'Receipts for ${_formatDashboardDateLabel(selectedDateFilter)}';
}

String _dashboardRecentReceiptsEmptyMessage({
  required String selectedDateFilter,
  required String todayDate,
}) {
  if (selectedDateFilter == _allDashboardDatesFilter) {
    return 'No receipts have been recorded yet.';
  }
  if (selectedDateFilter == todayDate) {
    return 'No receipts have been recorded for today yet.';
  }
  return 'No receipts were recorded on ${_formatDashboardDateLabel(selectedDateFilter)}.';
}

String _formatDashboardDateLabel(String value) {
  try {
    final date = DateTime.parse(value);
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  } catch (_) {
    return value;
  }
}

String _monthName(int month) {
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

  if (month < 1 || month > monthNames.length) {
    return 'Unknown';
  }

  return monthNames[month - 1];
}

_DashboardSalesBreakdown _buildSalesBreakdown(List<ReceiptItem> receipts) {
  var mengStoreTotal = 0.0;
  var mengStoreReceiptCount = 0;
  var generalReceiptTotal = 0.0;
  var generalReceiptCount = 0;

  for (final receipt in receipts) {
    if (receipt.purchasedItems.isEmpty) {
      generalReceiptTotal += receipt.total;
      generalReceiptCount += 1;
      continue;
    }

    var hasMengStoreItems = false;
    var hasGeneralItems = false;

    for (final item in receipt.purchasedItems) {
      if (item.category == protectedCategoryName) {
        mengStoreTotal += item.lineTotal;
        hasMengStoreItems = true;
      } else {
        generalReceiptTotal += item.lineTotal;
        hasGeneralItems = true;
      }
    }

    if (hasMengStoreItems) {
      mengStoreReceiptCount += 1;
    }
    if (hasGeneralItems) {
      generalReceiptCount += 1;
    }
  }

  return _DashboardSalesBreakdown(
    mengStoreTotal: mengStoreTotal,
    mengStoreReceiptCount: mengStoreReceiptCount,
    generalReceiptTotal: generalReceiptTotal,
    generalReceiptCount: generalReceiptCount,
  );
}

class _DashboardSalesBreakdown {
  const _DashboardSalesBreakdown({
    required this.mengStoreTotal,
    required this.mengStoreReceiptCount,
    required this.generalReceiptTotal,
    required this.generalReceiptCount,
  });

  final double mengStoreTotal;
  final int mengStoreReceiptCount;
  final double generalReceiptTotal;
  final int generalReceiptCount;
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 18),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _ReceiptHighlightRow extends StatelessWidget {
  const _ReceiptHighlightRow({required this.receipt});

  final ReceiptItem receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.number,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${receipt.time} • ${receipt.cashier}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₱${receipt.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StockAlertRow extends StatelessWidget {
  const _StockAlertRow({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final status = item.stock == 0 ? 'Out of Stock' : 'Low Stock';
    final statusColor = item.stock == 0
        ? const Color(0xFFE53935)
        : const Color(0xFFFB8C00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.stock} left • Reorder at ${item.reorderLevel}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateMessage extends StatelessWidget {
  const _EmptyStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    );
  }
}
