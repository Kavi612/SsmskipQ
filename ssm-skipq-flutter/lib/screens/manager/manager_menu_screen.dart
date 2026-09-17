import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../services/menu_service.dart';
import '../../utils/category_icons.dart';

class ManagerMenuScreen extends StatefulWidget {
  const ManagerMenuScreen({super.key, required this.menuService});

  final MenuService menuService;

  @override
  State<ManagerMenuScreen> createState() => _ManagerMenuScreenState();
}

class _ManagerMenuScreenState extends State<ManagerMenuScreen> {
  List<Category> _categories = [];
  List<MenuItem> _items = [];
  bool _loading = true;
  String? _error;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String? _categoryId;
  bool _isVeg = true;
  XFile? _pickedImage;
  bool _formLoading = false;
  static const _categoryIcons = CategoryIcons.byKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.menuService.fetchManagerMenu();
      _categories = data.categories;
      _items = data.items;
      _categoryId ??= _categories.isNotEmpty ? _categories.first.id : null;
    } catch (_) {
      _error = 'Unable to load menu.';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createItem() async {
    if (_categoryId == null) return;
    if (_categories.isEmpty) {
      setState(() => _error = 'Please create a category before adding menu items.');
      return;
    }
    setState(() => _formLoading = true);
    try {
      final form = FormData.fromMap({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': _priceController.text.trim(),
        'categoryId': _categoryId,
        'isVeg': _isVeg.toString(),
        if (_pickedImage != null)
          'image': await MultipartFile.fromFile(_pickedImage!.path),
      });
      final item = await widget.menuService.createMenuItem(form);
      setState(() {
        _items = [..._items, item]..sort((a, b) => a.name.compareTo(b.name));
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        _pickedImage = null;
      });
    } catch (_) {
      setState(() => _error = 'Unable to create menu item.');
    } finally {
      setState(() => _formLoading = false);
    }
  }

  List<MenuItem> get _visibleItems {
    if (_categoryId == null) return _items;
    return _items.where((item) => item.categoryId == _categoryId).toList();
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final orderController = TextEditingController(
      text: '${category?.sortOrder ?? _categories.length}',
    );
    var icon = category?.icon ?? 'restaurant';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: 'Display order'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: const InputDecoration(labelText: 'Icon'),
                items: _categoryIcons.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => icon = value);
                },
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final sortOrder = int.tryParse(orderController.text) ?? 0;
                if (name.isEmpty) return;
                try {
                  final updated = category == null
                      ? await widget.menuService.createCategory(
                          name: name, icon: icon, sortOrder: sortOrder)
                      : await widget.menuService.updateCategory(
                          category.id,
                          name: name,
                          icon: icon,
                          sortOrder: sortOrder,
                        );
                  if (!context.mounted) return;
                  setState(() {
                    _categories = category == null
                        ? [..._categories, updated]
                        : _categories
                            .map((item) =>
                                item.id == updated.id ? updated : item)
                            .toList();
                    _categories.sort((a, b) => a.sortOrder == b.sortOrder
                        ? a.name.compareTo(b.name)
                        : a.sortOrder.compareTo(b.sortOrder));
                    _categoryId ??= updated.id;
                  });
                  Navigator.pop(context, true);
                } catch (_) {
                  if (mounted) {
                    setState(() => _error = 'Unable to save category.');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    orderController.dispose();
    if (result == true && mounted) setState(() {});
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await widget.menuService.deleteCategory(category.id);
      setState(() {
        _categories.removeWhere((item) => item.id == category.id);
        if (_categoryId == category.id) {
          _categoryId = _categories.isNotEmpty ? _categories.first.id : null;
        }
      });
    } catch (_) {
      setState(
          () => _error = 'Move or delete this category\'s menu items first.');
    }
  }

  IconData _categoryIcon(String key) => CategoryIcons.resolve(key);

  Future<void> _openCategoryItems(Category category) async {
    setState(() => _categoryId = category.id);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryItemsPage(
          category: category,
          items: _items.where((item) => item.categoryId == category.id).toList(),
          onAddItem: () => _showAddItemDialog(category),
          onUpdatePrice: (item, price) => _updatePrice(item, price),
          onToggleAvailability: _toggleAvailability,
          onEditCategory: () => _showCategoryDialog(category: category),
          onDeleteCategory: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete Category?'),
                content: Text('Delete ${category.name}? Menu items must be moved or deleted first.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await _deleteCategory(category);
              if (mounted) Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<MenuItem?> _showAddItemDialog(Category category) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    var isVeg = true;
    try {
      return await showDialog<MenuItem>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Add Menu Item to ${category.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vegetarian'),
                    value: isVeg,
                    onChanged: (value) => setDialogState(() => isVeg = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = num.tryParse(priceController.text.trim());
                  if (name.isEmpty || price == null || price < 0) return;
                  try {
                    final item = await widget.menuService.createMenuItem(
                      FormData.fromMap({
                        'name': name,
                        'description': descriptionController.text.trim(),
                        'price': price,
                        'categoryId': category.id,
                        'isVeg': isVeg.toString(),
                      }),
                    );
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, item);
                    }
                    if (mounted) setState(() => _items = [..._items, item]);
                  } catch (_) {
                    if (mounted) setState(() => _error = 'Unable to create menu item.');
                  }
                },
                child: const Text('Add Item'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      priceController.dispose();
    }
  }

  Future<MenuItem?> _toggleAvailability(MenuItem item) async {
    try {
      final updated = await widget.menuService.toggleAvailability(item.id);
      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
      return updated;
    } catch (_) {
      setState(() => _error = 'Unable to toggle availability.');
      return null;
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    try {
      await widget.menuService.deleteMenuItem(item.id);
      setState(() => _items.removeWhere((e) => e.id == item.id));
    } catch (_) {
      setState(() => _error = 'Unable to delete item.');
    }
  }

  Future<void> _updatePrice(MenuItem item, String value) async {
    final price = num.tryParse(value);
    if (price == null || price < 0) return;
    try {
      final updated = await widget.menuService.updatePrice(item.id, price);
      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
    } catch (_) {
      setState(() => _error = 'Unable to update price.');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedImage = file);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Category Master',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Select a category to manage its menu items.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add New Category'),
          ),
          if (_categories.isEmpty)
            const Text('Create a category before adding menu items.')
          else
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = _categoryId == category.id;
                  return SizedBox(
                    width: 96,
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: selected ? AppTheme.primary : AppTheme.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openCategoryItems(category),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_categoryIcon(category.icon),
                                color: AppTheme.primary, size: 20),
                              const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Menu Item',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    _categoryId == null
                        ? 'Select a category above to add an item to it.'
                        : 'Adding to: ${_categories.firstWhere((category) => category.id == _categoryId).name}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    enabled: _categoryId != null && !_formLoading,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    enabled: _categoryId != null && !_formLoading,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
                    enabled: _categoryId != null && !_formLoading,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vegetarian'),
                    value: _isVeg,
                    onChanged: _categoryId == null || _formLoading
                        ? null
                        : (v) => setState(() => _isVeg = v),
                  ),
                  OutlinedButton.icon(
                    onPressed: _categoryId == null || _formLoading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_pickedImage == null ? 'Pick image' : 'Image selected'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _categoryId == null || _formLoading ? null : _createItem,
                      child: Text(_formLoading ? 'Saving…' : 'Add Item'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          const Text('Menu Items',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else
            ..._visibleItems.map((item) {
              final priceController =
                  TextEditingController(text: '${item.price}');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(item.imageUrl,
                                  width: 56, height: 56, fit: BoxFit.cover),
                            )
                          else
                            const Icon(Icons.restaurant, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(item.categoryName),
                                Text(item.isVeg ? 'Veg' : 'Non-Veg'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        onSubmitted: (v) => _updatePrice(item, v),
                      ),
                      Row(
                        children: [
                          Text(item.available ? 'Available' : 'Sold out'),
                          const Spacer(),
                          Switch(
                            value: item.available,
                            onChanged: (_) => _toggleAvailability(item),
                          ),
                          IconButton(
                            onPressed: () => _deleteItem(item),
                            icon: const Icon(Icons.delete_outline,
                                color: AppTheme.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CategoryItemsPage extends StatefulWidget {
  const _CategoryItemsPage({
    required this.category,
    required this.items,
    required this.onAddItem,
    required this.onUpdatePrice,
    required this.onToggleAvailability,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  final Category category;
  final List<MenuItem> items;
  final Future<MenuItem?> Function() onAddItem;
  final Future<void> Function(MenuItem item, String price) onUpdatePrice;
  final Future<MenuItem?> Function(MenuItem item) onToggleAvailability;
  final VoidCallback onEditCategory;
  final Future<void> Function() onDeleteCategory;

  @override
  State<_CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<_CategoryItemsPage> {
  late List<MenuItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_items.length} item${_items.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final item = await widget.onAddItem();
                  if (item != null && mounted) {
                    setState(() => _items = [..._items, item]);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No items in this category yet.'),
            )
          else
            ..._items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.name,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Text(item.isVeg ? 'Veg' : 'Non-Veg'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: '${item.price}'),
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        onSubmitted: (value) => widget.onUpdatePrice(item, value),
                      ),
                      Row(
                        children: [
                          Text(item.available ? 'Available' : 'Unavailable'),
                          const Spacer(),
                          Switch(
                            value: item.available,
                            onChanged: (_) async {
                              final updated =
                                  await widget.onToggleAvailability(item);
                              if (updated != null && mounted) {
                                setState(() {
                                  _items = _items
                                      .map((entry) => entry.id == updated.id
                                          ? updated
                                          : entry)
                                      .toList();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: widget.onEditCategory,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Category'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onDeleteCategory,
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            label: const Text('Delete Category'),
          ),
        ],
      ),
    );
  }
}
