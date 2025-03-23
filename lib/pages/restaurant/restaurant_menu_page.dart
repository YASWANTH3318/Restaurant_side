import 'package:flutter/material.dart';

class RestaurantMenuPage extends StatefulWidget {
  const RestaurantMenuPage({super.key});

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _menuItems = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Add dummy data
    _categories = [
      {'id': 'all', 'name': 'All'},
      {'id': 'appetizers', 'name': 'Appetizers'},
      {'id': 'main_courses', 'name': 'Main Courses'},
      {'id': 'desserts', 'name': 'Desserts'},
      {'id': 'beverages', 'name': 'Beverages'},
    ];

    _menuItems = [
      {
        'id': '1',
        'name': 'Caesar Salad',
        'description': 'Fresh romaine lettuce with Caesar dressing, croutons, and parmesan cheese',
        'price': 8.99,
        'category': 'appetizers',
        'image': 'https://picsum.photos//150',
        'isAvailable': true,
      },
      {
        'id': '2',
        'name': 'Grilled Salmon',
        'description': 'Grilled salmon with herbs, served with vegetables and mashed potatoes',
        'price': 18.99,
        'category': 'main_courses',
        'image': 'https://picsum.photos//150',
        'isAvailable': true,
      },
      {
        'id': '3',
        'name': 'Chocolate Cake',
        'description': 'Rich chocolate cake with a molten center',
        'price': 6.99,
        'category': 'desserts',
        'image': 'https://picsum.photos//150',
        'isAvailable': true,
      },
      {
        'id': '4',
        'name': 'Iced Tea',
        'description': 'Refreshing iced tea with lemon',
        'price': 2.99,
        'category': 'beverages',
        'image': 'https://picsum.photos//150',
        'isAvailable': false,
      },
    ];
  }

  List<Map<String, dynamic>> get filteredMenuItems {
    if (_selectedCategory == 'All') {
      return _menuItems;
    }
    return _menuItems.where((item) => item['category'] == _selectedCategory.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _showAddItemDialog();
              },
              child: const Icon(Icons.add),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Menu Management',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          // TODO: Implement search
                        },
                      ),
                    ],
                  ),
                ),
                
                // Category filters
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category['name'] == _selectedCategory;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category['name']),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category['name'];
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                const Divider(),
                
                // Menu items
                filteredMenuItems.isEmpty
                    ? _buildEmptyState()
                    : Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMenuItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredMenuItems[index];
                            return _buildMenuItemCard(item);
                          },
                        ),
                      ),
              ],
            ),
          );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No menu items found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to your menu to get started',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showAddItemDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Menu Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Switch(
                        value: item['isAvailable'],
                        onChanged: (value) {
                          setState(() {
                            item['isAvailable'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showAddItemDialog(item: item);
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showDeleteConfirmation(item);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> item) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Menu Item'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${item['name']}?'),
                const Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                setState(() {
                  _menuItems.removeWhere((menuItem) => menuItem['id'] == item['id']);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddItemDialog({Map<String, dynamic>? item}) async {
    final TextEditingController nameController = TextEditingController(text: item?['name'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: item?['description'] ?? '');
    final TextEditingController priceController = TextEditingController(text: item?['price']?.toString() ?? '');
    
    String selectedCategory = item?['category'] ?? _categories[1]['id']; // Default to first non-All category
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item != null ? 'Edit Dish' : 'Add New Dish'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Dish Name',
                    hintText: 'Enter dish name',
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Dish Type',
                  ),
                  items: _categories.where((category) => category['id'] != 'all').map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
                
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter dish description',
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (\$)',
                    hintText: 'Enter dish price',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate inputs
                if (nameController.text.trim().isEmpty || 
                    descriptionController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }
                
                double? price = double.tryParse(priceController.text.trim());
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }
                
                final newItem = {
                  'id': item?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'price': price,
                  'category': selectedCategory,
                  'image': item?['image'] ?? 'https://picsum.photos//150',
                  'isAvailable': item?['isAvailable'] ?? true,
                };
                
                setState(() {
                  if (item != null) {
                    // Edit existing item
                    final index = _menuItems.indexWhere((menuItem) => menuItem['id'] == item['id']);
                    if (index != -1) {
                      _menuItems[index] = newItem;
                    }
                  } else {
                    // Add new item
                    _menuItems.add(newItem);
                  }
                });
                
                Navigator.of(context).pop();
              },
              child: Text(item != null ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    ).then((_) => {
      // Dispose controllers when dialog is closed
      nameController.dispose(),
      descriptionController.dispose(),
      priceController.dispose(),
    });
  }
} 