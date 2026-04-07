// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petsupplies_inventory/data/local_database.dart';
import 'package:petsupplies_inventory/data/sample_data.dart';
import 'package:petsupplies_inventory/main.dart';
import 'package:petsupplies_inventory/models/app_models.dart';

void main() {
  testWidgets('app shows sales screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    expect(find.text('Sales'), findsWidgets);
    expect(find.text('Premium Dog Kibble'), findsOneWidget);
  });

  testWidgets('dashboard section can be opened from the sidebar', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Dashboard').first);
    await _pumpUntilReady(tester, find.text('Dashboard Overview'));

    final todayDate = DateTime.now().toIso8601String().split('T').first;
    final todaySales = receipts
        .where((receipt) => receipt.date == todayDate)
        .fold<double>(0, (sum, receipt) => sum + receipt.total);

    expect(find.text('Dashboard Overview'), findsOneWidget);
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('₱${todaySales.toStringAsFixed(2)}'), findsWidgets);
    expect(find.text('Dashboard Summary'), findsNothing);
  });

  testWidgets(
    'dashboard shows Meng\'s Store and general receipt sales totals',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final todayDate = DateTime.now().toIso8601String().split('T').first;
      final yesterdayDate = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .split('T')
          .first;

      final store = _FakeAppDataStore();
      store._receipts = [
        ReceiptItem(
          id: 3002,
          number: 'RCPT-3002',
          date: todayDate,
          time: '03:25 PM',
          items: 2,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Bowl',
              quantity: 1,
              lineTotal: 41.25,
              category: protectedCategoryName,
            ),
            ReceiptPurchase(
              name: 'Dental Chews',
              quantity: 1,
              lineTotal: 9.75,
              category: 'Treats',
            ),
          ],
          cashier: 'Andy',
          total: 51.00,
        ),
        ReceiptItem(
          id: 3001,
          number: 'RCPT-3001',
          date: yesterdayDate,
          time: '02:10 PM',
          items: 1,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Carrier Bag',
              quantity: 1,
              lineTotal: 7.30,
              category: 'Accessories',
            ),
          ],
          cashier: 'Noel',
          total: 7.30,
        ),
      ];

      await tester.pumpWidget(PetSuppliesApp(dataStore: store));
      await _pumpUntilReady(tester, find.text('Sales'));

      await tester.tap(find.text('Dashboard').first);
      await _pumpUntilReady(tester, find.text('Dashboard Overview'));

      expect(find.text("Meng's Store Sales"), findsOneWidget);
      expect(find.text('General Receipt Sales'), findsOneWidget);
      expect(find.text('₱41.25'), findsOneWidget);
      expect(find.text('₱9.75'), findsOneWidget);
      expect(find.text('₱51.00'), findsWidgets);
    },
  );

  testWidgets('dashboard can be filtered by date', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final todayDate = DateTime.now().toIso8601String().split('T').first;
    final yesterdayDate = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

    final store = _FakeAppDataStore();
    store._receipts = [
      ReceiptItem(
        id: 3002,
        number: 'RCPT-3002',
        date: todayDate,
        time: '03:25 PM',
        items: 2,
        purchasedItems: [
          ReceiptPurchase(
            name: 'Meng Bowl',
            quantity: 1,
            lineTotal: 41.25,
            category: protectedCategoryName,
          ),
          ReceiptPurchase(
            name: 'Dental Chews',
            quantity: 1,
            lineTotal: 9.75,
            category: 'Treats',
          ),
        ],
        cashier: 'Andy',
        total: 51.00,
      ),
      ReceiptItem(
        id: 3001,
        number: 'RCPT-3001',
        date: yesterdayDate,
        time: '02:10 PM',
        items: 1,
        purchasedItems: [
          ReceiptPurchase(
            name: 'Carrier Bag',
            quantity: 1,
            lineTotal: 7.30,
            category: 'Accessories',
          ),
        ],
        cashier: 'Noel',
        total: 7.30,
      ),
    ];

    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Dashboard').first);
    await _pumpUntilReady(tester, find.text('Dashboard Overview'));

    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text('₱51.00'), findsWidgets);
    expect(find.text("Today's Receipts"), findsOneWidget);
    expect(find.text('RCPT-3002'), findsOneWidget);
    expect(find.text('RCPT-3001'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard-date-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(_formatDashboardDateForTest(yesterdayDate)).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Filtered Sales'), findsOneWidget);
    expect(find.text('₱7.30'), findsWidgets);
    expect(find.text('₱0.00'), findsOneWidget);
    expect(
      find.text('Receipts for ${_formatDashboardDateForTest(yesterdayDate)}'),
      findsOneWidget,
    );
    expect(find.text('RCPT-3001'), findsOneWidget);
    expect(find.text('RCPT-3002'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard-date-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Dates').last);
    await tester.pumpAndSettle();

    expect(find.text('All Sales'), findsOneWidget);
    expect(find.text('₱58.30'), findsOneWidget);
    expect(find.text('₱41.25'), findsOneWidget);
    expect(find.text('₱17.05'), findsOneWidget);
    expect(find.text('Recent Receipts'), findsOneWidget);
    expect(find.text('RCPT-3002'), findsOneWidget);
    expect(find.text('RCPT-3001'), findsOneWidget);
  });

  testWidgets('inventory submenus can be opened from the sidebar', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Inventory').first);
    await _pumpUntilReady(tester, find.text('Add Item'));

    expect(find.text('Purchase Order'), findsOneWidget);
    expect(find.text('Stock Adjustment'), findsOneWidget);
    expect(find.text('Inventory Count'), findsOneWidget);
    expect(find.text('Inventory History'), findsOneWidget);

    await tester.tap(find.text('Purchase Order'));
    await _pumpUntilReady(tester, find.text('Purchase Order Overview'));

    expect(find.text('Purchase Order Overview'), findsOneWidget);
    expect(find.text('Items Needing Reorder'), findsOneWidget);
    expect(find.text('Purchase Flow'), findsOneWidget);
  });

  testWidgets('can add a category from the categories screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Categories'));

    await tester.tap(find.text('Categories').first);
    await _pumpUntilReady(tester, find.text('Add Category'));

    await tester.tap(find.text('Add Category'));
    await _pumpUntilReady(tester, find.text('Add'));

    await tester.enterText(find.byType(EditableText), 'Bird Supplies');
    await tester.tap(find.text('Add'));
    await _pumpUntilReady(tester, find.text('Bird Supplies'));

    expect(find.text('Bird Supplies'), findsWidgets);
  });

  testWidgets('category changes persist after app restart', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Categories'));

    await tester.tap(find.text('Categories').first);
    await _pumpUntilReady(tester, find.text('Add Category'));

    await tester.tap(find.text('Add Category'));
    await _pumpUntilReady(tester, find.text('Add'));

    await tester.enterText(find.byType(EditableText), 'Bird Supplies');
    await tester.tap(find.text('Add'));
    await _pumpUntilReady(tester, find.text('Bird Supplies'));

    expect(find.text('Bird Supplies'), findsWidgets);

    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Categories'));

    await tester.tap(find.text('Categories').first);
    await _pumpUntilReady(tester, find.text('Bird Supplies'));

    expect(find.text('Bird Supplies'), findsWidgets);
  });

  testWidgets('protected Meng\'s Store category is shown as locked', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Categories'));

    await tester.tap(find.text('Categories').first);
    await _pumpUntilReady(tester, find.text(protectedCategoryName));

    expect(find.text(protectedCategoryName), findsWidgets);
    expect(find.byTooltip('Protected category'), findsOneWidget);
  });

  testWidgets('sales grid filters when a bottom category tab is tapped', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    store._inventoryItems = [
      ...store._inventoryItems,
      const InventoryItem(
        id: 11,
        name: 'Meng Leash',
        category: protectedCategoryName,
        stock: 6,
        reorderLevel: 2,
        unitCost: 21.50,
      ),
    ];

    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Premium Dog Kibble'));

    expect(find.text("MENG'S STORE"), findsOneWidget);
    expect(find.text('Premium Dog Kibble'), findsOneWidget);
    expect(find.text('Meng Leash'), findsNothing);

    final allTabPosition = tester.getTopLeft(find.text('ALL').first);
    final mengStoreTabPosition = tester.getTopLeft(find.text("MENG'S STORE"));
    final dogFoodTabPosition = tester.getTopLeft(find.text('DOG FOOD').first);

    expect(mengStoreTabPosition.dx, greaterThan(allTabPosition.dx));
    expect(mengStoreTabPosition.dx, lessThan(dogFoodTabPosition.dx));

    await tester.tap(find.text('TREATS').first);
    await _pumpUntilReady(tester, find.text('Training Treats'));

    expect(find.text('Training Treats'), findsOneWidget);
    expect(find.text('Dental Chews'), findsOneWidget);
    expect(find.text('Premium Dog Kibble'), findsNothing);

    await tester.tap(find.text('ALL').first);
    await _pumpUntilReady(tester, find.text('Premium Dog Kibble'));

    expect(find.text('Premium Dog Kibble'), findsOneWidget);
    expect(find.text('Training Treats'), findsOneWidget);
    expect(find.text('Meng Leash'), findsNothing);

    await tester.tap(find.text("MENG'S STORE"));
    await _pumpUntilReady(tester, find.text('Meng Leash'));

    expect(find.text('Meng Leash'), findsOneWidget);
    expect(find.text('Premium Dog Kibble'), findsNothing);
  });

  testWidgets('can add a discount from the discounts screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Discounts'));

    await tester.tap(find.text('Discounts').first);
    await _pumpUntilReady(tester, find.text('Add Discount'));

    await tester.tap(find.text('Add Discount'));
    await _pumpUntilReady(tester, find.text('Discount name'));

    await tester.enterText(find.byType(EditableText).first, 'Holiday Promo');
    await tester.tap(find.byType(DropdownButtonFormField<DiscountType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exact Amount').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).last, '25');
    await tester.tap(find.text('Add'));
    await _pumpUntilReady(tester, find.text('Holiday Promo'));

    expect(find.text('Holiday Promo'), findsWidgets);
    expect(find.text('₱25.00'), findsWidgets);
  });

  testWidgets('can add an inventory item from the inventory screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Inventory').first);
    await _pumpUntilReady(tester, find.text('Add Item'));

    await tester.tap(find.text('Add Item'));
    await _pumpUntilReady(tester, find.text('Name'));

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Bird Seed Mix');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toys').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '11.50');
    await tester.enterText(fields.at(2), '8.50');
    await tester.tap(
      find.byKey(ValueKey('display-color-${inventoryDisplayColorChoices[3]}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('display-shape-circle')));
    await tester.pumpAndSettle();

    final expectedSku = generateInventorySku(
      id: 11,
      name: 'Bird Seed Mix',
      category: 'Toys',
    );
    expect(find.text(expectedSku), findsOneWidget);

    await tester.enterText(fields.at(4), '12');
    await tester.enterText(fields.at(5), '4');
    await tester.tap(find.text('Add'));
    await _pumpUntilReady(tester, find.text('Bird Seed Mix'));

    expect(find.text('Bird Seed Mix'), findsWidgets);
    expect(find.text(expectedSku), findsWidgets);
    expect(find.text('₱11.50'), findsOneWidget);
    expect(find.text('8.50'), findsWidgets);

    await tester.tap(find.text('Sales').first);
    await _pumpUntilReady(tester, find.text('Bird Seed Mix'));

    expect(
      find.byKey(const ValueKey('product-shape-11-circle')),
      findsOneWidget,
    );
  });

  testWidgets('inventory items are reflected in sales', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    await tester.pumpWidget(
      PetSuppliesApp(
        dataStore: store,
        inventoryImagePicker: const _FakeInventoryImagePicker(
          '/tmp/mock_inventory_image.png',
        ),
      ),
    );
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Inventory').first);
    await _pumpUntilReady(tester, find.text('Add Item'));

    await tester.tap(find.text('Add Item'));
    await _pumpUntilReady(tester, find.text('Name'));

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Bird Seed Mix');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accessories').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(1), '12.50');
    await tester.enterText(fields.at(2), '8.50');
    await tester.enterText(fields.at(4), '12');
    await tester.enterText(fields.at(5), '4');
    await tester.tap(
      find.byType(DropdownButtonFormField<InventoryRepresentation>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Image').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload Image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await _pumpUntilReady(tester, find.text('Bird Seed Mix'));

    await tester.tap(find.text('Sales').first);
    await _pumpUntilReady(tester, find.text('Bird Seed Mix'));

    expect(find.text('Bird Seed Mix'), findsWidgets);
    expect(find.text('₱12.50'), findsWidgets);
    expect(find.byKey(const ValueKey('product-image-11')), findsOneWidget);
  });

  testWidgets('items screen shows information only without crud actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Items Information'));

    expect(find.text('Items Information'), findsOneWidget);
    expect(find.text('Add Item'), findsNothing);
    expect(find.byTooltip('Edit item'), findsNothing);
    expect(find.byTooltip('Delete item'), findsNothing);
  });

  testWidgets('sales search filters visible items', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    expect(find.text('Premium Dog Kibble'), findsOneWidget);
    expect(find.text('Salmon Cat Food'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'salmon');
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food'), findsOneWidget);
    expect(find.text('Premium Dog Kibble'), findsNothing);
  });

  testWidgets('clicking a sales item adds it to the ticket', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 2'), findsOneWidget);
  });

  testWidgets('clicking an out of stock sales item shows a message', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    store._inventoryItems = store._inventoryItems
        .map((item) => item.id == 2 ? item.copyWith(stock: 0) : item)
        .toList();

    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('Salmon Cat Food is out of stock.'), findsOneWidget);
    expect(find.text('Salmon Cat Food x 1'), findsNothing);
  });

  testWidgets('ticket quantity cannot exceed available stock', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    store._inventoryItems = store._inventoryItems
        .map((item) => item.id == 2 ? item.copyWith(stock: 1) : item)
        .toList();

    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Stock Limit Reached'), findsOneWidget);
    expect(
      find.text('Salmon Cat Food only has 1 unit available in stock.'),
      findsOneWidget,
    );
    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);
    expect(find.text('Salmon Cat Food x 2'), findsNothing);
  });

  testWidgets('ticket items can be removed individually', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsNothing);
    expect(
      find.text('Tap an item in Sales to add it to this ticket.'),
      findsOneWidget,
    );
  });

  testWidgets('clear button empties the ticket', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);

    await tester.tap(find.text('CLEAR'));
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsNothing);
    expect(
      find.text('Tap an item in Sales to add it to this ticket.'),
      findsOneWidget,
    );
  });

  testWidgets('charge opens a payment dialog with total and amount received', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHARGE'));
    await tester.pumpAndSettle();

    expect(find.text('Charge Payment'), findsOneWidget);
    expect(find.text('Total Amount to be Paid'), findsOneWidget);
    expect(find.text('Amount Received'), findsOneWidget);
  });

  testWidgets(
    'charge shows confirmation dialog and success message after proceeding',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
      await _pumpUntilReady(tester, find.text('Sales'));

      await tester.tap(find.text('Salmon Cat Food').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('CHARGE'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).last, '20');
      await tester.tap(find.text('Charge'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Payment'), findsOneWidget);
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('Change'), findsWidgets);

      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();

      expect(find.text('Payment Successful'), findsOneWidget);
      expect(
        find.text('The payment has been processed successfully.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('successful charge is recorded in receipts', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHARGE'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).last, '20');
    await tester.tap(find.text('Charge'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Receipts').first);
    await _pumpUntilReady(tester, find.text('Recent Receipts'));

    expect(find.text('RCPT-1049'), findsWidgets);
    expect(find.text('#1049'), findsOneWidget);
    expect(find.text('Purchased Items'), findsOneWidget);
    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);
    expect(find.text('10.20'), findsWidgets);
  });

  testWidgets('successful charge deducts sold quantity from item stock', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('CHARGE'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).last, '20');
    await tester.tap(find.text('Charge'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Successful'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Items Information'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('#2'), findsOneWidget);
    expect(find.text('27'), findsWidgets);
    expect(find.text('₱275.40'), findsOneWidget);
  });

  testWidgets('receipt summary updates when a receipt is selected', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Receipts').first);
    await _pumpUntilReady(tester, find.text('Recent Receipts'));

    await tester.tap(find.text('RCPT-1045').first);
    await tester.pumpAndSettle();

    expect(find.text('#1045'), findsOneWidget);
    expect(find.text('₱14.80'), findsOneWidget);
    expect(find.text('Pet Shampoo x 1'), findsOneWidget);

    await tester.tap(find.text('RCPT-1042').first);
    await tester.pumpAndSettle();

    expect(find.text('#1042'), findsOneWidget);
    expect(find.text('₱42.75'), findsOneWidget);
    expect(find.text('Premium Dog Kibble x 1'), findsOneWidget);
  });

  testWidgets('receipts can be filtered by date', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Receipts').first);
    await _pumpUntilReady(tester, find.text('Recent Receipts'));

    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('April 6, 2026').last);
    await tester.pumpAndSettle();

    expect(find.text('RCPT-1046'), findsWidgets);
    expect(find.text('RCPT-1045'), findsWidgets);
    expect(find.text('RCPT-1048'), findsNothing);
    expect(find.text('RCPT-1042'), findsNothing);
    expect(find.text('#1046'), findsOneWidget);
  });

  testWidgets('general receipt excludes Meng\'s Store items', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final store = _FakeAppDataStore();
    store._receipts = [
      const ReceiptItem(
        id: 3002,
        number: 'RCPT-3002',
        date: '2026-04-07',
        time: '03:25 PM',
        items: 1,
        purchasedItems: [
          ReceiptPurchase(
            name: 'Meng Bowl',
            quantity: 1,
            lineTotal: 30,
            category: protectedCategoryName,
          ),
        ],
        cashier: 'Andy',
        total: 30,
      ),
      const ReceiptItem(
        id: 3001,
        number: 'RCPT-3001',
        date: '2026-04-07',
        time: '03:10 PM',
        items: 3,
        purchasedItems: [
          ReceiptPurchase(
            name: 'Meng Collar',
            quantity: 2,
            lineTotal: 50,
            category: protectedCategoryName,
          ),
          ReceiptPurchase(
            name: 'Salmon Cat Food',
            quantity: 1,
            lineTotal: 10.20,
            category: 'Cat Food',
          ),
        ],
        cashier: 'Andy',
        total: 60.20,
      ),
      ...store._receipts,
    ];

    await tester.pumpWidget(PetSuppliesApp(dataStore: store));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Receipts').first);
    await _pumpUntilReady(tester, find.text('Recent Receipts'));

    expect(find.text('RCPT-3002'), findsNothing);
    expect(find.text('RCPT-3001'), findsWidgets);

    await tester.tap(find.text('RCPT-3001').first);
    await tester.pumpAndSettle();

    expect(find.text('Salmon Cat Food x 1'), findsOneWidget);
    expect(find.text('Meng Collar x 2'), findsNothing);
    expect(find.text('₱10.20'), findsWidgets);
  });

  testWidgets(
    'combined receipt submenu shows both general and Meng\'s Store purchases',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = _FakeAppDataStore();
      store._receipts = [
        const ReceiptItem(
          id: 3002,
          number: 'RCPT-3002',
          date: '2026-04-07',
          time: '03:25 PM',
          items: 1,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Bowl',
              quantity: 1,
              lineTotal: 30,
              category: protectedCategoryName,
            ),
          ],
          cashier: 'Andy',
          total: 30,
        ),
        const ReceiptItem(
          id: 3001,
          number: 'RCPT-3001',
          date: '2026-04-07',
          time: '03:10 PM',
          items: 3,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Collar',
              quantity: 2,
              lineTotal: 50,
              category: protectedCategoryName,
            ),
            ReceiptPurchase(
              name: 'Salmon Cat Food',
              quantity: 1,
              lineTotal: 10.20,
              category: 'Cat Food',
            ),
          ],
          cashier: 'Andy',
          total: 60.20,
        ),
      ];

      await tester.pumpWidget(PetSuppliesApp(dataStore: store));
      await _pumpUntilReady(tester, find.text('Sales'));

      await tester.tap(find.text('Receipts').first);
      await _pumpUntilReady(tester, find.text('Recent Receipts'));

      await tester.tap(find.text('Combined Receipt').first);
      await _pumpUntilReady(tester, find.text('Combined Receipts'));

      expect(find.text('RCPT-3002'), findsWidgets);
      expect(find.text('RCPT-3001'), findsWidgets);
      expect(
        find.text(
          "Shows full receipt totals from General Receipt and Meng's Store purchases.",
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('RCPT-3001').first);
      await tester.pumpAndSettle();

      expect(find.text('#3001'), findsOneWidget);
      expect(find.text('Meng Collar x 2'), findsOneWidget);
      expect(find.text('Salmon Cat Food x 1'), findsOneWidget);
      expect(find.text('Combined Receipt'), findsWidgets);
      expect(find.text('₱60.20'), findsWidgets);
    },
  );

  testWidgets(
    'Meng\'s Store receipt sidebar shows only Meng\'s Store purchases',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = _FakeAppDataStore();
      store._inventoryItems = [
        ...store._inventoryItems,
        const InventoryItem(
          id: 99,
          name: 'Meng Collar',
          category: protectedCategoryName,
          stock: 4,
          reorderLevel: 1,
          unitCost: 25,
        ),
      ];
      store._receipts = [
        const ReceiptItem(
          id: 3002,
          number: 'RCPT-3002',
          date: '2026-04-07',
          time: '03:25 PM',
          items: 1,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Bowl',
              quantity: 1,
              lineTotal: 30,
              category: protectedCategoryName,
            ),
          ],
          cashier: 'Andy',
          total: 30,
        ),
        const ReceiptItem(
          id: 3001,
          number: 'RCPT-3001',
          date: '2026-04-07',
          time: '03:10 PM',
          items: 3,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Collar',
              quantity: 2,
              lineTotal: 50,
              category: protectedCategoryName,
            ),
            ReceiptPurchase(
              name: 'Salmon Cat Food',
              quantity: 1,
              lineTotal: 10.20,
              category: 'Cat Food',
            ),
          ],
          cashier: 'Andy',
          total: 60.20,
        ),
        ...store._receipts,
      ];

      await tester.pumpWidget(PetSuppliesApp(dataStore: store));
      await _pumpUntilReady(tester, find.text('Sales'));

      await tester.tap(find.text('Receipts').first);
      await _pumpUntilReady(tester, find.text('Recent Receipts'));

      await tester.tap(find.text("Meng's Store").first);
      await _pumpUntilReady(tester, find.text("Meng's Store Receipt Table"));

      expect(find.text("Meng's Store Receipt Table"), findsOneWidget);
      expect(find.text('Meng Collar'), findsOneWidget);
      expect(find.text('RCPT-3001'), findsWidgets);
      expect(find.text('RCPT-3002'), findsOneWidget);
      expect(find.text('₱50.00'), findsWidgets);
      expect(find.text('Salmon Cat Food'), findsNothing);
    },
  );

  testWidgets(
    'Meng\'s Store receipt summary updates when a receipt is tapped',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final store = _FakeAppDataStore();
      store._receipts = [
        const ReceiptItem(
          id: 3002,
          number: 'RCPT-3002',
          date: '2026-04-07',
          time: '03:25 PM',
          items: 1,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Bowl',
              quantity: 1,
              lineTotal: 30,
              category: protectedCategoryName,
            ),
          ],
          cashier: 'Andy',
          total: 30,
        ),
        const ReceiptItem(
          id: 3001,
          number: 'RCPT-3001',
          date: '2026-04-07',
          time: '03:10 PM',
          items: 3,
          purchasedItems: [
            ReceiptPurchase(
              name: 'Meng Collar',
              quantity: 2,
              lineTotal: 50,
              category: protectedCategoryName,
            ),
            ReceiptPurchase(
              name: 'Salmon Cat Food',
              quantity: 1,
              lineTotal: 10.20,
              category: 'Cat Food',
            ),
          ],
          cashier: 'Andy',
          total: 60.20,
        ),
        ...store._receipts,
      ];

      await tester.pumpWidget(PetSuppliesApp(dataStore: store));
      await _pumpUntilReady(tester, find.text('Sales'));

      await tester.tap(find.text('Receipts').first);
      await _pumpUntilReady(tester, find.text('Recent Receipts'));

      await tester.tap(find.text("Meng's Store").first);
      await _pumpUntilReady(tester, find.text("Meng's Store Receipt Table"));

      await tester.tap(find.text('RCPT-3002').first);
      await tester.pumpAndSettle();

      expect(find.text('#3002'), findsOneWidget);
      expect(find.text('Meng Bowl x 1'), findsOneWidget);
      expect(find.text('₱30.00'), findsWidgets);
      expect(find.text('Meng Collar x 2'), findsNothing);

      await tester.tap(find.text('RCPT-3001').first);
      await tester.pumpAndSettle();

      expect(find.text('#3001'), findsOneWidget);
      expect(find.text('Meng Collar x 2'), findsOneWidget);
      expect(find.text('Salmon Cat Food x 1'), findsNothing);
      expect(find.text('Store'), findsWidgets);
      expect(find.text("Meng's Store"), findsWidgets);
    },
  );

  testWidgets('item summary updates when an inventory item is selected', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const ui.Size(2400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(PetSuppliesApp(dataStore: _FakeAppDataStore()));
    await _pumpUntilReady(tester, find.text('Sales'));

    await tester.tap(find.text('Items').first);
    await _pumpUntilReady(tester, find.text('Items Information'));

    await tester.tap(find.text('Salmon Cat Food').first);
    await tester.pumpAndSettle();

    expect(find.text('#2'), findsOneWidget);
    expect(find.text('₱285.60'), findsOneWidget);

    await tester.tap(find.text('Dental Chews').first);
    await tester.pumpAndSettle();

    expect(find.text('#3'), findsOneWidget);
    expect(find.text('₱47.60'), findsOneWidget);
  });
}

