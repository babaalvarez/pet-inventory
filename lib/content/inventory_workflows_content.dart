import 'package:flutter/material.dart';

import '../models/app_models.dart';

class InventoryWorkflowPanel extends StatelessWidget {
  const InventoryWorkflowPanel({
    super.key,
    required this.workflowId,
    required this.inventoryItems,
    this.isEmbedded = false,
  });

  final String workflowId;
  final List<InventoryItem> inventoryItems;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final workflow = _definitionFor(workflowId, inventoryItems);

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
                  '${workflow.title} Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workflow.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: workflow.metrics
                .map(
                  (metric) => _WorkflowMetricCard(
                    label: metric.label,
                    value: metric.value,
                    subtitle: metric.subtitle,
                    icon: metric.icon,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          _WorkflowSection(
            title: workflow.primarySectionTitle,
            child: workflow.primaryRows.isEmpty
                ? const _WorkflowEmptyState(
                    message: 'No items need attention right now.',
                  )
                : Column(
                    children: workflow.primaryRows
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WorkflowRow(row: row),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 18),
          _WorkflowSection(
            title: workflow.secondarySectionTitle,
            child: Column(
              children: workflow.secondaryRows
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkflowRow(row: row, compact: true),
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
      child: isEmbedded ? content : content,
    );
  }
}

_InventoryWorkflowDefinition _definitionFor(
  String workflowId,
  List<InventoryItem> inventoryItems,
) {
  final sortedItems = List<InventoryItem>.from(inventoryItems)
    ..sort((left, right) => left.name.compareTo(right.name));
  final lowStockItems = sortedItems
      .where((item) => item.stock <= item.reorderLevel)
      .toList();
  final outOfStockItems = sortedItems.where((item) => item.stock == 0).toList();
  final totalUnits = inventoryItems.fold<int>(
    0,
    (sum, item) => sum + item.stock,
  );
  final inventoryValue = inventoryItems.fold<double>(
    0,
    (sum, item) => sum + (item.stock * item.unitCost),
  );
  final impactedCategories = lowStockItems.map((item) => item.category).toSet();
  final recommendedUnits = lowStockItems.fold<int>(
    0,
    (sum, item) =>
        sum +
        ((item.reorderLevel - item.stock) > 0
            ? item.reorderLevel - item.stock
            : 0),
  );

  switch (workflowId) {
    case 'purchase_order':
      return _InventoryWorkflowDefinition(
        title: 'Purchase Order',
        description:
            'Review low-stock items and prepare replenishment requests before shelves run dry.',
        metrics: [
          _WorkflowMetric(
            label: 'Reorder Items',
            value: '${lowStockItems.length}',
            subtitle: '${outOfStockItems.length} already out of stock',
            icon: Icons.warning_amber_outlined,
          ),
          _WorkflowMetric(
            label: 'Suggested Units',
            value: '$recommendedUnits',
            subtitle: 'Based on current reorder gaps',
            icon: Icons.add_shopping_cart_outlined,
          ),
          _WorkflowMetric(
            label: 'Affected Categories',
            value: '${impactedCategories.length}',
            subtitle: 'Need supplier attention',
            icon: Icons.category_outlined,
          ),
        ],
        primarySectionTitle: 'Items Needing Reorder',
        primaryRows: lowStockItems
            .map(
              (item) => _WorkflowRowData(
                title: item.name,
                subtitle:
                    '${item.category}  |  ${item.stock} on hand  |  reorder at ${item.reorderLevel}',
                trailing:
                    'Order ${item.reorderLevel > item.stock ? item.reorderLevel - item.stock : 0}',
              ),
            )
            .toList(),
        secondarySectionTitle: 'Purchase Flow',
        secondaryRows: const [
          _WorkflowRowData(
            title: 'Draft supplier request',
            subtitle: 'Group low-stock products by category or vendor.',
            trailing: 'Step 1',
          ),
          _WorkflowRowData(
            title: 'Confirm incoming quantities',
            subtitle: 'Match requested units to shelf and backroom capacity.',
            trailing: 'Step 2',
          ),
          _WorkflowRowData(
            title: 'Receive and verify delivery',
            subtitle: 'Check physical stock before posting the final update.',
            trailing: 'Step 3',
          ),
        ],
      );
    case 'stock_adjustment':
      final reviewItems = [...outOfStockItems, ...lowStockItems]
          .fold<List<InventoryItem>>(<InventoryItem>[], (items, item) {
            if (items.any((entry) => entry.id == item.id)) {
              return items;
            }
            return [...items, item];
          });
      return _InventoryWorkflowDefinition(
        title: 'Stock Adjustment',
        description:
            'Track manual corrections for damaged goods, expired stocks, returns, and count variances.',
        metrics: [
          _WorkflowMetric(
            label: 'Out of Stock',
            value: '${outOfStockItems.length}',
            subtitle: 'Need immediate review',
            icon: Icons.remove_shopping_cart_outlined,
          ),
          _WorkflowMetric(
            label: 'Low Stock',
            value: '${lowStockItems.length}',
            subtitle: 'Close to reorder level',
            icon: Icons.inventory_2_outlined,
          ),
          _WorkflowMetric(
            label: 'Inventory Value',
            value: '₱${inventoryValue.toStringAsFixed(2)}',
            subtitle: '$totalUnits units currently tracked',
            icon: Icons.payments_outlined,
          ),
        ],
        primarySectionTitle: 'Items To Review',
        primaryRows: reviewItems
            .map(
              (item) => _WorkflowRowData(
                title: item.name,
                subtitle: '${item.category}  |  ${item.stock} units on hand',
                trailing: item.stock == 0 ? 'Out of stock' : 'Low stock',
              ),
            )
            .toList(),
        secondarySectionTitle: 'Common Adjustment Reasons',
        secondaryRows: const [
          _WorkflowRowData(
            title: 'Damaged items',
            subtitle: 'Reduce stock for goods that cannot be sold.',
            trailing: 'Reason',
          ),
          _WorkflowRowData(
            title: 'Customer returns',
            subtitle: 'Add stock back only after quality checks are completed.',
            trailing: 'Reason',
          ),
          _WorkflowRowData(
            title: 'Manual corrections',
            subtitle:
                'Use when the physical count differs from the system value.',
            trailing: 'Reason',
          ),
        ],
      );
    case 'inventory_count':
      final countPriorityItems = List<InventoryItem>.from(sortedItems)
        ..sort(
          (left, right) => (right.stock * right.unitCost).compareTo(
            left.stock * left.unitCost,
          ),
        );
      return _InventoryWorkflowDefinition(
        title: 'Inventory Count',
        description:
            'Prepare cycle counts by focusing on valuable stock, critical items, and products near reorder level.',
        metrics: [
          _WorkflowMetric(
            label: 'Tracked SKUs',
            value: '${inventoryItems.length}',
            subtitle: 'Items included in count sessions',
            icon: Icons.qr_code_scanner_outlined,
          ),
          _WorkflowMetric(
            label: 'Units On Hand',
            value: '$totalUnits',
            subtitle: 'Current counted system quantity',
            icon: Icons.layers_outlined,
          ),
          _WorkflowMetric(
            label: 'Count Priorities',
            value: '${countPriorityItems.take(5).length}',
            subtitle: 'High-value items to verify first',
            icon: Icons.fact_check_outlined,
          ),
        ],
        primarySectionTitle: 'Count Priorities',
        primaryRows: countPriorityItems
            .take(5)
            .map(
              (item) => _WorkflowRowData(
                title: item.name,
                subtitle:
                    '${item.category}  |  ${item.stock} units  |  unit cost ₱${item.unitCost.toStringAsFixed(2)}',
                trailing: '₱${(item.stock * item.unitCost).toStringAsFixed(2)}',
              ),
            )
            .toList(),
        secondarySectionTitle: 'Count Checklist',
        secondaryRows: const [
          _WorkflowRowData(
            title: 'Freeze active changes',
            subtitle: 'Pause edits before starting a physical count session.',
            trailing: 'Check',
          ),
          _WorkflowRowData(
            title: 'Count shelves by zone',
            subtitle:
                'Split the floor into smaller sections for easier verification.',
            trailing: 'Check',
          ),
          _WorkflowRowData(
            title: 'Reconcile variances',
            subtitle: 'Review mismatches before posting final adjustments.',
            trailing: 'Check',
          ),
        ],
      );
    case 'inventory_history':
      final snapshotItems = List<InventoryItem>.from(sortedItems)
        ..sort((left, right) {
          final stockCompare = left.stock.compareTo(right.stock);
          if (stockCompare != 0) {
            return stockCompare;
          }
          return left.name.compareTo(right.name);
        });
      return _InventoryWorkflowDefinition(
        title: 'Inventory History',
        description:
            'Monitor a movement-ready snapshot of current inventory health while you build out detailed stock logs.',
        metrics: [
          _WorkflowMetric(
            label: 'Total Units',
            value: '$totalUnits',
            subtitle: '${inventoryItems.length} items currently tracked',
            icon: Icons.timeline_outlined,
          ),
          _WorkflowMetric(
            label: 'Inventory Value',
            value: '₱${inventoryValue.toStringAsFixed(2)}',
            subtitle: 'Based on current stock and unit cost',
            icon: Icons.payments_outlined,
          ),
          _WorkflowMetric(
            label: 'Items Below Reorder',
            value: '${lowStockItems.length}',
            subtitle: 'Need follow-up activity',
            icon: Icons.history_outlined,
          ),
        ],
        primarySectionTitle: 'Current Stock Snapshot',
        primaryRows: snapshotItems
            .take(6)
            .map(
              (item) => _WorkflowRowData(
                title: item.name,
                subtitle:
                    '${item.category}  |  reorder at ${item.reorderLevel}  |  unit cost ₱${item.unitCost.toStringAsFixed(2)}',
                trailing: item.stock == 0 ? '0 units' : '${item.stock} units',
              ),
            )
            .toList(),
        secondarySectionTitle: 'History Checkpoints',
        secondaryRows: const [
          _WorkflowRowData(
            title: 'Purchases received',
            subtitle:
                'Incoming stock should be captured here once supplier logging is added.',
            trailing: 'Future',
          ),
          _WorkflowRowData(
            title: 'Adjustments posted',
            subtitle:
                'Manual increases and decreases can roll into this audit trail next.',
            trailing: 'Future',
          ),
          _WorkflowRowData(
            title: 'Count variances',
            subtitle:
                'Cycle-count results can be surfaced as historical events in this section.',
            trailing: 'Future',
          ),
        ],
      );
    default:
      return _InventoryWorkflowDefinition(
        title: 'Inventory',
        description:
            'Track stock workflows across purchasing, adjustments, counts, and audit reviews.',
        metrics: [
          _WorkflowMetric(
            label: 'Items',
            value: '${inventoryItems.length}',
            subtitle: '$totalUnits units on hand',
            icon: Icons.inventory_2_outlined,
          ),
        ],
        primarySectionTitle: 'Items',
        primaryRows: const [],
        secondarySectionTitle: 'Guide',
        secondaryRows: const [],
      );
  }
}

class _InventoryWorkflowDefinition {
  const _InventoryWorkflowDefinition({
    required this.title,
    required this.description,
    required this.metrics,
    required this.primarySectionTitle,
    required this.primaryRows,
    required this.secondarySectionTitle,
    required this.secondaryRows,
  });

  final String title;
  final String description;
  final List<_WorkflowMetric> metrics;
  final String primarySectionTitle;
  final List<_WorkflowRowData> primaryRows;
  final String secondarySectionTitle;
  final List<_WorkflowRowData> secondaryRows;
}

class _WorkflowMetric {
  const _WorkflowMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _WorkflowRowData {
  const _WorkflowRowData({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;
}

class _WorkflowMetricCard extends StatelessWidget {
  const _WorkflowMetricCard({
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _WorkflowSection extends StatelessWidget {
  const _WorkflowSection({required this.title, required this.child});

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

class _WorkflowRow extends StatelessWidget {
  const _WorkflowRow({required this.row, this.compact = false});

  final _WorkflowRowData row;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.subtitle,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD8E6D6)),
            ),
            child: Text(
              row.trailing,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowEmptyState extends StatelessWidget {
  const _WorkflowEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.black54)),
    );
  }
}
