import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'content/dashboard_content.dart';
import 'content/discounts_content.dart';
import 'content/inventory_content.dart';
import 'content/inventory_workflows_content.dart';
import 'content/receipts_content.dart';
import 'content/sales_content.dart';
import 'data/local_database.dart';
import 'data/sample_data.dart';
import 'models/app_models.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';

void main() {
  runApp(const PetSuppliesApp());
}

class PetSuppliesApp extends StatelessWidget {
  const PetSuppliesApp({super.key, this.dataStore, this.inventoryImagePicker});

  final AppDataStore? dataStore;
  final InventoryImagePicker? inventoryImagePicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Supplies Inventory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: true,
      ),
      home: InventoryDashboard(
        dataStore: dataStore,
        inventoryImagePicker: inventoryImagePicker,
      ),
    );
  }
}

abstract class InventoryImagePicker {
  Future<String?> pickAndSaveImage({required String sku});
}

class FileSelectorInventoryImagePicker implements InventoryImagePicker {
  const FileSelectorInventoryImagePicker();

  @override
  Future<String?> pickAndSaveImage({required String sku}) async {
    const imageTypeGroup = XTypeGroup(
      label: 'images',
      extensions: ['png', 'jpg', 'jpeg', 'webp'],
    );

    final selectedFile = await openFile(acceptedTypeGroups: [imageTypeGroup]);
    if (selectedFile == null) {
      return null;
    }

    final appDirectory = await getApplicationDocumentsDirectory();
    final imagesDirectory = Directory(
      p.join(appDirectory.path, 'inventory_images'),
    );
    await imagesDirectory.create(recursive: true);

    final sourceName = selectedFile.name.isNotEmpty
        ? selectedFile.name
        : p.basename(selectedFile.path);
    final extension = p.extension(sourceName).toLowerCase();
    final safeExtension = extension.isEmpty ? '.png' : extension;
    final safeSku = sku.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final targetPath = p.join(
      imagesDirectory.path,
      '${safeSku}_${DateTime.now().millisecondsSinceEpoch}$safeExtension',
    );

    if (selectedFile.path.isNotEmpty) {
      await File(selectedFile.path).copy(targetPath);
    } else {
      await File(targetPath).writeAsBytes(await selectedFile.readAsBytes());
    }

    return targetPath;
  }
}

class InventoryDashboard extends StatefulWidget {
  const InventoryDashboard({
    super.key,
    this.dataStore,
    this.inventoryImagePicker,
  });

  final AppDataStore? dataStore;
  final InventoryImagePicker? inventoryImagePicker;

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  late final AppDataStore _dataStore;
  late final InventoryImagePicker _inventoryImagePicker;
  late final TextEditingController _salesSearchController;
  bool _isSidebarOpen = true;
  String _selectedSection = 'sales';
  List<InventoryItem> _inventoryItems = [];
  List<DiscountItem> _discounts = [];
  List<CategoryItem> _categories = [];
  List<ReceiptItem> _receipts = [];
  List<CartItem> _cartItems = [];
  String _salesSearchQuery = '';
  int? _selectedInventoryItemId;
  int? _selectedCategoryId;
  int? _selectedSalesCategoryId;
  int? _selectedReceiptId;
  String? _selectedReceiptDateFilter;
  bool _isLoading = true;
  String? _loadError;
  int _nextInventoryId = 11;
  int _nextDiscountId = 4;
  int _nextCategoryId = 8;
  int _nextReceiptId = 1049;

