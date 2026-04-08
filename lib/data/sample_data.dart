import 'package:flutter/material.dart';

import '../models/app_models.dart';

const sidebarMenuItems = [
  SidebarItemData('dashboard', 'Dashboard', Icons.dashboard_outlined),
  SidebarItemData('sales', 'Sales', Icons.shopping_basket_outlined),
  SidebarItemData(
    'receipts_group',
    'Receipts',
    Icons.receipt_long_outlined,
    children: [
      SidebarItemData(
        'combined_receipts',
        'Combined Receipt',
        Icons.library_books_outlined,
      ),
      SidebarItemData(
        'receipts',
        'General Receipt',
        Icons.receipt_long_outlined,
      ),
      SidebarItemData(
        'meng_store_receipts',
        "Meng's Store",
        Icons.storefront_outlined,
      ),
    ],
  ),
  SidebarItemData(
    'items_group',
    'Items',
    Icons.format_list_bulleted_outlined,
    children: [
      SidebarItemData('items', 'Items', Icons.inventory_2_outlined),
      SidebarItemData('categories', 'Categories', Icons.category_outlined),
      SidebarItemData('discounts', 'Discounts', Icons.sell_outlined),
    ],
  ),
  SidebarItemData(
    'inventory_group',
    'Inventory',
    Icons.inventory_2_outlined,
    children: [
      SidebarItemData('inventory', 'Inventory', Icons.inventory_2_outlined),
      SidebarItemData(
        'purchase_order',
        'Purchase Order',
        Icons.shopping_cart_checkout_outlined,
      ),
      SidebarItemData(
        'stock_adjustment',
        'Stock Adjustment',
        Icons.tune_outlined,
      ),
      SidebarItemData(
        'inventory_count',
        'Inventory Count',
        Icons.fact_check_outlined,
      ),
      SidebarItemData(
        'inventory_history',
        'Inventory History',
        Icons.history_outlined,
      ),
    ],
  ),
  SidebarItemData('settings', 'Settings', Icons.settings_outlined),
  SidebarItemData('back_office', 'Back office', Icons.bar_chart_outlined),
];

String sectionLabelFor(String sectionId) {
  for (final item in sidebarMenuItems) {
    if (item.id == sectionId) {
      return item.label;
    }
    for (final child in item.children) {
      if (child.id == sectionId) {
        return child.label;
      }
    }
  }
  return sectionId;
}

const catalogItems = [
  CatalogItem(
    name: 'Premium Dog Kibble',
    category: 'Dog Food',
    imageUrl:
        'https://images.unsplash.com/photo-1586671267731-da2cf3ceeb80?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Salmon Cat Food',
    category: 'Cat Food',
    imageUrl:
        'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Dental Chews',
    category: 'Treats',
    imageUrl:
        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Feather Teaser',
    category: 'Toys',
    imageUrl:
        'https://images.unsplash.com/photo-1511044568932-338cba0ad803?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Training Treats',
    category: 'Treats',
    imageUrl:
        'https://images.unsplash.com/photo-1583512603806-077998240c7a?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Pet Shampoo',
    category: 'Grooming',
    imageUrl:
        'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Chew Bone',
    category: 'Treats',
    imageUrl:
        'https://images.unsplash.com/photo-1560743641-3914f2c45636?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Carrier Bag',
    category: 'Accessories',
    imageUrl:
        'https://images.unsplash.com/photo-1548681528-6a5c45b66b42?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Tuna Bites',
    category: 'Treats',
    imageUrl:
        'https://images.unsplash.com/photo-1574158622682-e40e69881006?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Spring Toy Set',
    category: 'Toys',
    imageUrl:
        'https://images.unsplash.com/photo-1450778869180-41d0601e046e?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Litter Scoop',
    category: 'Litter',
    imageUrl:
        'https://images.unsplash.com/photo-1517849845537-4d257902454a?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Paw Wipes',
    category: 'Grooming',
    imageUrl:
        'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Supplements',
    category: 'Accessories',
    isActionTile: true,
    tileColor: Color(0xFF66BB6A),
    icon: Icons.open_in_new,
  ),
  CatalogItem(
    name: 'Accessories',
    category: 'Accessories',
    isActionTile: true,
    tileColor: Color(0xFFD4E52A),
    icon: Icons.open_in_new,
  ),
  CatalogItem(
    name: 'Bundle Deals',
    category: 'Dog Food',
    imageUrl:
        'https://images.unsplash.com/photo-1587300003388-59208cc962cb?auto=format&fit=crop&w=600&q=80',
  ),
  CatalogItem(
    name: 'Coupon',
    category: 'Treats',
    isActionTile: true,
    tileColor: Color(0xFFEAEAEA),
    icon: Icons.sell_outlined,
  ),
  CatalogItem(
    name: 'Loyal Customer',
    category: 'Cat Food',
    isActionTile: true,
    tileColor: Color(0xFFEAEAEA),
    icon: Icons.local_offer_outlined,
  ),
];

