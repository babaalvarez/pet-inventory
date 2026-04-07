import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:petsupplies_inventory/data/local_database.dart';
import 'package:petsupplies_inventory/models/app_models.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await LocalDatabase.instance.resetForTesting();
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
  });

  test(
    'database seeds the default categories, inventory items, discounts, and receipts',
    () async {
      final snapshot = await LocalDatabase.instance.loadSnapshot();

      expect(snapshot.categories, isNotEmpty);
      expect(snapshot.inventoryItems, isNotEmpty);
      expect(snapshot.discounts, isNotEmpty);
      expect(snapshot.receipts, isNotEmpty);
      expect(
        snapshot.categories.any(
          (category) =>
              category.name == protectedCategoryName && category.isProtected,
        ),
        isTrue,
      );
    },
  );

  test('protected Meng\'s Store category cannot be deleted', () async {
    final snapshot = await LocalDatabase.instance.loadSnapshot();
    final protectedCategory = snapshot.categories.firstWhere(
      (category) => category.name == protectedCategoryName,
    );

    await LocalDatabase.instance.deleteCategory(protectedCategory.id);
    await LocalDatabase.instance.close();

    final reopened = await LocalDatabase.instance.loadSnapshot();

    expect(
      reopened.categories.any(
        (category) =>
            category.name == protectedCategoryName && category.isProtected,
      ),
      isTrue,
    );
  });

  test('category insert persists after reopening the database', () async {
    await LocalDatabase.instance.insertCategory(
      const CategoryItem(id: 99, name: 'Bird Supplies', colorValue: 0xFFE53935),
    );

    await LocalDatabase.instance.close();

    final reopened = await LocalDatabase.instance.loadSnapshot();

    expect(
      reopened.categories.any((category) => category.name == 'Bird Supplies'),
      isTrue,
    );
  });

  test('inventory delete persists after reopening the database', () async {
    final beforeDelete = await LocalDatabase.instance.loadSnapshot();
    final itemId = beforeDelete.inventoryItems.first.id;

    await LocalDatabase.instance.deleteInventoryItem(itemId);
    await LocalDatabase.instance.close();

    final reopened = await LocalDatabase.instance.loadSnapshot();

    expect(reopened.inventoryItems.any((item) => item.id == itemId), isFalse);
  });

  test('inventory item visuals and pricing persist after reopening', () async {
    await LocalDatabase.instance.insertInventoryItem(
      const InventoryItem(
        id: 88,
        name: 'Bird Seed Mix',
        category: 'Accessories',
        stock: 12,
        reorderLevel: 4,
        unitCost: 8.50,
        price: 12.50,
        sku: 'ACC-BIR-0088',
        representation: InventoryRepresentation.image,
        displayColorValue: 0xFF42A5F5,
        displayShape: InventoryDisplayShape.circle,
        imagePath: '/tmp/mock_inventory_image.png',
      ),
    );

    await LocalDatabase.instance.close();

    final reopened = await LocalDatabase.instance.loadSnapshot();
    final savedItem = reopened.inventoryItems.firstWhere(
      (item) => item.id == 88,
    );

    expect(savedItem.sellingPrice, 12.50);
    expect(savedItem.unitCost, 8.50);
    expect(savedItem.resolvedSku, 'ACC-BIR-0088');
    expect(savedItem.representation, InventoryRepresentation.image);
    expect(savedItem.displayColor.toARGB32(), 0xFF42A5F5);
    expect(savedItem.displayShape, InventoryDisplayShape.circle);
    expect(savedItem.imagePath, '/tmp/mock_inventory_image.png');
  });

  test('discount insert persists after reopening the database', () async {
    await LocalDatabase.instance.insertDiscount(
      const DiscountItem(
        id: 77,
        name: 'Flash Sale',
        type: DiscountType.percentage,
        value: 15,
      ),
    );

    await LocalDatabase.instance.close();

    final reopened = await LocalDatabase.instance.loadSnapshot();

    expect(
      reopened.discounts.any((discount) => discount.name == 'Flash Sale'),
      isTrue,
    );
  });

  test(
    'completed charge persists updated stock and receipt after reopening',
    () async {
      final beforeCharge = await LocalDatabase.instance.loadSnapshot();
      final item = beforeCharge.inventoryItems.firstWhere(
        (entry) => entry.id == 2,
      );

      await LocalDatabase.instance.completeCharge(
        updatedItems: [item.copyWith(stock: item.stock - 1)],
        receipt: const ReceiptItem(
          id: 1049,
          number: 'RCPT-1049',
          date: '2026-04-07',
          time: '01:30 PM',
          items: 1,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Salmon Cat Food',
              quantity: 1,
              lineTotal: 10.20,
              category: 'Cat Food',
            ),
          ],
          cashier: 'Cashier',
          total: 10.20,
          isHighlighted: true,
        ),
      );

      await LocalDatabase.instance.close();

      final reopened = await LocalDatabase.instance.loadSnapshot();
      final updatedItem = reopened.inventoryItems.firstWhere(
        (entry) => entry.id == 2,
      );
      final receipt = reopened.receipts.firstWhere(
        (entry) => entry.number == 'RCPT-1049',
      );

      expect(updatedItem.stock, item.stock - 1);
      expect(receipt.total, 10.20);
      expect(receipt.date, '2026-04-07');
      expect(receipt.storeName, defaultReceiptStoreName);
      expect(receipt.purchasedItems.single.name, 'Salmon Cat Food');
      expect(receipt.purchasedItems.single.category, 'Cat Food');
      expect(receipt.isHighlighted, isTrue);
    },
  );
}