String _formatDashboardDateForTest(String value) {
  final date = DateTime.parse(value);
  return '${_monthNameForTest(date.month)} ${date.day}, ${date.year}';
}

String _monthNameForTest(int month) {
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

  return monthNames[month - 1];
}

Future<void> _pumpUntilReady(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 120));
    if (tester.any(find.text('Could not load local database.'))) {
      break;
    }
    if (tester.any(finder)) {
      return;
    }
  }

  expect(find.text('Could not load local database.'), findsNothing);
  expect(finder, findsWidgets);
}

class _FakeInventoryImagePicker implements InventoryImagePicker {
  const _FakeInventoryImagePicker(this.path);

  final String path;

  @override
  Future<String?> pickAndSaveImage({required String sku}) async => path;
}

class _FakeAppDataStore implements AppDataStore {
  _FakeAppDataStore()
    : _categories = List.of(initialCategories),
      _inventoryItems = List.of(initialInventoryItems),
      _discounts = List.of(initialDiscounts),
      _receipts = List.of(receipts);

  List<CategoryItem> _categories;
  List<InventoryItem> _inventoryItems;
  List<DiscountItem> _discounts;
  List<ReceiptItem> _receipts;

  @override
  Future<void> deleteCategory(int id) async {
    final category = _categories.cast<CategoryItem?>().firstWhere(
      (entry) => entry?.id == id,
      orElse: () => null,
    );
    if (category?.isProtected ?? false) {
      return;
    }
    _categories = _categories.where((entry) => entry.id != id).toList();
  }