const cartItems = [
  CartItem(name: 'Premium Dog Kibble', quantity: 1, price: 22.00),
  CartItem(name: 'Dental Chews', quantity: 2, price: 6.50),
  CartItem(name: 'Pet Shampoo', quantity: 1, price: 12.00),
  CartItem(name: 'Feather Teaser', quantity: 1, price: 5.25),
];

const receipts = [
  ReceiptItem(
    id: 1042,
    number: 'RCPT-1042',
    date: '2026-04-05',
    time: '09:14 AM',
    items: 5,
    purchasedItems: [
      ReceiptPurchase(name: 'Premium Dog Kibble', quantity: 1, lineTotal: 22),
      ReceiptPurchase(name: 'Dental Chews', quantity: 2, lineTotal: 13),
      ReceiptPurchase(name: 'Feather Teaser', quantity: 1, lineTotal: 5.25),
      ReceiptPurchase(name: 'Paw Wipes', quantity: 1, lineTotal: 2.50),
    ],
    cashier: 'Andy',
    total: 42.75,
  ),
  ReceiptItem(
    id: 1043,
    number: 'RCPT-1043',
    date: '2026-04-05',
    time: '09:38 AM',
    items: 3,
    purchasedItems: [
      ReceiptPurchase(name: 'Training Treats', quantity: 2, lineTotal: 12),
      ReceiptPurchase(name: 'Tuna Bites', quantity: 1, lineTotal: 6.50),
    ],
    cashier: 'Mia',
    total: 18.50,
    isHighlighted: true,
  ),
  ReceiptItem(
    id: 1044,
    number: 'RCPT-1044',
    date: '2026-04-05',
    time: '10:02 AM',
    items: 8,
    purchasedItems: [
      ReceiptPurchase(name: 'Premium Dog Kibble', quantity: 2, lineTotal: 44),
      ReceiptPurchase(name: 'Dental Chews', quantity: 4, lineTotal: 13.20),
      ReceiptPurchase(name: 'Feather Teaser', quantity: 2, lineTotal: 6),
    ],
    cashier: 'Andy',
    total: 63.20,
  ),
  ReceiptItem(
    id: 1045,
    number: 'RCPT-1045',
    date: '2026-04-06',
    time: '10:27 AM',
    items: 2,
    purchasedItems: [
      ReceiptPurchase(name: 'Pet Shampoo', quantity: 1, lineTotal: 8.30),
      ReceiptPurchase(name: 'Paw Wipes', quantity: 1, lineTotal: 6.50),
    ],
    cashier: 'Noel',
    total: 14.80,
  ),
  ReceiptItem(
    id: 1046,
    number: 'RCPT-1046',
    date: '2026-04-06',
    time: '11:05 AM',
    items: 6,
    purchasedItems: [
      ReceiptPurchase(name: 'Salmon Cat Food', quantity: 2, lineTotal: 20.40),
      ReceiptPurchase(name: 'Training Treats', quantity: 2, lineTotal: 9.75),
      ReceiptPurchase(name: 'Feather Teaser', quantity: 2, lineTotal: 9.80),
    ],
    cashier: 'Mia',
    total: 39.95,
  ),
  ReceiptItem(
    id: 1047,
    number: 'RCPT-1047',
    date: '2026-04-07',
    time: '11:42 AM',
    items: 4,
    purchasedItems: [
      ReceiptPurchase(
        name: 'Premium Dog Kibble',
        quantity: 2,
        lineTotal: 41.80,
      ),
      ReceiptPurchase(name: 'Carrier Bag', quantity: 1, lineTotal: 6.75),
      ReceiptPurchase(name: 'Tuna Bites', quantity: 1, lineTotal: 3.50),
    ],
    cashier: 'Andy',
    total: 52.05,
  ),
  ReceiptItem(
    id: 1048,
    number: 'RCPT-1048',
    date: '2026-04-07',
    time: '12:16 PM',
    items: 3,
    purchasedItems: [
      ReceiptPurchase(name: 'Premium Dog Kibble', quantity: 1, lineTotal: 19),
      ReceiptPurchase(name: 'Salmon Cat Food', quantity: 1, lineTotal: 14.50),
      ReceiptPurchase(name: 'Carrier Bag', quantity: 1, lineTotal: 11.50),
    ],
    cashier: 'Noel',
    total: 45.00,
  ),
];