  @override
  void initState() {
    super.initState();
    _dataStore = widget.dataStore ?? LocalDatabase.instance;
    _inventoryImagePicker =
        widget.inventoryImagePicker ?? const FileSelectorInventoryImagePicker();
    _salesSearchController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _salesSearchController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _selectSection(String section) {
    setState(() {
      _selectedSection = section;
      if (section != 'sales' && _salesSearchQuery.isNotEmpty) {
        _salesSearchQuery = '';
        _salesSearchController.clear();
      }
      if ((section == 'items' || section == 'inventory') &&
          _selectedInventoryItemId == null &&
          _inventoryItems.isNotEmpty) {
        _selectedInventoryItemId = _inventoryItems.first.id;
      }
      if (section == 'categories' &&
          _selectedCategoryId == null &&
          _categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
      if (section == 'receipts') {
        final generalReceipts = _generalReceipts();
        _selectedReceiptDateFilter = _resolveReceiptDateFilter(
          _selectedReceiptDateFilter,
          receipts: generalReceipts,
        );
        _selectedReceiptId = _resolveReceiptSelection(
          _selectedReceiptId,
          receipts: _filterReceiptsByDate(
            _selectedReceiptDateFilter,
            receipts: generalReceipts,
          ),
        );
      }
      if (section == 'combined_receipts') {
        final combinedReceipts = _combinedReceipts();
        _selectedReceiptDateFilter = _resolveReceiptDateFilter(
          _selectedReceiptDateFilter,
          receipts: combinedReceipts,
        );
        _selectedReceiptId = _resolveReceiptSelection(
          _selectedReceiptId,
          receipts: _filterReceiptsByDate(
            _selectedReceiptDateFilter,
            receipts: combinedReceipts,
          ),
        );
      }
      if (section == 'meng_store_receipts') {
        final mengStoreReceipts = _mengStoreReceipts();
        _selectedReceiptDateFilter = _resolveReceiptDateFilter(
          _selectedReceiptDateFilter,
          receipts: mengStoreReceipts,
        );
        _selectedReceiptId = _resolveReceiptSelection(
          _selectedReceiptId,
          receipts: _filterReceiptsByDate(
            _selectedReceiptDateFilter,
            receipts: mengStoreReceipts,
          ),
        );
      }
    });
  }

  void _selectCategory(CategoryItem category) {
    setState(() {
      _selectedCategoryId = category.id;
    });
  }

  void _selectSalesCategory(CategoryItem category) {
    setState(() {
      _selectedSalesCategoryId = category.id;
    });
  }

  void _selectInventoryItem(InventoryItem item) {
    setState(() {
      _selectedInventoryItemId = item.id;
    });
  }

  void _selectReceipt(ReceiptItem receipt) {
    setState(() {
      _selectedReceiptId = receipt.id;
    });
  }

  void _updateReceiptDateFilter(String? date) {
    setState(() {
      final scopedReceipts = _selectedSection == 'receipts'
          ? _generalReceipts()
          : _selectedSection == 'combined_receipts'
          ? _combinedReceipts()
          : _selectedSection == 'meng_store_receipts'
          ? _mengStoreReceipts()
          : _receipts;
      _selectedReceiptDateFilter = _resolveReceiptDateFilter(
        date,
        receipts: scopedReceipts,
      );
      _selectedReceiptId = _resolveReceiptSelection(
        _selectedReceiptId,
        receipts: _filterReceiptsByDate(
          _selectedReceiptDateFilter,
          receipts: scopedReceipts,
        ),
      );
    });
  }

  void _showAllSalesItems() {
    setState(() {
      _selectedSalesCategoryId = null;
    });
  }

  void _updateSalesSearchQuery(String value) {
    setState(() {
      _salesSearchQuery = value.trim();
    });
  }

  bool _isVisibleInAllSales(InventoryItem item) {
    return item.category != protectedCategoryName;
  }

  Future<void> _showSalesItemMessage({
    required String title,
    required String message,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSalesItemToTicket(CatalogItem item) async {
    final inventoryItem = _inventoryItems.cast<InventoryItem?>().firstWhere(
      (entry) =>
          entry?.id == item.id || (item.id == null && entry?.name == item.name),
      orElse: () => null,
    );
    final existingIndex = _cartItems.indexWhere(
      (entry) =>
          entry.inventoryItemId == item.id ||
          (entry.inventoryItemId == null && entry.name == item.name),
    );
    final existingQuantity = existingIndex >= 0
        ? _cartItems[existingIndex].quantity
        : 0;

    if (inventoryItem != null && inventoryItem.stock <= 0) {
      await _showSalesItemMessage(
        title: 'Out of Stock',
        message: '${item.name} is out of stock.',
      );
      return;
    }

    if (inventoryItem != null && existingQuantity >= inventoryItem.stock) {
      final unitLabel = inventoryItem.stock == 1 ? 'unit' : 'units';
      await _showSalesItemMessage(
        title: 'Stock Limit Reached',
        message:
            '${item.name} only has ${inventoryItem.stock} $unitLabel available in stock.',
      );
      return;
    }

    final itemPrice = item.price ?? 0.0;
    final itemRepresentation =
        inventoryItem?.representation ?? item.representation;
    final itemDisplayColorValue =
        inventoryItem?.resolvedDisplayColorValue ??
        item.displayColor?.toARGB32() ??
        0;
    final itemDisplayShape = inventoryItem?.displayShape ?? item.displayShape;
    final itemImagePath = inventoryItem?.imagePath ?? item.imagePath ?? '';

    setState(() {
      if (existingIndex >= 0) {
        final existing = _cartItems[existingIndex];
        _cartItems = List<CartItem>.from(_cartItems)
          ..[existingIndex] = existing.copyWith(
            quantity: existing.quantity + 1,
            representation: itemRepresentation,
            displayColorValue: itemDisplayColorValue,
            displayShape: itemDisplayShape,
            imagePath: itemImagePath,
          );
        return;
      }

      _cartItems = [
        ..._cartItems,
        CartItem(
          inventoryItemId: item.id,
          name: item.name,
          quantity: 1,
          price: itemPrice,
          representation: itemRepresentation,
          displayColorValue: itemDisplayColorValue,
          displayShape: itemDisplayShape,
          imagePath: itemImagePath,
        ),
      ];
    });
  }

  void _clearTicket() {
    setState(() {
      _cartItems = [];
    });
  }

  void _removeSalesItemFromTicket(CartItem item) {
    setState(() {
      _cartItems = _cartItems
          .where(
            (entry) =>
                entry.inventoryItemId != item.inventoryItemId ||
                entry.name != item.name,
          )
          .toList();
    });
  }

  Future<String?> _chargeTicket(List<CartItem> cart) async {
    final updatedItems = List<InventoryItem>.from(_inventoryItems);
    final itemsToPersist = <InventoryItem>[];
    final receiptId = _nextReceiptId;
    final receiptTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.now());
    final purchasedItems = cart.map((item) {
      final inventoryItem = _inventoryItems.cast<InventoryItem?>().firstWhere(
        (entry) =>
            entry?.id == item.inventoryItemId ||
            (item.inventoryItemId == null && entry?.name == item.name),
        orElse: () => null,
      );

      return ReceiptPurchase(
        name: item.name,
        quantity: item.quantity,
        lineTotal: item.total,
        category: inventoryItem?.category ?? '',
        representation: item.representation,
        displayColorValue: item.displayColorValue,
        displayShape: item.displayShape,
        imagePath: item.imagePath,
      );
    }).toList();
    final receipt = ReceiptItem(
      id: receiptId,
      number: 'RCPT-$receiptId',
      date: _storageDateString(DateTime.now()),
      time: receiptTime,
      items: cart.fold<int>(0, (sum, item) => sum + item.quantity),
      purchasedItems: purchasedItems,
      storeName: defaultReceiptStoreName,
      cashier: 'Cashier',
      total: cart.fold<double>(0, (sum, item) => sum + item.total),
      isHighlighted: true,
    );

    for (final cartItem in cart) {
      final itemIndex = updatedItems.indexWhere(
        (item) =>
            item.id == cartItem.inventoryItemId ||
            (cartItem.inventoryItemId == null && item.name == cartItem.name),
      );

      if (itemIndex == -1) {
        return 'Unable to find ${cartItem.name} in inventory.';
      }

      final inventoryItem = updatedItems[itemIndex];
      if (inventoryItem.stock < cartItem.quantity) {
        return 'Not enough stock for ${cartItem.name}. Available: ${inventoryItem.stock}.';
      }

      final updatedItem = inventoryItem.copyWith(
        stock: inventoryItem.stock - cartItem.quantity,
      );
      updatedItems[itemIndex] = updatedItem;
      itemsToPersist.add(updatedItem);
    }

    try {
      await _dataStore.completeCharge(
        updatedItems: itemsToPersist,
        receipt: receipt,
      );
    } catch (_) {
      return 'Unable to complete the charge right now. Please try again.';
    }

    if (!mounted) {
      return null;
    }

    setState(() {
      _inventoryItems = updatedItems;
      final nextReceipts = [
        receipt,
        ..._receipts.map((entry) => entry.copyWith(isHighlighted: false)),
      ];
      _receipts = nextReceipts;
      _selectedReceiptDateFilter = _resolveReceiptDateFilter(
        _selectedReceiptDateFilter,
        receipts: nextReceipts,
      );
      final filteredReceipts = _filterReceiptsByDate(
        _selectedReceiptDateFilter,
        receipts: nextReceipts,
      );
      _selectedReceiptId =
          filteredReceipts.any((entry) => entry.id == receipt.id)
          ? receipt.id
          : _resolveReceiptSelection(
              _selectedReceiptId,
              receipts: filteredReceipts,
            );
      _selectedInventoryItemId = _resolveInventoryItemSelection(
        _selectedInventoryItemId,
      );
      _cartItems = [];
      _nextReceiptId = receiptId + 1;
    });

    return null;
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await _dataStore.loadSnapshot();
      if (!mounted) {
        return;
      }

      setState(() {
        _inventoryItems = snapshot.inventoryItems;
        _discounts = snapshot.discounts;
        _categories = snapshot.categories;
        _receipts = snapshot.receipts;
        _selectedReceiptDateFilter = _resolveReceiptDateFilter(
          _selectedReceiptDateFilter,
        );
        _selectedReceiptId = _resolveReceiptSelection(
          _selectedReceiptId,
          receipts: _filterReceiptsByDate(_selectedReceiptDateFilter),
        );
        _selectedInventoryItemId = _resolveInventoryItemSelection(
          _selectedInventoryItemId,
        );
        _selectedCategoryId = _resolveCategorySelection(_selectedCategoryId);
        _selectedSalesCategoryId = _resolveSalesSelection(
          _selectedSalesCategoryId,
        );
        _nextInventoryId = _nextIdForInventoryItems();
        _nextDiscountId = _nextIdForDiscounts();
        _nextCategoryId = _nextIdForCategories();
        _nextReceiptId = _nextIdForReceipts();
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _createInventoryItem() async {
    final item = await _showInventoryItemDialog();
    if (item == null) {
      return;
    }

    final created = item.copyWith(id: _nextInventoryId++);
    await _dataStore.insertInventoryItem(created);

    if (!mounted) {
      return;
    }

    setState(() {
      _inventoryItems = [..._inventoryItems, created];
      _selectedInventoryItemId = created.id;
    });
  }

  Future<void> _editInventoryItem(InventoryItem item) async {
    final updated = await _showInventoryItemDialog(item: item);
    if (updated == null) {
      return;
    }

    final saved = updated.copyWith(id: item.id);
    await _dataStore.updateInventoryItem(saved);

    if (!mounted) {
      return;
    }

    setState(() {
      _inventoryItems = _inventoryItems
          .map((entry) => entry.id == item.id ? saved : entry)
          .toList();
      _selectedInventoryItemId = saved.id;
    });
  }

  Future<void> _deleteInventoryItem(InventoryItem item) async {
    await _dataStore.deleteInventoryItem(item.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _inventoryItems = _inventoryItems
          .where((entry) => entry.id != item.id)
          .toList();
      if (_selectedInventoryItemId == item.id) {
        _selectedInventoryItemId = _resolveInventoryItemSelection(null);
      }
    });
  }

  Future<void> _createDiscount() async {
    final discount = await _showDiscountDialog();
    if (discount == null) {
      return;
    }

    final created = discount.copyWith(id: _nextDiscountId++);
    await _dataStore.insertDiscount(created);

    if (!mounted) {
      return;
    }

    setState(() {
      _discounts = [..._discounts, created];
    });
  }

  Future<void> _editDiscount(DiscountItem discount) async {
    final updated = await _showDiscountDialog(discount: discount);
    if (updated == null) {
      return;
    }

    final saved = updated.copyWith(id: discount.id);
    await _dataStore.updateDiscount(saved);

    if (!mounted) {
      return;
    }

    setState(() {
      _discounts = _discounts
          .map((entry) => entry.id == discount.id ? saved : entry)
          .toList();
    });
  }

  Future<void> _deleteDiscount(DiscountItem discount) async {
    await _dataStore.deleteDiscount(discount.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _discounts = _discounts
          .where((entry) => entry.id != discount.id)
          .toList();
    });
  }

  Future<void> _createCategory() async {
    final category = await _showCategoryDialog();
    if (category == null) {
      return;
    }

    final created = category.copyWith(id: _nextCategoryId++);
    await _dataStore.insertCategory(created);

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = [..._categories, created];
      _selectedCategoryId = created.id;
    });
  }

  Future<void> _editCategory(CategoryItem category) async {
    if (category.isProtected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${category.name} is a protected category and cannot be edited.',
          ),
        ),
      );
      return;
    }

