import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_models.dart';
import 'sample_data.dart';

class AppDataSnapshot {
  const AppDataSnapshot({
    required this.categories,
    required this.inventoryItems,
    required this.discounts,
    required this.receipts,
  });

  final List<CategoryItem> categories;
  final List<InventoryItem> inventoryItems;
  final List<DiscountItem> discounts;
  final List<ReceiptItem> receipts;
}

abstract class AppDataStore {
  Future<AppDataSnapshot> loadSnapshot();
  Future<void> insertInventoryItem(InventoryItem item);
  Future<void> updateInventoryItem(InventoryItem item);
  Future<void> deleteInventoryItem(int id);
  Future<void> insertDiscount(DiscountItem discount);
  Future<void> updateDiscount(DiscountItem discount);
  Future<void> deleteDiscount(int id);
  Future<void> insertCategory(CategoryItem category);
  Future<void> updateCategory(
    CategoryItem category, {
    required String previousName,
  });
  Future<void> deleteCategory(int id);
  Future<void> completeCharge({
    required List<InventoryItem> updatedItems,
    required ReceiptItem receipt,
  });
}

class LocalDatabase implements AppDataStore {
  LocalDatabase._();

  static final LocalDatabase instance = LocalDatabase._();

  static const _databaseName = 'petsupplies_inventory.db';
  static const _databaseVersion = 9;
  static const _categoriesTable = 'categories';
  static const _inventoryTable = 'inventory_items';
  static const _discountsTable = 'discounts';
  static const _receiptsTable = 'receipts';

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final path = p.join(await getDatabasesPath(), _databaseName);
    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createCategoriesTable(db);
        await _createInventoryTable(db);
        await _createDiscountsTable(db);
        await _createReceiptsTable(db);
        await _seedDefaults(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createDiscountsTable(db);
          await _seedDiscountDefaults(db);
        }
        if (oldVersion < 3) {
          await _createReceiptsTable(db);
          await _seedReceiptDefaults(db);
        }
        if (oldVersion >= 3 && oldVersion < 4) {
          await db.execute('''
            ALTER TABLE $_receiptsTable
            ADD COLUMN purchased_items TEXT NOT NULL DEFAULT '[]'
            ''');
          await _seedReceiptPurchaseDefaults(db);
        }
        if (oldVersion >= 3 && oldVersion < 5) {
          await db.execute('''
            ALTER TABLE $_receiptsTable
            ADD COLUMN date TEXT NOT NULL DEFAULT ''
            ''');
          await _seedReceiptDateDefaults(db);
        }
        if (oldVersion < 6) {
          await db.execute('''
            ALTER TABLE $_categoriesTable
            ADD COLUMN is_protected INTEGER NOT NULL DEFAULT 0
            ''');
          await _seedProtectedCategoryIfMissing(db);
        }
        if (oldVersion >= 3 && oldVersion < 7) {
          await db.execute('''
            ALTER TABLE $_receiptsTable
            ADD COLUMN store_name TEXT NOT NULL DEFAULT 'Meng''s Store'
            ''');
          await _seedReceiptStoreDefaults(db);
        }
        if (oldVersion < 8) {
          await db.execute('''
            ALTER TABLE $_inventoryTable
            ADD COLUMN price REAL NOT NULL DEFAULT 0
            ''');
          await db.execute('''
            ALTER TABLE $_inventoryTable
            ADD COLUMN sku TEXT NOT NULL DEFAULT ''
            ''');
          await db.execute('''
            ALTER TABLE $_inventoryTable
            ADD COLUMN representation TEXT NOT NULL DEFAULT 'color_shape'
            ''');
          await _seedInventoryItemDefaults(db);
        }
        if (oldVersion < 9) {
          await db.execute('''
            ALTER TABLE $_inventoryTable
            ADD COLUMN display_color_value INTEGER NOT NULL DEFAULT 0
            ''');
          await db.execute('''
            ALTER TABLE $_inventoryTable
            ADD COLUMN display_shape TEXT NOT NULL DEFAULT 'rounded_square'
            ''');
          await db.execute('''
            ALTER TABLE $_inventoryTable
            ADD COLUMN image_path TEXT NOT NULL DEFAULT ''
            ''');
          await _seedInventoryDisplayDefaults(db);
        }
      },
    );

    _database = db;
    return db;
  }

  @override
  Future<AppDataSnapshot> loadSnapshot() async {
    final db = await database;
    final categories = await db.query(_categoriesTable, orderBy: 'id ASC');
    final inventoryItems = await db.query(_inventoryTable, orderBy: 'id ASC');
    final discounts = await db.query(_discountsTable, orderBy: 'id ASC');
    final receipts = await db.query(_receiptsTable, orderBy: 'id DESC');

    return AppDataSnapshot(
      categories: categories.map(CategoryItem.fromMap).toList(),
      inventoryItems: inventoryItems.map(InventoryItem.fromMap).toList(),
      discounts: discounts.map(DiscountItem.fromMap).toList(),
      receipts: receipts.map(ReceiptItem.fromMap).toList(),
    );
  }

  @override
  Future<void> insertInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.insert(
      _inventoryTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    await db.update(
      _inventoryTable,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> deleteInventoryItem(int id) async {
    final db = await database;
    await db.delete(_inventoryTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> insertDiscount(DiscountItem discount) async {
    final db = await database;
    await db.insert(
      _discountsTable,
      discount.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateDiscount(DiscountItem discount) async {
    final db = await database;
    await db.update(
      _discountsTable,
      discount.toMap(),
      where: 'id = ?',
      whereArgs: [discount.id],
    );
  }

  @override
  Future<void> deleteDiscount(int id) async {
    final db = await database;
    await db.delete(_discountsTable, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> insertCategory(CategoryItem category) async {
    final db = await database;
    await db.insert(
      _categoriesTable,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCategory(
    CategoryItem category, {
    required String previousName,
  }) async {
    if (category.isProtected) {
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _categoriesTable,
        category.toMap(),
        where: 'id = ? AND is_protected = 0',
        whereArgs: [category.id],
      );

      if (previousName != category.name) {
        await txn.update(
          _inventoryTable,
          {'category': category.name},
          where: 'category = ?',
          whereArgs: [previousName],
        );
      }
    });
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete(
      _categoriesTable,
      where: 'id = ? AND is_protected = 0',
      whereArgs: [id],
    );
  }

  @override
  Future<void> completeCharge({
    required List<InventoryItem> updatedItems,
    required ReceiptItem receipt,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final item in updatedItems) {
        await txn.update(
          _inventoryTable,
          item.toMap(),
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }

      await txn.update(_receiptsTable, {'is_highlighted': 0});
      await txn.insert(
        _receiptsTable,
        receipt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> resetForTesting() async {
    final path = p.join(await getDatabasesPath(), _databaseName);
    await close();
    await deleteDatabase(path);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _seedDefaults(Database db) async {
    final batch = db.batch();
    for (final category in initialCategories) {
      batch.insert(
        _categoriesTable,
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final item in initialInventoryItems) {
      batch.insert(
        _inventoryTable,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final discount in initialDiscounts) {
      batch.insert(
        _discountsTable,
        discount.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final receipt in receipts) {
      batch.insert(
        _receiptsTable,
        receipt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    await _seedProtectedCategoryIfMissing(db);
  }

  Future<void> _seedDiscountDefaults(Database db) async {
    final existingDiscounts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_discountsTable'),
    );
    if ((existingDiscounts ?? 0) > 0) {
      return;
    }

    final batch = db.batch();
    for (final discount in initialDiscounts) {
      batch.insert(
        _discountsTable,
        discount.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedReceiptDefaults(Database db) async {
    final existingReceipts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_receiptsTable'),
    );
    if ((existingReceipts ?? 0) > 0) {
      return;
    }

    final batch = db.batch();
    for (final receipt in receipts) {
      batch.insert(
        _receiptsTable,
        receipt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedReceiptPurchaseDefaults(Database db) async {
    final batch = db.batch();
    for (final receipt in receipts) {
      batch.update(
        _receiptsTable,
        {'purchased_items': receipt.toMap()['purchased_items']},
        where: 'id = ? AND purchased_items = ?',
        whereArgs: [receipt.id, '[]'],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedReceiptDateDefaults(Database db) async {
    final today = _storageDateString(DateTime.now());
    await db.update(
      _receiptsTable,
      {'date': today},
      where: 'date = ?',
      whereArgs: [''],
    );

    final batch = db.batch();
    for (final receipt in receipts) {
      batch.update(
        _receiptsTable,
        {'date': receipt.date},
        where: 'id = ?',
        whereArgs: [receipt.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedReceiptStoreDefaults(Database db) async {
    await db.update(
      _receiptsTable,
      {'store_name': defaultReceiptStoreName},
      where: 'store_name = ?',
      whereArgs: [''],
    );

    final batch = db.batch();
    for (final receipt in receipts) {
      batch.update(
        _receiptsTable,
        {'store_name': receipt.storeName},
        where: 'id = ?',
        whereArgs: [receipt.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedInventoryItemDefaults(Database db) async {
    final items = await db.query(_inventoryTable);
    final batch = db.batch();

    for (final item in items) {
      final id = item['id'] as int;
      final name = item['name'] as String? ?? '';
      final category = item['category'] as String? ?? '';
      final unitCost = (item['unit_cost'] as num?)?.toDouble() ?? 0;
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final sku = item['sku'] as String? ?? '';
      final representation = item['representation'] as String? ?? '';

      batch.update(
        _inventoryTable,
        {
          'price': price > 0 ? price : unitCost,
          'sku': sku.isEmpty
              ? generateInventorySku(id: id, name: name, category: category)
              : sku,
          'representation': representation.isEmpty
              ? InventoryRepresentation.colorAndShape.databaseValue
              : representation,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> _seedInventoryDisplayDefaults(Database db) async {
    final items = await db.query(_inventoryTable);
    final batch = db.batch();

    for (final item in items) {
      final id = item['id'] as int;
      final name = item['name'] as String? ?? '';
      final displayColorValue = item['display_color_value'] as int? ?? 0;
      final displayShape = item['display_shape'] as String? ?? '';
      final imagePath = item['image_path'] as String? ?? '';

      batch.update(
        _inventoryTable,
        {
          'display_color_value': displayColorValue == 0
              ? defaultInventoryDisplayColorValue(name)
              : displayColorValue,
          'display_shape': displayShape.isEmpty
              ? InventoryDisplayShape.roundedSquare.databaseValue
              : displayShape,
          'image_path': imagePath,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  String _storageDateString(DateTime value) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    return dateOnly.toIso8601String().split('T').first;
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_categoriesTable(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_protected INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _seedProtectedCategoryIfMissing(Database db) async {
    final existing = await db.query(
      _categoriesTable,
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [protectedCategoryName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        _categoriesTable,
        {'is_protected': 1},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return;
    }

    final maxId = Sqflite.firstIntValue(
      await db.rawQuery('SELECT MAX(id) FROM $_categoriesTable'),
    );
    final protectedCategory = CategoryItem(
      id: (maxId ?? 0) + 1,
      name: protectedCategoryName,
      colorValue: protectedCategoryColorValue,
      isProtected: true,
    );

    await db.insert(
      _categoriesTable,
      protectedCategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _createInventoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_inventoryTable(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        stock INTEGER NOT NULL,
        reorder_level INTEGER NOT NULL,
        unit_cost REAL NOT NULL,
        price REAL NOT NULL,
        sku TEXT NOT NULL,
        representation TEXT NOT NULL DEFAULT 'color_shape',
        display_color_value INTEGER NOT NULL,
        display_shape TEXT NOT NULL DEFAULT 'rounded_square',
        image_path TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  Future<void> _createDiscountsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_discountsTable(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL
      )
    ''');
  }

  Future<void> _createReceiptsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_receiptsTable(
        id INTEGER PRIMARY KEY,
        number TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        items INTEGER NOT NULL,
        purchased_items TEXT NOT NULL DEFAULT '[]',
        store_name TEXT NOT NULL DEFAULT 'Meng''s Store',
        cashier TEXT NOT NULL,
        total REAL NOT NULL,
        is_highlighted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
}
