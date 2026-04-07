import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/app_models.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedItem,
    required this.onItemTap,
  });

  final String selectedItem;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 274,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAF6),
        border: Border(right: BorderSide(color: Color(0xFFE4EADF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Andy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _InfoChip(label: 'POS 1'),
                      const SizedBox(width: 8),
                      _InfoChip(label: 'Active'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pet Shop Management',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Text(
              'Navigation',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (final item in sidebarMenuItems)
                    SidebarMenuEntry(
                      item: item,
                      selectedItem: selectedItem,
                      onItemTap: onItemTap,
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE4EADF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'System Ready',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'v. 2.56',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarMenuEntry extends StatelessWidget {
  const SidebarMenuEntry({
    super.key,
    required this.item,
    required this.selectedItem,
    required this.onItemTap,
  });

  final SidebarItemData item;
  final String selectedItem;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = item.matches(selectedItem);
    final hasSelectedChild =
        item.hasChildren &&
        item.children.any((child) => child.containsSelection(selectedItem));
    final showExpanded = item.hasChildren && (isSelected || hasSelectedChild);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () =>
                  onItemTap(item.hasChildren ? item.defaultChildId : item.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: (isSelected || hasSelectedChild)
                      ? const Color(0xFFE8F5E9)
                      : Colors.transparent,
                  border: Border.all(
                    color: (isSelected || hasSelectedChild)
                        ? const Color(0xFFB7DFBA)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isSelected || hasSelectedChild)
                            ? const Color(0xFF43A047)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isSelected || hasSelectedChild)
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE3E8E0),
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: (isSelected || hasSelectedChild)
                            ? Colors.white
                            : const Color(0xFF5F6B63),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: (isSelected || hasSelectedChild)
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1F2937),
                          fontWeight: (isSelected || hasSelectedChild)
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (item.hasChildren)
                      Icon(
                        showExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.chevron_right,
                        color: const Color(0xFF2E7D32),
                      )
                    else if (isSelected)
                      const Icon(Icons.chevron_right, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
          ),
          if (showExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(18, 8, 8, 2),
              padding: const EdgeInsets.only(left: 18),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFCADBC9).withValues(alpha: 0.9),
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  for (final child in item.children)
                    SidebarSubmenuItem(
                      item: child,
                      isSelected: child.matches(selectedItem),
                      onTap: () => onItemTap(child.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SidebarSubmenuItem extends StatelessWidget {
  const SidebarSubmenuItem({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SidebarItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected ? const Color(0xFFDFF0DD) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF738074),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF425046),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