const initialInventoryItems = [
  InventoryItem(
    id: 1,
    name: 'Premium Dog Kibble',
    category: 'Dog Food',
    stock: 42,
    reorderLevel: 15,
    unitCost: 12.50,
  ),
  InventoryItem(
    id: 2,
    name: 'Salmon Cat Food',
    category: 'Cat Food',
    stock: 28,
    reorderLevel: 12,
    unitCost: 10.20,
  ),
  InventoryItem(
    id: 3,
    name: 'Dental Chews',
    category: 'Treats',
    stock: 14,
    reorderLevel: 16,
    unitCost: 3.40,
  ),
  InventoryItem(
    id: 4,
    name: 'Feather Teaser',
    category: 'Toys',
    stock: 9,
    reorderLevel: 8,
    unitCost: 2.80,
  ),
  InventoryItem(
    id: 5,
    name: 'Training Treats',
    category: 'Treats',
    stock: 34,
    reorderLevel: 10,
    unitCost: 4.10,
  ),
  InventoryItem(
    id: 6,
    name: 'Pet Shampoo',
    category: 'Grooming',
    stock: 11,
    reorderLevel: 10,
    unitCost: 6.75,
  ),
  InventoryItem(
    id: 7,
    name: 'Chew Bone',
    category: 'Toys',
    stock: 0,
    reorderLevel: 6,
    unitCost: 2.10,
  ),
  InventoryItem(
    id: 8,
    name: 'Carrier Bag',
    category: 'Accessories',
    stock: 7,
    reorderLevel: 5,
    unitCost: 14.00,
  ),
  InventoryItem(
    id: 9,
    name: 'Tuna Bites',
    category: 'Treats',
    stock: 18,
    reorderLevel: 8,
    unitCost: 3.90,
  ),
  InventoryItem(
    id: 10,
    name: 'Litter Scoop',
    category: 'Litter',
    stock: 23,
    reorderLevel: 10,
    unitCost: 5.25,
  ),
];

const initialCategories = [
  CategoryItem(id: 1, name: 'Dog Food', colorValue: 0xFF43A047),
  CategoryItem(id: 2, name: 'Cat Food', colorValue: 0xFF1E88E5),
  CategoryItem(id: 3, name: 'Treats', colorValue: 0xFFFFB300),
  CategoryItem(id: 4, name: 'Toys', colorValue: 0xFF8E24AA),
  CategoryItem(id: 5, name: 'Grooming', colorValue: 0xFF00897B),
  CategoryItem(id: 6, name: 'Accessories', colorValue: 0xFF6D4C41),
  CategoryItem(id: 7, name: 'Litter', colorValue: 0xFFF4511E),
  CategoryItem(
    id: 8,
    name: protectedCategoryName,
    colorValue: protectedCategoryColorValue,
    isProtected: true,
  ),
];

const initialDiscounts = [
  DiscountItem(
    id: 1,
    name: 'Loyalty Reward',
    type: DiscountType.fixedAmount,
    value: 6.50,
  ),
  DiscountItem(
    id: 2,
    name: 'Senior Citizen',
    type: DiscountType.percentage,
    value: 20,
  ),
  DiscountItem(
    id: 3,
    name: 'Weekend Grooming Promo',
    type: DiscountType.percentage,
    value: 10,
  ),
];
