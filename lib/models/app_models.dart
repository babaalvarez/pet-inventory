import 'dart:convert';

import 'package:flutter/material.dart';

const protectedCategoryName = "Meng's Store";
const protectedCategoryColorValue = 0xFF546E7A;
const defaultReceiptStoreName = protectedCategoryName;

class CatalogItem {
  const CatalogItem({
    this.id,
    required this.name,
    required this.category,
    this.price,
    this.imageUrl,
    this.imagePath,
    this.representation = InventoryRepresentation.colorAndShape,
    this.displayColor,
    this.displayShape = InventoryDisplayShape.roundedSquare,
    this.isActionTile = false,
    this.tileColor,
    this.icon,
  });

  final int? id;
  final String name;
  final String category;
  final double? price;
  final String? imageUrl;
  final String? imagePath;
  final InventoryRepresentation representation;
  final Color? displayColor;
  final InventoryDisplayShape displayShape;
  final bool isActionTile;
  final Color? tileColor;
  final IconData? icon;
}

class CartItem {
  const CartItem({
    this.inventoryItemId,
    required this.name,
    required this.quantity,
    required this.price,
    this.representation = InventoryRepresentation.colorAndShape,
    this.displayColorValue = 0,
    this.displayShape = InventoryDisplayShape.roundedSquare,
    this.imagePath = '',
  });

  final int? inventoryItemId;
  final String name;
  final int quantity;
  final double price;
  final InventoryRepresentation representation;
  final int displayColorValue;
  final InventoryDisplayShape displayShape;
  final String imagePath;

  double get total => quantity * price;
  int get resolvedDisplayColorValue => displayColorValue == 0
      ? defaultInventoryDisplayColorValue(name)
      : displayColorValue;
  Color get displayColor => Color(resolvedDisplayColorValue);