  @override
  Future<void> deleteInventoryItem(int id) async {
    _inventoryItems = _inventoryItems.where((entry) => entry.id != id).toList();
  }

  @override
  Future<void> deleteDiscount(int id) async {
    _discounts = _discounts.where((entry) => entry.id != id).toList();
  }

  @override
  Future<void> insertCategory(CategoryItem category) async {
    _categories = [..._categories, category];
  }

  @override
  Future<void> insertInventoryItem(InventoryItem item) async {
    _inventoryItems = [..._inventoryItems, item];
  }

  @override
  Future<void> insertDiscount(DiscountItem discount) async {
    _discounts = [..._discounts, discount];
  }

  @override
  Future<AppDataSnapshot> loadSnapshot() async {
    final sortedReceipts = List<ReceiptItem>.of(_receipts)
      ..sort((left, right) => right.id.compareTo(left.id));

    return AppDataSnapshot(
      categories: List.of(_categories),
      inventoryItems: List.of(_inventoryItems),
      discounts: List.of(_discounts),
      receipts: sortedReceipts,
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
    _categories = _categories
        .map((entry) => entry.id == category.id ? category : entry)
        .toList();
    if (previousName != category.name) {
      _inventoryItems = _inventoryItems
          .map(
            (entry) => entry.category == previousName
                ? entry.copyWith(category: category.name)
                : entry,
          )
          .toList();
    }
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    _inventoryItems = _inventoryItems
        .map((entry) => entry.id == item.id ? item : entry)
        .toList();
  }

  @override
  Future<void> updateDiscount(DiscountItem discount) async {
    _discounts = _discounts
        .map((entry) => entry.id == discount.id ? discount : entry)
        .toList();
  }

  @override
  Future<void> completeCharge({
    required List<InventoryItem> updatedItems,
    required ReceiptItem receipt,
  }) async {
    for (final item in updatedItems) {
      _inventoryItems = _inventoryItems
          .map((entry) => entry.id == item.id ? item : entry)
          .toList();
    }
    _receipts = [
      receipt,
      ..._receipts.map((entry) => entry.copyWith(isHighlighted: false)),
    ];
  }
}
