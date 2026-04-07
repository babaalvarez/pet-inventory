import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'receipts_content.dart';

class CategoriesPanel extends StatelessWidget {
  const CategoriesPanel({
    super.key,
    required this.categories,
    required this.inventoryItems,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.isEmbedded = false,
  });

  final List<CategoryItem> categories;
  final List<InventoryItem> inventoryItems;
  final int? selectedCategoryId;
  final ValueChanged<CategoryItem> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<CategoryItem> onEdit;
  final ValueChanged<CategoryItem> onDelete;
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
                  'Categories',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
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
                    'Name',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Color',
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
          if (isEmbedded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => CategoryRow(
                category: categories[index],
                isSelected: selectedCategoryId == categories[index].id,
                linkedItemCount: inventoryItems
                    .where((item) => item.category == categories[index].name)
                    .length,
                onTap: () => onSelect(categories[index]),
                onEdit: () => onEdit(categories[index]),
                onDelete: () => onDelete(categories[index]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => CategoryRow(
                  category: categories[index],
                  isSelected: selectedCategoryId == categories[index].id,
                  linkedItemCount: inventoryItems
                      .where((item) => item.category == categories[index].name)
                      .length,
                  onTap: () => onSelect(categories[index]),
                  onEdit: () => onEdit(categories[index]),
                  onDelete: () => onDelete(categories[index]),
                ),
              ),
            ),
        ],
      ),
    );

    return content;
  }
}

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.isSelected,
    required this.linkedItemCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryItem category;
  final bool isSelected;
  final int linkedItemCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF1F8E9) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF2E7D32) : null,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '#${category.colorValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    ),
                  ],
                ),
              ),
              Expanded(child: Text('$linkedItemCount items')),
              SizedBox(
                width: 108,
                child: category.isProtected
                    ? const Align(
                        alignment: Alignment.centerRight,
                        child: Tooltip(
                          message: 'Protected category',
                          child: Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: Colors.black45,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Edit category',
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Delete category',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryItemsPanel extends StatelessWidget {
  const InventoryItemsPanel({
    super.key,
    required this.items,
    required this.selectedItemId,
    required this.onSelect,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.title = 'Inventory Items',
    this.addButtonLabel = 'Add Item',
    this.isManagementEnabled = true,
    this.isEmbedded = false,
  });

  final List<InventoryItem> items;
  final int? selectedItemId;
  final bool isEmbedded;
  final ValueChanged<InventoryItem> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<InventoryItem> onEdit;
  final ValueChanged<InventoryItem> onDelete;
  final String title;
  final String addButtonLabel;
  final bool isManagementEnabled;

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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isManagementEnabled) ...[
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(addButtonLabel),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: Color(0xFF43A047),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Warehouse A',
                        style: TextStyle(
                          color: Color(0xFF43A047),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Item',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Category',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'In Stock',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Low Stock',
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
                      isManagementEnabled ? 'Cost' : 'Value',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (isManagementEnabled)
                  const SizedBox(
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
          if (isEmbedded)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => InventoryRow(
                item: items[index],
                isSelected: selectedItemId == items[index].id,
                isManagementEnabled: isManagementEnabled,
                onTap: () => onSelect(items[index]),
                onEdit: () => onEdit(items[index]),
                onDelete: () => onDelete(items[index]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => InventoryRow(
                  item: items[index],
                  isSelected: selectedItemId == items[index].id,
                  isManagementEnabled: isManagementEnabled,
                  onTap: () => onSelect(items[index]),
                  onEdit: () => onEdit(items[index]),
                  onDelete: () => onDelete(items[index]),
                ),
              ),
            ),
        ],
      ),
    );

    return content;
  }
}

class InventoryRow extends StatelessWidget {
  const InventoryRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isManagementEnabled,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItem item;
  final bool isSelected;
  final bool isManagementEnabled;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stockColor = item.stock <= item.reorderLevel
        ? const Color(0xFFE53935)
        : item.stock <= item.reorderLevel + 10
        ? const Color(0xFFFB8C00)
        : const Color(0xFF43A047);