  CartItem copyWith({
    int? inventoryItemId,
    String? name,
    int? quantity,
    double? price,
    InventoryRepresentation? representation,
    int? displayColorValue,
    InventoryDisplayShape? displayShape,
    String? imagePath,
  }) {
    return CartItem(
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      representation: representation ?? this.representation,
      displayColorValue: displayColorValue ?? this.displayColorValue,
      displayShape: displayShape ?? this.displayShape,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class ReceiptItem {
  const ReceiptItem({
    required this.id,
    required this.number,
    required this.date,
    required this.time,
    required this.items,
    this.purchasedItems = const [],
    this.storeName = defaultReceiptStoreName,
    required this.cashier,
    required this.total,
    this.isHighlighted = false,
  });

  final int id;
  final String number;
  final String date;
  final String time;
  final int items;
  final List<ReceiptPurchase> purchasedItems;
  final String storeName;
  final String cashier;
  final double total;
  final bool isHighlighted;

  factory ReceiptItem.fromMap(Map<String, Object?> map) {
    return ReceiptItem(
      id: map['id'] as int,
      number: map['number'] as String,
      date: map['date'] as String,
      time: map['time'] as String,
      items: map['items'] as int,
      purchasedItems: _decodePurchasedItems(map['purchased_items']),
      storeName: map['store_name'] as String? ?? defaultReceiptStoreName,
      cashier: map['cashier'] as String,
      total: (map['total'] as num).toDouble(),
      isHighlighted: (map['is_highlighted'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'number': number,
      'date': date,
      'time': time,
      'items': items,
      'purchased_items': jsonEncode(
        purchasedItems.map((item) => item.toMap()).toList(),
      ),
      'store_name': storeName,
      'cashier': cashier,
      'total': total,
      'is_highlighted': isHighlighted ? 1 : 0,
    };
  }

  ReceiptItem copyWith({
    int? id,
    String? number,
    String? date,
    String? time,
    int? items,
    List<ReceiptPurchase>? purchasedItems,
    String? storeName,
    String? cashier,
    double? total,
    bool? isHighlighted,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      number: number ?? this.number,
      date: date ?? this.date,
      time: time ?? this.time,
      items: items ?? this.items,
      purchasedItems: purchasedItems ?? this.purchasedItems,
      storeName: storeName ?? this.storeName,
      cashier: cashier ?? this.cashier,
      total: total ?? this.total,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  static List<ReceiptPurchase> _decodePurchasedItems(Object? value) {
    if (value is! String || value.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(value);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => ReceiptPurchase.fromMap(
            Map<String, Object?>.from(item.cast<String, Object?>()),
          ),
        )
        .toList();
  }
}

class ReceiptPurchase {
  const ReceiptPurchase({
    required this.name,
    required this.quantity,
    required this.lineTotal,
    this.category = '',
    this.representation = InventoryRepresentation.colorAndShape,
    this.displayColorValue = 0,
    this.displayShape = InventoryDisplayShape.roundedSquare,
    this.imagePath = '',
  });

  final String name;
  final int quantity;
  final double lineTotal;
  final String category;
  final InventoryRepresentation representation;
  final int displayColorValue;
  final InventoryDisplayShape displayShape;
  final String imagePath;
  int get resolvedDisplayColorValue => displayColorValue == 0
      ? defaultInventoryDisplayColorValue(name)
      : displayColorValue;
  Color get displayColor => Color(resolvedDisplayColorValue);

  factory ReceiptPurchase.fromMap(Map<String, Object?> map) {
    return ReceiptPurchase(
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      lineTotal: (map['line_total'] as num).toDouble(),
      category: map['category'] as String? ?? '',
      representation: InventoryRepresentation.fromDatabaseValue(
        map['representation'] as String?,
      ),
      displayColorValue: map['display_color_value'] as int? ?? 0,
      displayShape: InventoryDisplayShape.fromDatabaseValue(
        map['display_shape'] as String?,
      ),
      imagePath: map['image_path'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'line_total': lineTotal,
      'category': category,
      'representation': representation.databaseValue,
      'display_color_value': resolvedDisplayColorValue,
      'display_shape': displayShape.databaseValue,
      'image_path': imagePath,
    };
  }

  ReceiptPurchase copyWith({
    String? name,
    int? quantity,
    double? lineTotal,
    String? category,
    InventoryRepresentation? representation,
    int? displayColorValue,
    InventoryDisplayShape? displayShape,
    String? imagePath,
  }) {
    return ReceiptPurchase(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
      category: category ?? this.category,
      representation: representation ?? this.representation,
      displayColorValue: displayColorValue ?? this.displayColorValue,
      displayShape: displayShape ?? this.displayShape,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.reorderLevel,
    required this.unitCost,
    this.price,
    this.sku = '',
    this.representation = InventoryRepresentation.colorAndShape,
    this.displayColorValue = 0,
    this.displayShape = InventoryDisplayShape.roundedSquare,
    this.imagePath = '',
  });

  final int id;
  final String name;
  final String category;
  final int stock;
  final int reorderLevel;
  final double unitCost;
  final double? price;
  final String sku;
  final InventoryRepresentation representation;
  final int displayColorValue;
  final InventoryDisplayShape displayShape;
  final String imagePath;

  double get sellingPrice => price ?? unitCost;
  int get resolvedDisplayColorValue => displayColorValue == 0
      ? defaultInventoryDisplayColorValue(name)
      : displayColorValue;
  Color get displayColor => Color(resolvedDisplayColorValue);

  String get resolvedSku => sku.isEmpty
      ? generateInventorySku(id: id, name: name, category: category)
      : sku;

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    return InventoryItem(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      stock: map['stock'] as int,
      reorderLevel: map['reorder_level'] as int,
      unitCost: (map['unit_cost'] as num).toDouble(),
      price: ((map['price'] as num?) ?? (map['unit_cost'] as num?))?.toDouble(),
      sku: map['sku'] as String? ?? '',
      representation: InventoryRepresentation.fromDatabaseValue(
        map['representation'] as String?,
      ),
      displayColorValue: map['display_color_value'] as int? ?? 0,
      displayShape: InventoryDisplayShape.fromDatabaseValue(
        map['display_shape'] as String?,
      ),
      imagePath: map['image_path'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'stock': stock,
      'reorder_level': reorderLevel,
      'unit_cost': unitCost,
      'price': sellingPrice,
      'sku': resolvedSku,
      'representation': representation.databaseValue,
      'display_color_value': resolvedDisplayColorValue,
      'display_shape': displayShape.databaseValue,
      'image_path': imagePath,
    };
  }

  InventoryItem copyWith({
    int? id,
    String? name,
    String? category,
    int? stock,
    int? reorderLevel,
    double? unitCost,
    double? price,
    String? sku,
    InventoryRepresentation? representation,
    int? displayColorValue,
    InventoryDisplayShape? displayShape,
    String? imagePath,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      unitCost: unitCost ?? this.unitCost,
      price: price ?? this.price,
      sku: sku ?? this.sku,
      representation: representation ?? this.representation,
      displayColorValue: displayColorValue ?? this.displayColorValue,
      displayShape: displayShape ?? this.displayShape,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

enum InventoryRepresentation {
  colorAndShape,
  image;

  String get databaseValue => switch (this) {
    InventoryRepresentation.colorAndShape => 'color_shape',
    InventoryRepresentation.image => 'image',
  };

  String get label => switch (this) {
    InventoryRepresentation.colorAndShape => 'Color and Shape',
    InventoryRepresentation.image => 'Image',
  };

  static InventoryRepresentation fromDatabaseValue(String? value) {
    return switch (value) {
      'image' => InventoryRepresentation.image,
      _ => InventoryRepresentation.colorAndShape,
    };
  }
}

enum InventoryDisplayShape {
  roundedSquare,
  circle,
  diamond,
  capsule;

  String get databaseValue => switch (this) {
    InventoryDisplayShape.roundedSquare => 'rounded_square',
    InventoryDisplayShape.circle => 'circle',
    InventoryDisplayShape.diamond => 'diamond',
    InventoryDisplayShape.capsule => 'capsule',
  };

  String get label => switch (this) {
    InventoryDisplayShape.roundedSquare => 'Rounded Square',
    InventoryDisplayShape.circle => 'Circle',
    InventoryDisplayShape.diamond => 'Diamond',
    InventoryDisplayShape.capsule => 'Capsule',
  };

  static InventoryDisplayShape fromDatabaseValue(String? value) {
    return switch (value) {
      'circle' => InventoryDisplayShape.circle,
      'diamond' => InventoryDisplayShape.diamond,
      'capsule' => InventoryDisplayShape.capsule,
      _ => InventoryDisplayShape.roundedSquare,
    };
  }
}

const inventoryDisplayColorChoices = <int>[
  0xFF26A69A,
  0xFF5C6BC0,
  0xFF66BB6A,
  0xFFFF7043,
  0xFF42A5F5,
  0xFFAB47BC,
  0xFFF9A825,
  0xFF8D6E63,
];

int defaultInventoryDisplayColorValue(String seed) {
  if (seed.isEmpty) {
    return inventoryDisplayColorChoices.first;
  }
  return inventoryDisplayColorChoices[seed.length %
      inventoryDisplayColorChoices.length];
}

String generateInventorySku({
  required int id,
  required String name,
  required String category,
}) {
  final categorySegment = _inventorySkuSegment(category);
  final nameSegment = _inventorySkuSegment(name);
  final numberSegment = id > 0 ? id.toString().padLeft(4, '0') : 'NEW';
  return '$categorySegment-$nameSegment-$numberSegment';
}

String _inventorySkuSegment(String value) {
  final cleaned = value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (cleaned.isEmpty) {
    return 'GEN';
  }
  if (cleaned.length >= 3) {
    return cleaned.substring(0, 3);
  }
  return cleaned.padRight(3, 'X');
}

enum DiscountType {
  percentage,
  fixedAmount;

  String get databaseValue => switch (this) {
    DiscountType.percentage => 'percentage',
    DiscountType.fixedAmount => 'fixed_amount',
  };

  String get label => switch (this) {
    DiscountType.percentage => 'Percentage',
    DiscountType.fixedAmount => 'Exact Amount',
  };

  String get shortLabel => switch (this) {
    DiscountType.percentage => '% Off',
    DiscountType.fixedAmount => 'Amount Off',
  };

  static DiscountType fromDatabaseValue(String value) {
    return switch (value) {
      'percentage' => DiscountType.percentage,
      'fixed_amount' => DiscountType.fixedAmount,
      _ => DiscountType.fixedAmount,
    };
  }
}

class DiscountItem {
  const DiscountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  });

  final int id;
  final String name;
  final DiscountType type;
  final double value;

  factory DiscountItem.fromMap(Map<String, Object?> map) {
    return DiscountItem(
      id: map['id'] as int,
      name: map['name'] as String,
      type: DiscountType.fromDatabaseValue(map['type'] as String),
      value: (map['value'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'type': type.databaseValue, 'value': value};
  }

  DiscountItem copyWith({
    int? id,
    String? name,
    DiscountType? type,
    double? value,
  }) {
    return DiscountItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  String get formattedValue {
    if (type == DiscountType.percentage) {
      final hasDecimal = value != value.truncateToDouble();
      return '${value.toStringAsFixed(hasDecimal ? 2 : 0)}%';
    }
    return '₱${value.toStringAsFixed(2)}';
  }

  double savingsForSubtotal(double subtotal) {
    if (type == DiscountType.percentage) {
      return subtotal * (value / 100);
    }
    return value > subtotal ? subtotal : value;
  }
}

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isProtected = false,
  });

  final int id;
  final String name;
  final int colorValue;
  final bool isProtected;

  Color get color => Color(colorValue);

  factory CategoryItem.fromMap(Map<String, Object?> map) {
    return CategoryItem(
      id: map['id'] as int,
      name: map['name'] as String,
      colorValue: map['color_value'] as int,
      isProtected: (map['is_protected'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'is_protected': isProtected ? 1 : 0,
    };
  }

  CategoryItem copyWith({
    int? id,
    String? name,
    int? colorValue,
    bool? isProtected,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isProtected: isProtected ?? this.isProtected,
    );
  }
}

class SidebarItemData {
  const SidebarItemData(
    this.id,
    this.label,
    this.icon, {
    this.children = const [],
  });

  final String id;
  final String label;
  final IconData icon;
  final List<SidebarItemData> children;

  bool get hasChildren => children.isNotEmpty;

  bool matches(String selectedItem) => id == selectedItem;

  bool containsSelection(String selectedItem) {
    if (matches(selectedItem)) {
      return true;
    }
    return children.any((child) => child.containsSelection(selectedItem));
  }

  String get defaultChildId => hasChildren ? children.first.id : id;
}