    final updated = await _showCategoryDialog(category: category);
    if (updated == null) {
      return;
    }

    final saved = updated.copyWith(id: category.id);
    await _dataStore.updateCategory(saved, previousName: category.name);

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = _categories
          .map((entry) => entry.id == category.id ? saved : entry)
          .toList();
      _inventoryItems = _inventoryItems
          .map(
            (entry) => entry.category == category.name
                ? entry.copyWith(category: saved.name)
                : entry,
          )
          .toList();
      _selectedCategoryId = category.id;
    });
  }

  Future<void> _deleteCategory(CategoryItem category) async {
    if (category.isProtected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${category.name} is a protected category and cannot be deleted.',
          ),
        ),
      );
      return;
    }

    final linkedItems = _inventoryItems
        .where((entry) => entry.category == category.name)
        .length;

    if (linkedItems > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Remove or reassign the $linkedItems linked item(s) before deleting ${category.name}.',
          ),
        ),
      );
      return;
    }

    await _dataStore.deleteCategory(category.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _categories = _categories
          .where((entry) => entry.id != category.id)
          .toList();
      if (_selectedCategoryId == category.id) {
        _selectedCategoryId = _resolveCategorySelection(null);
      }
      if (_selectedSalesCategoryId == category.id) {
        _selectedSalesCategoryId = null;
      }
    });
  }

  Future<InventoryItem?> _showInventoryItemDialog({InventoryItem? item}) async {
    final previewId = item?.id ?? _nextInventoryId;
    return showDialog<InventoryItem>(
      context: context,
      builder: (_) => _InventoryItemDialog(
        item: item,
        categories: _categories,
        previewId: previewId,
        imagePicker: _inventoryImagePicker,
      ),
    );
  }

  Future<CategoryItem?> _showCategoryDialog({CategoryItem? category}) async {
    return showDialog<CategoryItem>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
  }

  Future<DiscountItem?> _showDiscountDialog({DiscountItem? discount}) async {
    return showDialog<DiscountItem>(
      context: context,
      builder: (_) => _DiscountDialog(discount: discount),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storage_outlined,
                  size: 44,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Could not load local database.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _loadError = null;
                    });
                    _loadData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDashboardSection = _selectedSection == 'dashboard';
    final isSalesSection = _selectedSection == 'sales';
    final isReceiptsSection = _selectedSection == 'receipts';
    final isCombinedReceiptsSection = _selectedSection == 'combined_receipts';
    final isMengStoreReceiptsSection =
        _selectedSection == 'meng_store_receipts';
    final isCategoriesSection = _selectedSection == 'categories';
    final isDiscountsSection = _selectedSection == 'discounts';
    final selectedInventoryItem = _inventoryItems
        .cast<InventoryItem?>()
        .firstWhere(
          (item) => item?.id == _selectedInventoryItemId,
          orElse: () => _inventoryItems.isEmpty ? null : _inventoryItems.first,
        );
    final selectedCategory = _categories.cast<CategoryItem?>().firstWhere(
      (category) => category?.id == _selectedCategoryId,
      orElse: () => _categories.isEmpty ? null : _categories.first,
    );
    final selectedSalesCategory = _categories.cast<CategoryItem?>().firstWhere(
      (category) => category?.id == _selectedSalesCategoryId,
      orElse: () => null,
    );
    final combinedReceipts = _combinedReceipts();
    final combinedReceiptDateFilter = _resolveReceiptDateFilter(
      _selectedReceiptDateFilter,
      receipts: combinedReceipts,
    );
    final filteredCombinedReceipts = _filterReceiptsByDate(
      combinedReceiptDateFilter,
      receipts: combinedReceipts,
    );
    final availableCombinedReceiptDates = _availableReceiptDates(
      receipts: combinedReceipts,
    );
    final selectedCombinedReceipt = filteredCombinedReceipts
        .cast<ReceiptItem?>()
        .firstWhere(
          (receipt) => receipt?.id == _selectedReceiptId,
          orElse: () => filteredCombinedReceipts.isEmpty
              ? null
              : filteredCombinedReceipts.first,
        );
    final generalReceipts = _generalReceipts();
    final generalReceiptDateFilter = _resolveReceiptDateFilter(
      _selectedReceiptDateFilter,
      receipts: generalReceipts,
    );
    final filteredReceipts = _filterReceiptsByDate(
      generalReceiptDateFilter,
      receipts: generalReceipts,
    );
    final availableReceiptDates = _availableReceiptDates(
      receipts: generalReceipts,
    );
    final selectedReceipt = filteredReceipts.cast<ReceiptItem?>().firstWhere(
      (receipt) => receipt?.id == _selectedReceiptId,
      orElse: () => filteredReceipts.isEmpty ? null : filteredReceipts.first,
    );
    final mengStoreReceipts = _mengStoreReceipts();
    final mengStoreReceiptDateFilter = _resolveReceiptDateFilter(
      _selectedReceiptDateFilter,
      receipts: mengStoreReceipts,
    );
    final filteredMengStoreReceipts = _filterReceiptsByDate(
      mengStoreReceiptDateFilter,
      receipts: mengStoreReceipts,
    );
    final availableMengStoreReceiptDates = _availableReceiptDates(
      receipts: mengStoreReceipts,
    );
    final selectedMengStoreReceipt = filteredMengStoreReceipts
        .cast<ReceiptItem?>()
        .firstWhere(
          (receipt) => receipt?.id == _selectedReceiptId,
          orElse: () => filteredMengStoreReceipts.isEmpty
              ? null
              : filteredMengStoreReceipts.first,
        );
    final salesSearchText = _salesSearchQuery.toLowerCase();
    final validCategoryNames = _categories
        .map((category) => category.name)
        .toSet();
    final filteredCatalogItems = _inventoryItems
        .where((item) => validCategoryNames.contains(item.category))
        .where(
          (item) => selectedSalesCategory == null
              ? _isVisibleInAllSales(item)
              : item.category == selectedSalesCategory.name,
        )
        .map(
          (item) => CatalogItem(
            id: item.id,
            name: item.name,
            category: item.category,
            price: item.sellingPrice,
            imageUrl: _catalogImageUrlForInventoryItem(item),
            imagePath: item.imagePath.isEmpty ? null : item.imagePath,
            representation: item.representation,
            displayColor: item.displayColor,
            displayShape: item.displayShape,
          ),
        )
        .where(
          (item) =>
              salesSearchText.isEmpty ||
              item.name.toLowerCase().contains(salesSearchText) ||
              item.category.toLowerCase().contains(salesSearchText),
        )
        .toList();
    final isItemsInfoSection = _selectedSection == 'items';
    final isInventoryCrudSection = _selectedSection == 'inventory';
    final isInventoryWorkflowSection =
        _selectedSection == 'purchase_order' ||
        _selectedSection == 'stock_adjustment' ||
        _selectedSection == 'inventory_count' ||
        _selectedSection == 'inventory_history';
    final isItemsSection = isItemsInfoSection || isInventoryCrudSection;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (!isWide) {
              return Column(
                children: [
                  AppTopBar(
                    title: sectionLabelFor(_selectedSection),
                    onMenuTap: _toggleSidebar,
                    searchController: isSalesSection
                        ? _salesSearchController
                        : null,
                    onSearchChanged: isSalesSection
                        ? _updateSalesSearchQuery
                        : null,
                    searchHintText: 'Search sales items',
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (isDashboardSection)
                          DashboardPanel(
                            inventoryItems: _inventoryItems,
                            categories: _categories,
                            discounts: _discounts,
                            receipts: _receipts,
                            isEmbedded: true,
                          )
                        else if (isReceiptsSection)
                          ReceiptsPanel(
                            receipts: filteredReceipts,
                            availableDates: availableReceiptDates,
                            selectedDateFilter: generalReceiptDateFilter,
                            onDateFilterChanged: _updateReceiptDateFilter,
                            selectedReceiptId: _selectedReceiptId,
                            onSelect: _selectReceipt,
                            isEmbedded: true,
                          )
                        else if (isCombinedReceiptsSection)
                          ReceiptsPanel(
                            receipts: filteredCombinedReceipts,
                            availableDates: availableCombinedReceiptDates,
                            selectedDateFilter: combinedReceiptDateFilter,
                            onDateFilterChanged: _updateReceiptDateFilter,
                            selectedReceiptId: _selectedReceiptId,
                            onSelect: _selectReceipt,
                            isEmbedded: true,
                            title: 'Combined Receipts',
                            description:
                                "Shows full receipt totals from General Receipt and Meng's Store purchases.",
                          )
                        else if (isMengStoreReceiptsSection)
                          MengStoreReceiptsPanel(
                            receipts: filteredMengStoreReceipts,
                            availableDates: availableMengStoreReceiptDates,
                            selectedDateFilter: mengStoreReceiptDateFilter,
                            onDateFilterChanged: _updateReceiptDateFilter,
                            selectedReceiptId: _selectedReceiptId,
                            onSelect: _selectReceipt,
                            isEmbedded: true,
                          )
                        else if (isCategoriesSection)
                          CategoriesPanel(
                            categories: _categories,
                            inventoryItems: _inventoryItems,
                            selectedCategoryId: _selectedCategoryId,
                            onSelect: _selectCategory,
                            isEmbedded: true,
                            onAdd: _createCategory,
                            onEdit: _editCategory,
                            onDelete: _deleteCategory,
                          )
                        else if (isDiscountsSection)
                          DiscountsPanel(
                            discounts: _discounts,
                            isEmbedded: true,
                            onAdd: _createDiscount,
                            onEdit: _editDiscount,
                            onDelete: _deleteDiscount,
                          )
                        else if (isItemsInfoSection)
                          InventoryItemsPanel(
                            items: _inventoryItems,
                            selectedItemId: _selectedInventoryItemId,
                            onSelect: _selectInventoryItem,
                            isEmbedded: true,
                            onAdd: _createInventoryItem,
                            onEdit: _editInventoryItem,
                            onDelete: _deleteInventoryItem,
                            title: 'Items Information',
                            isManagementEnabled: false,
                          )
                        else if (isInventoryCrudSection)
                          InventoryItemsPanel(
                            items: _inventoryItems,
                            selectedItemId: _selectedInventoryItemId,
                            onSelect: _selectInventoryItem,
                            isEmbedded: true,
                            onAdd: _createInventoryItem,
                            onEdit: _editInventoryItem,
                            onDelete: _deleteInventoryItem,
                          )
                        else if (isInventoryWorkflowSection)
                          InventoryWorkflowPanel(
                            workflowId: _selectedSection,
                            inventoryItems: _inventoryItems,
                            isEmbedded: true,
                          )
                        else
                          ProductPanel(
                            items: filteredCatalogItems,
                            onItemTap: _addSalesItemToTicket,
                            activeCategoryName: selectedSalesCategory?.name,
                            isEmbedded: true,
                          ),
                        if (!isDiscountsSection &&
                            !isDashboardSection &&
                            !isInventoryWorkflowSection) ...[
                          const Divider(height: 1),
                          if (isReceiptsSection)
                            ReceiptSummaryPanel(
                              selectedReceipt: selectedReceipt,
                              isEmbedded: true,
                            )
                          else if (isCombinedReceiptsSection)
                            ReceiptSummaryPanel(
                              selectedReceipt: selectedCombinedReceipt,
                              isEmbedded: true,
                            )
                          else if (isMengStoreReceiptsSection)
                            ReceiptSummaryPanel(
                              selectedReceipt: selectedMengStoreReceipt,
                              isEmbedded: true,
                            )
                          else if (isCategoriesSection)
                            CategorySummaryPanel(
                              categories: _categories,
                              inventoryItems: _inventoryItems,
                              selectedCategory: selectedCategory,
                              isEmbedded: true,
                            )
                          else if (isItemsSection)
                            ItemSummaryPanel(
                              selectedItem: selectedInventoryItem,
                              isEmbedded: true,
                            )
                          else
                            TicketPanel(
                              cart: _cartItems,
                              onClear: _clearTicket,
                              onRemoveItem: _removeSalesItemFromTicket,
                              onCharge: _chargeTicket,
                              isEmbedded: true,
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (isSalesSection)
                    BottomTabs(
                      categories: _categories,
                      selectedCategoryId: _selectedSalesCategoryId,
                      onAllTap: _showAllSalesItems,
                      onCategoryTap: _selectSalesCategory,
                    ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (_isSidebarOpen)
                        AppSidebar(
                          selectedItem: _selectedSection,
                          onItemTap: _selectSection,
                        ),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            AppTopBar(
                              title: sectionLabelFor(_selectedSection),
                              onMenuTap: _toggleSidebar,
                              searchController: isSalesSection
                                  ? _salesSearchController
                                  : null,
                              onSearchChanged: isSalesSection
                                  ? _updateSalesSearchQuery
                                  : null,
                              searchHintText: 'Search sales items',
                            ),
                            Expanded(
                              child: isDashboardSection
                                  ? DashboardPanel(
                                      inventoryItems: _inventoryItems,
                                      categories: _categories,
                                      discounts: _discounts,
                                      receipts: _receipts,
                                    )
                                  : isReceiptsSection
                                  ? ReceiptsPanel(
                                      receipts: filteredReceipts,
                                      availableDates: availableReceiptDates,
                                      selectedDateFilter:
                                          generalReceiptDateFilter,
                                      onDateFilterChanged:
                                          _updateReceiptDateFilter,
                                      selectedReceiptId: _selectedReceiptId,
                                      onSelect: _selectReceipt,
                                    )
                                  : isCombinedReceiptsSection
                                  ? ReceiptsPanel(
                                      receipts: filteredCombinedReceipts,
                                      availableDates:
                                          availableCombinedReceiptDates,
                                      selectedDateFilter:
                                          combinedReceiptDateFilter,
                                      onDateFilterChanged:
                                          _updateReceiptDateFilter,
                                      selectedReceiptId: _selectedReceiptId,
                                      onSelect: _selectReceipt,
                                      title: 'Combined Receipts',
                                      description:
                                          "Shows full receipt totals from General Receipt and Meng's Store purchases.",
                                    )
                                  : isMengStoreReceiptsSection
                                  ? MengStoreReceiptsPanel(
                                      receipts: filteredMengStoreReceipts,
                                      availableDates:
                                          availableMengStoreReceiptDates,
                                      selectedDateFilter:
                                          mengStoreReceiptDateFilter,
                                      onDateFilterChanged:
                                          _updateReceiptDateFilter,
                                      selectedReceiptId: _selectedReceiptId,
                                      onSelect: _selectReceipt,
                                    )
                                  : isCategoriesSection
                                  ? CategoriesPanel(
                                      categories: _categories,
                                      inventoryItems: _inventoryItems,
                                      selectedCategoryId: _selectedCategoryId,
                                      onSelect: _selectCategory,
                                      onAdd: _createCategory,
                                      onEdit: _editCategory,
                                      onDelete: _deleteCategory,
                                    )
                                  : isDiscountsSection
                                  ? DiscountsPanel(
                                      discounts: _discounts,
                                      onAdd: _createDiscount,
                                      onEdit: _editDiscount,
                                      onDelete: _deleteDiscount,
                                    )
                                  : isItemsInfoSection
                                  ? InventoryItemsPanel(
                                      items: _inventoryItems,
                                      selectedItemId: _selectedInventoryItemId,
                                      onSelect: _selectInventoryItem,
                                      onAdd: _createInventoryItem,
                                      onEdit: _editInventoryItem,
                                      onDelete: _deleteInventoryItem,
                                      title: 'Items Information',
                                      isManagementEnabled: false,
                                    )
                                  : isInventoryCrudSection
                                  ? InventoryItemsPanel(
                                      items: _inventoryItems,
                                      selectedItemId: _selectedInventoryItemId,
                                      onSelect: _selectInventoryItem,
                                      onAdd: _createInventoryItem,
                                      onEdit: _editInventoryItem,
                                      onDelete: _deleteInventoryItem,
                                    )
                                  : isInventoryWorkflowSection
                                  ? InventoryWorkflowPanel(
                                      workflowId: _selectedSection,
                                      inventoryItems: _inventoryItems,
                                    )
                                  : ProductPanel(
                                      items: filteredCatalogItems,
                                      onItemTap: _addSalesItemToTicket,
                                      activeCategoryName:
                                          selectedSalesCategory?.name,
                                    ),
                            ),
                            if (isSalesSection)
                              BottomTabs(
                                categories: _categories,
                                selectedCategoryId: _selectedSalesCategoryId,
                                onAllTap: _showAllSalesItems,
                                onCategoryTap: _selectSalesCategory,
                              ),
                          ],
                        ),
                      ),
                      if (!isDiscountsSection &&
                          !isDashboardSection &&
                          !isInventoryWorkflowSection) ...[
                        const VerticalDivider(width: 1),
                        Expanded(
                          flex: 3,
                          child: isReceiptsSection
                              ? ReceiptSummaryPanel(
                                  selectedReceipt: selectedReceipt,
                                )
                              : isCombinedReceiptsSection
                              ? ReceiptSummaryPanel(
                                  selectedReceipt: selectedCombinedReceipt,
                                )
                              : isMengStoreReceiptsSection
                              ? ReceiptSummaryPanel(
                                  selectedReceipt: selectedMengStoreReceipt,
                                )
                              : isCategoriesSection
                              ? CategorySummaryPanel(
                                  categories: _categories,
                                  inventoryItems: _inventoryItems,
                                  selectedCategory: selectedCategory,
                                )
                              : isItemsSection
                              ? ItemSummaryPanel(
                                  selectedItem: selectedInventoryItem,
                                )
                              : TicketPanel(
                                  cart: _cartItems,
                                  onClear: _clearTicket,
                                  onRemoveItem: _removeSalesItemFromTicket,
                                  onCharge: _chargeTicket,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int? _resolveCategorySelection(int? preferredId) {
    if (_categories.isEmpty) {
      return null;
    }
    if (preferredId != null &&
        _categories.any((category) => category.id == preferredId)) {
      return preferredId;
    }
    return _categories.first.id;
  }

  int? _resolveSalesSelection(int? preferredId) {
    if (preferredId == null) {
      return null;
    }
    return _categories.any((category) => category.id == preferredId)
        ? preferredId
        : null;
  }

  int? _resolveInventoryItemSelection(int? preferredId) {
    if (_inventoryItems.isEmpty) {
      return null;
    }
    if (preferredId != null &&
        _inventoryItems.any((item) => item.id == preferredId)) {
      return preferredId;
    }
    return _inventoryItems.first.id;
  }

  int _nextIdForInventoryItems() {
    final maxId = _inventoryItems.fold<int>(0, (maxId, item) {
      return item.id > maxId ? item.id : maxId;
    });
    return maxId + 1;
  }

  int _nextIdForCategories() {
    final maxId = _categories.fold<int>(0, (maxId, category) {
      return category.id > maxId ? category.id : maxId;
    });
    return maxId + 1;
  }

  int _nextIdForDiscounts() {
    final maxId = _discounts.fold<int>(0, (maxId, discount) {
      return discount.id > maxId ? discount.id : maxId;
    });
    return maxId + 1;
  }

  int _nextIdForReceipts() {
    final maxId = _receipts.fold<int>(1041, (maxId, receipt) {
      return receipt.id > maxId ? receipt.id : maxId;
    });
    return maxId + 1;
  }

  String _storageDateString(DateTime value) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    return dateOnly.toIso8601String().split('T').first;
  }

  String? _catalogImageUrlForInventoryItem(InventoryItem item) {
    if (item.representation != InventoryRepresentation.image) {
      return null;
    }

    final exactMatch = catalogItems.cast<CatalogItem?>().firstWhere(
      (entry) => entry?.name == item.name && entry?.imageUrl != null,
      orElse: () => null,
    );
    if (exactMatch?.imageUrl != null) {
      return exactMatch!.imageUrl;
    }

    final categoryMatch = catalogItems.cast<CatalogItem?>().firstWhere(
      (entry) => entry?.category == item.category && entry?.imageUrl != null,
      orElse: () => null,
    );
    return categoryMatch?.imageUrl;
  }

  List<ReceiptItem> _combinedReceipts({List<ReceiptItem>? receipts}) {
    final source = receipts ?? _receipts;

    return source
        .map((receipt) => receipt.copyWith(storeName: 'Combined Receipt'))
        .toList();
  }

  List<ReceiptItem> _generalReceipts({List<ReceiptItem>? receipts}) {
    final source = receipts ?? _receipts;

    return source
        .map((receipt) {
          final filteredItems = receipt.purchasedItems
              .where((item) => item.category != protectedCategoryName)
              .toList();

          if (filteredItems.isEmpty) {
            return null;
          }

          return receipt.copyWith(
            purchasedItems: filteredItems,
            items: filteredItems.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            ),
            total: filteredItems.fold<double>(
              0,
              (sum, item) => sum + item.lineTotal,
            ),
            storeName: 'General Receipt',
          );
        })
        .whereType<ReceiptItem>()
        .toList();
  }

  List<ReceiptItem> _mengStoreReceipts({List<ReceiptItem>? receipts}) {
    final source = receipts ?? _receipts;

    return source
        .map((receipt) {
          final filteredItems = receipt.purchasedItems
              .where((item) => item.category == protectedCategoryName)
              .toList();

          if (filteredItems.isEmpty) {
            return null;
          }

          return receipt.copyWith(
            purchasedItems: filteredItems,
            items: filteredItems.fold<int>(
              0,
              (sum, item) => sum + item.quantity,
            ),
            total: filteredItems.fold<double>(
              0,
              (sum, item) => sum + item.lineTotal,
            ),
            storeName: protectedCategoryName,
          );
        })
        .whereType<ReceiptItem>()
        .toList();
  }

  List<ReceiptItem> _filterReceiptsByDate(
    String? date, {
    List<ReceiptItem>? receipts,
  }) {
    final source = receipts ?? _receipts;
    if (date == null) {
      return source;
    }
    return source.where((receipt) => receipt.date == date).toList();
  }

  List<String> _availableReceiptDates({List<ReceiptItem>? receipts}) {
    final source = receipts ?? _receipts;
    final dates = source.map((receipt) => receipt.date).toSet().toList();
    dates.sort((left, right) => right.compareTo(left));
    return dates;
  }

  String? _resolveReceiptDateFilter(
    String? preferredDate, {
    List<ReceiptItem>? receipts,
  }) {
    if (preferredDate == null) {
      return null;
    }

    final source = receipts ?? _receipts;
    return source.any((receipt) => receipt.date == preferredDate)
        ? preferredDate
        : null;
  }

  int? _resolveReceiptSelection(
    int? preferredId, {
    List<ReceiptItem>? receipts,
  }) {
    final source = receipts ?? _receipts;
    if (source.isEmpty) {
      return null;
    }
    if (preferredId != null &&
        source.any((receipt) => receipt.id == preferredId)) {
      return preferredId;
    }
    return source.first.id;
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final CategoryItem? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late Color _selectedColor;
  String? _errorText;

  static const List<Color> _colorOptions = [
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFFF4511E),
    Color(0xFFE53935),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? _colorOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Category name is required.';
      });
      return;
    }

    Navigator.of(context).pop(
      CategoryItem(
        id: widget.category?.id ?? -1,
        name: name,
        colorValue: _selectedColor.toARGB32(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions
                  .map(
                    (color) => GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.black87
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.category == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _InventoryItemDialog extends StatefulWidget {
  const _InventoryItemDialog({
    required this.categories,
    required this.previewId,
    required this.imagePicker,
    this.item,
  });

  final InventoryItem? item;
  final List<CategoryItem> categories;
  final int previewId;
  final InventoryImagePicker imagePicker;

  @override
  State<_InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<_InventoryItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _skuController;
  late final TextEditingController _stockController;
  late final TextEditingController _reorderController;
  late final TextEditingController _costController;
  late String _selectedCategory;
  late final String _lockedSku;
  late InventoryRepresentation _selectedRepresentation;
  late int _selectedDisplayColorValue;
  late InventoryDisplayShape _selectedDisplayShape;
  late String _selectedImagePath;
  bool _isPickingImage = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(
      text: widget.item == null
          ? ''
          : widget.item!.sellingPrice.toStringAsFixed(2),
    );
    _stockController = TextEditingController(
      text: widget.item == null ? '' : '${widget.item!.stock}',
    );
    _reorderController = TextEditingController(
      text: widget.item == null ? '' : '${widget.item!.reorderLevel}',
    );
    _costController = TextEditingController(
      text: widget.item == null ? '' : widget.item!.unitCost.toStringAsFixed(2),
    );
    _selectedCategory =
        widget.item?.category ??
        (widget.categories.isNotEmpty ? widget.categories.first.name : '');
    _lockedSku = widget.item?.resolvedSku ?? '';
    _skuController = TextEditingController(text: _currentSku);
    _selectedRepresentation =
        widget.item?.representation ?? InventoryRepresentation.colorAndShape;
    _selectedDisplayColorValue =
        widget.item?.resolvedDisplayColorValue ??
        defaultInventoryDisplayColorValue(
          widget.item?.name ?? _selectedCategory,
        );
    _selectedDisplayShape =
        widget.item?.displayShape ?? InventoryDisplayShape.roundedSquare;
    _selectedImagePath = widget.item?.imagePath ?? '';
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _priceController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _reorderController.dispose();
    _costController.dispose();
    super.dispose();
  }

  String get _currentSku {
    if (_lockedSku.isNotEmpty) {
      return _lockedSku;
    }

    return generateInventorySku(
      id: widget.previewId,
      name: _nameController.text.trim(),
      category: _selectedCategory,
    );
  }

  void _handleNameChanged() {
    _refreshSkuPreview();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshSkuPreview() {
    final nextValue = _currentSku;
    if (_skuController.text == nextValue) {
      return;
    }
    _skuController.value = _skuController.value.copyWith(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  Future<void> _pickImage() async {
    setState(() {
      _isPickingImage = true;
      _errorText = null;
    });

    try {
      final savedImagePath = await widget.imagePicker.pickAndSaveImage(
        sku: _currentSku,
      );
      if (!mounted || savedImagePath == null) {
        return;
      }

      setState(() {
        _selectedImagePath = savedImagePath;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Unable to upload and save the image right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _save() {
    if (widget.categories.isEmpty) {
      setState(() {
        _errorText = 'Add a category first before saving an item.';
      });
      return;
    }

    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    final reorder = int.tryParse(_reorderController.text.trim());
    final cost = double.tryParse(_costController.text.trim());

    if (name.isEmpty ||
        _selectedCategory.isEmpty ||
        price == null ||
        stock == null ||
        reorder == null ||
        cost == null) {
      setState(() {
        _errorText = 'Please complete all fields with valid values.';
      });
      return;
    }

    if (_selectedRepresentation == InventoryRepresentation.image &&
        _selectedImagePath.isEmpty) {
      setState(() {
        _errorText = 'Upload an image before saving an item in Image mode.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      InventoryItem(
        id: widget.item?.id ?? -1,
        name: name,
        category: _selectedCategory,
        stock: stock,
        reorderLevel: reorder,
        unitCost: cost,
        price: price,
        sku: _currentSku,
        representation: _selectedRepresentation,
        displayColorValue: _selectedDisplayColorValue,
        displayShape: _selectedDisplayShape,
        imagePath: _selectedImagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Add Inventory Item' : 'Edit Inventory Item',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                onSubmitted: (_) => _save(),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedCategory),
                initialValue: _selectedCategory.isEmpty
                    ? null
                    : _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category.name,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? '';
                    _refreshSkuPreview();
                  });
                },
              ),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price'),
                onSubmitted: (_) => _save(),
              ),
              TextField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Cost'),
                onSubmitted: (_) => _save(),
              ),
              TextField(
                controller: _skuController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'SKU (Auto Generated)',
                ),
              ),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'In Stock'),
                onSubmitted: (_) => _save(),
              ),
              TextField(
                controller: _reorderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Low Stock'),
                onSubmitted: (_) => _save(),
              ),
              DropdownButtonFormField<InventoryRepresentation>(
                initialValue: _selectedRepresentation,
                decoration: const InputDecoration(
                  labelText: 'Representation On Screen',
                ),
                items: InventoryRepresentation.values
                    .map(
                      (representation) =>
                          DropdownMenuItem<InventoryRepresentation>(
                            value: representation,
                            child: Text(representation.label),
                          ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRepresentation =
                        value ?? InventoryRepresentation.colorAndShape;
                  });
                },
              ),
              const SizedBox(height: 16),
              _InventoryRepresentationPreview(
                representation: _selectedRepresentation,
                color: Color(_selectedDisplayColorValue),
                shape: _selectedDisplayShape,
                imagePath: _selectedImagePath,
                label: _nameController.text.trim().isEmpty
                    ? 'Item Preview'
                    : _nameController.text.trim(),
              ),
              const SizedBox(height: 16),
              if (_selectedRepresentation ==
                  InventoryRepresentation.colorAndShape) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Color',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: inventoryDisplayColorChoices
                      .map(
                        (colorValue) => InkWell(
                          key: ValueKey('display-color-$colorValue'),
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() {
                              _selectedDisplayColorValue = colorValue;
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(colorValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedDisplayColorValue == colorValue
                                    ? Colors.black87
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Shape',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: InventoryDisplayShape.values
                      .map(
                        (shape) => _ShapeChoiceCard(
                          key: ValueKey('display-shape-${shape.databaseValue}'),
                          shape: shape,
                          color: Color(_selectedDisplayColorValue),
                          isSelected: _selectedDisplayShape == shape,
                          onTap: () {
                            setState(() {
                              _selectedDisplayShape = shape;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _isPickingImage ? null : _pickImage,
                        icon: _isPickingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_outlined),
                        label: Text(
                          _selectedImagePath.isEmpty
                              ? 'Upload Image'
                              : 'Replace Image',
                        ),
                      ),
                      if (_selectedImagePath.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.basename(_selectedImagePath),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'The selected image will be saved in app storage and shown in Sales.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.item == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class _InventoryRepresentationPreview extends StatelessWidget {
  const _InventoryRepresentationPreview({
    required this.representation,
    required this.color,
    required this.shape,
    required this.imagePath,
    required this.label,
  });

  final InventoryRepresentation representation;
  final Color color;
  final InventoryDisplayShape shape;
  final String imagePath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EADF)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Center(
              child: representation == InventoryRepresentation.image
                  ? _ImagePreviewCard(imagePath: imagePath)
                  : _InventoryShapeSwatch(
                      shape: shape,
                      color: color,
                      size: 88,
                      iconSize: 34,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ShapeChoiceCard extends StatelessWidget {
  const _ShapeChoiceCard({
    super.key,
    required this.shape,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final InventoryDisplayShape shape;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 108,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE4EADF),
            ),
          ),
          child: Column(
            children: [
              _InventoryShapeSwatch(
                shape: shape,
                color: color,
                size: 52,
                iconSize: 18,
              ),
              const SizedBox(height: 10),
              Text(
                shape.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 140,
        height: 96,
        color: const Color(0xFFE9EEF3),
        child: imagePath.isEmpty
            ? const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 36,
                  color: Colors.black45,
                ),
              )
            : Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 36,
                    color: Colors.black45,
                  ),
                ),
              ),
      ),
    );
  }
}

class _InventoryShapeSwatch extends StatelessWidget {
  const _InventoryShapeSwatch({
    required this.shape,
    required this.color,
    required this.size,
    required this.iconSize,
  });

  final InventoryDisplayShape shape;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case InventoryDisplayShape.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(Icons.pets, color: Colors.white, size: iconSize),
        );
      case InventoryDisplayShape.diamond:
        return Transform.rotate(
          angle: 0.78539816339,
          child: Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.78539816339,
                child: Icon(Icons.pets, color: Colors.white, size: iconSize),
              ),
            ),
          ),
        );
      case InventoryDisplayShape.capsule:
        return Container(
          width: size * 1.25,
          height: size * 0.68,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(Icons.pets, color: Colors.white, size: iconSize),
        );
      case InventoryDisplayShape.roundedSquare:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(Icons.pets, color: Colors.white, size: iconSize),
        );
    }
  }
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({this.discount});

  final DiscountItem? discount;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late DiscountType _selectedType;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.discount?.name ?? '');
    _valueController = TextEditingController(
      text: widget.discount == null
          ? ''
          : widget.discount!.value.toStringAsFixed(2),
    );
    _selectedType = widget.discount?.type ?? DiscountType.percentage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text.trim());

    if (name.isEmpty || value == null || value <= 0) {
      setState(() {
        _errorText = 'Please provide a name and a valid discount value.';
      });
      return;
    }

    if (_selectedType == DiscountType.percentage && value > 100) {
      setState(() {
        _errorText = 'Percentage discounts must be between 0 and 100.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      DiscountItem(
        id: widget.discount?.id ?? -1,
        name: name,
        type: _selectedType,
        value: value,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueLabel = _selectedType == DiscountType.percentage
        ? 'Discount percentage'
        : 'Exact amount';

    return AlertDialog(
      title: Text(widget.discount == null ? 'Add Discount' : 'Edit Discount'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Discount name'),
                onSubmitted: (_) => _save(),
              ),
              DropdownButtonFormField<DiscountType>(
                key: ValueKey(_selectedType),
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Discount type'),
                items: DiscountType.values
                    .map(
                      (type) => DropdownMenuItem<DiscountType>(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? DiscountType.percentage;
                  });
                },
              ),
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: valueLabel,
                  helperText: _selectedType == DiscountType.percentage
                      ? 'Enter a value from 0 to 100.'
                      : 'Enter the currency amount to deduct.',
                ),
                onSubmitted: (_) => _save(),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.discount == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