    return Material(
      color: isSelected ? const Color(0xFFF1F8E9) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF2E7D32) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.resolvedSku,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Text(item.category)),
              Expanded(
                child: Text(
                  '${item.stock}',
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: Text('${item.reorderLevel}')),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    (isManagementEnabled
                            ? item.unitCost
                            : item.stock * item.unitCost)
                        .toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (isManagementEnabled)
                SizedBox(
                  width: 108,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Edit item',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Delete item',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemSummaryPanel extends StatelessWidget {
  const ItemSummaryPanel({
    super.key,
    required this.selectedItem,
    this.isEmbedded = false,
  });

  final InventoryItem? selectedItem;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final item = selectedItem;
    final content = item == null
        ? _buildEmptyState()
        : _buildSelectedItemContent(item);

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
                'Item Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.summarize_outlined, color: Colors.grey),
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
              'Select an item from the list to view its summary.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemContent(InventoryItem item) {
    final stockValue = item.stock * item.unitCost;
    final status = item.stock == 0
        ? 'Out of Stock'
        : item.stock <= item.reorderLevel
        ? 'Low Stock'
        : 'In Stock';
    final statusColor = item.stock == 0
        ? const Color(0xFFE53935)
        : item.stock <= item.reorderLevel
        ? const Color(0xFFFB8C00)
        : const Color(0xFF43A047);
    final reorderGap = item.reorderLevel - item.stock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
          child: Row(
            children: [
              const Text(
                'Item Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.summarize_outlined, color: Colors.grey),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _summaryCard(item.name, item.category, Icons.inventory_outlined),
              const SizedBox(height: 12),
              _metricRow('Category', item.category),
              const SizedBox(height: 12),
              _metricRow('SKU', item.resolvedSku),
              const SizedBox(height: 12),
              _metricRow('Units On Hand', '${item.stock}'),
              const SizedBox(height: 12),
              _metricRow('Low Stock', '${item.reorderLevel}'),
              const SizedBox(height: 12),
              _metricRow('Price', '₱${item.sellingPrice.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _metricRow('Cost', '₱${item.unitCost.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _metricRow('Stock Value', '₱${stockValue.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _statusRow(status, statusColor),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: const Text(
            'Item Details',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: Column(
            children: [
              BreakdownRow(label: 'Item ID', value: '#${item.id}'),
              const SizedBox(height: 12),
              BreakdownRow(
                label: 'Representation',
                value: item.representation == InventoryRepresentation.image
                    ? 'Image'
                    : '${item.representation.label} • ${item.displayShape.label}',
              ),
              const SizedBox(height: 12),
              BreakdownRow(
                label: 'Restock Needed',
                value: reorderGap > 0
                    ? '$reorderGap units'
                    : 'No restock needed',
              ),
              const SizedBox(height: 12),
              BreakdownRow(
                label: 'Low Stock Threshold',
                value: '${item.reorderLevel} units',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String subtitle, IconData icon) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
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
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _statusRow(String label, Color color) {
    return Row(
      children: [
        const Text('Status', style: TextStyle(fontSize: 16)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class CategorySummaryPanel extends StatelessWidget {
  const CategorySummaryPanel({
    super.key,
    required this.categories,
    required this.inventoryItems,
    required this.selectedCategory,
    this.isEmbedded = false,
  });

  final List<CategoryItem> categories;
  final List<InventoryItem> inventoryItems;
  final CategoryItem? selectedCategory;
  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final selectedItems = selectedCategory == null
        ? <InventoryItem>[]
        : inventoryItems
              .where((item) => item.category == selectedCategory!.name)
              .toList();
    final totalUnits = selectedItems.fold<int>(
      0,
      (sum, item) => sum + item.stock,
    );
    final inventoryValue = selectedItems.fold<double>(
      0,
      (sum, item) => sum + (item.stock * item.unitCost),
    );
    final lowStockCount = selectedItems
        .where((item) => item.stock <= item.reorderLevel)
        .length;
    final averageUnitCost = selectedItems.isEmpty
        ? 0.0
        : selectedItems.fold<double>(0, (sum, item) => sum + item.unitCost) /
              selectedItems.length;
    final colorHex = selectedCategory == null
        ? '--'
        : '#${selectedCategory!.colorValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 18, 14),
          child: Row(
            children: [
              const Text(
                'Category Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.category_outlined, color: Colors.grey),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _summaryCard(
                selectedCategory?.name ?? 'No Category Selected',
                '${selectedItems.length}',
                Icons.inventory_2_outlined,
                accentColor: selectedCategory?.color,
              ),
              const SizedBox(height: 12),
              _metricRow('Items Listed', '${selectedItems.length}'),
              const SizedBox(height: 12),
              _metricRow('Units on Hand', '$totalUnits'),
              const SizedBox(height: 12),
              _metricRow(
                'Inventory Value',
                '₱${inventoryValue.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _metricRow('Low Stock Items', '$lowStockCount'),
              const SizedBox(height: 12),
              _metricRow(
                'Average Unit Cost',
                '₱${averageUnitCost.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: const Text(
            'Category Details',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: _buildDetailsSection(selectedItems, colorHex),
        ),
      ],
    );

    return Container(
      color: Colors.white,
      child: isEmbedded ? content : SingleChildScrollView(child: content),
    );
  }

  Widget _buildDetailsSection(
    List<InventoryItem> selectedItems,
    String colorHex,
  ) {
    if (selectedCategory == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE4EADF)),
        ),
        child: const Text(
          'Select a category from the list to view its summary.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EADF)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: selectedCategory!.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedCategory!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _metricRow('Assigned Items', '${selectedItems.length}'),
              const SizedBox(height: 10),
              _metricRow('Color', colorHex),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Items In This Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (selectedItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4EADF)),
            ),
            child: const Text(
              'No items currently assigned to this category.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ...selectedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BreakdownRow(
                label: item.name,
                value:
                    '${item.stock} pcs  |  ₱${(item.stock * item.unitCost).toStringAsFixed(2)}',
              ),
            ),
          ),
      ],
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon, {
    Color? accentColor,
  }) {
    final iconColor = accentColor ?? const Color(0xFF43A047);
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
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                value,
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
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
