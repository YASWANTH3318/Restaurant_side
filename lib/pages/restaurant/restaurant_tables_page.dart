import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/restaurant_service.dart';
import '../../models/restaurant.dart';

class RestaurantTablesPage extends StatefulWidget {
  const RestaurantTablesPage({super.key});

  @override
  State<RestaurantTablesPage> createState() => _RestaurantTablesPageState();
}

class _RestaurantTablesPageState extends State<RestaurantTablesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tables = [];
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for the add table form
  final _tableIdController = TextEditingController();
  final _tableTypeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _minimumSpendController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadTables();
  }
  
  @override
  void dispose() {
    _tableIdController.dispose();
    _tableTypeController.dispose();
    _capacityController.dispose();
    _minimumSpendController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();
      
      if (!restaurantDoc.exists) {
        // Create default tables if restaurant exists but has no tables
        _tables = [
          {
            'id': 'table1',
            'type': 'Standard',
            'capacity': 2,
            'isAvailable': true,
            'minimumSpend': 0.0,
          },
          {
            'id': 'table2',
            'type': 'Standard',
            'capacity': 4,
            'isAvailable': true,
            'minimumSpend': 0.0,
          },
        ];
        
        // Save default tables
        await RestaurantService.updateRestaurantTables(user.uid, _tables);
      } else {
        final data = restaurantDoc.data();
        final availableTables = data?['availableTables'];
        
        if (availableTables == null || (availableTables is List && availableTables.isEmpty)) {
          // Create default tables
          _tables = [
            {
              'id': 'table1',
              'type': 'Standard',
              'capacity': 2,
              'isAvailable': true,
              'minimumSpend': 0.0,
            },
            {
              'id': 'table2',
              'type': 'Standard',
              'capacity': 4,
              'isAvailable': true,
              'minimumSpend': 0.0,
            },
          ];
          
          // Save default tables
          await RestaurantService.updateRestaurantTables(user.uid, _tables);
        } else {
          _tables = List<Map<String, dynamic>>.from(availableTables);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tables: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveTables() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      await RestaurantService.updateRestaurantTables(user.uid, _tables);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tables saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving tables: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _addTable() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Table'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _tableIdController,
                    decoration: const InputDecoration(
                      labelText: 'Table ID',
                      hintText: 'e.g., Table1, VIP1',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a table ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tableTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Table Type',
                      hintText: 'e.g., Standard, VIP, Outdoor',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a table type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      hintText: 'Number of guests',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      try {
                        int capacity = int.parse(value);
                        if (capacity <= 0) {
                          return 'Capacity must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minimumSpendController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Spend (optional)',
                      hintText: 'Minimum amount in ₹',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _tables.add({
                      'id': _tableIdController.text.trim(),
                      'type': _tableTypeController.text.trim(),
                      'capacity': int.parse(_capacityController.text.trim()),
                      'isAvailable': true,
                      'minimumSpend': _minimumSpendController.text.isEmpty
                          ? 0.0
                          : double.parse(_minimumSpendController.text.trim()),
                    });
                  });
                  
                  // Clear form fields
                  _tableIdController.clear();
                  _tableTypeController.clear();
                  _capacityController.clear();
                  _minimumSpendController.clear();
                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Table'),
            ),
          ],
        );
      },
    );
  }
  
  void _editTable(int index) {
    final table = _tables[index];
    
    _tableIdController.text = table['id'];
    _tableTypeController.text = table['type'];
    _capacityController.text = table['capacity'].toString();
    _minimumSpendController.text = table['minimumSpend'].toString();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Table'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _tableIdController,
                    decoration: const InputDecoration(
                      labelText: 'Table ID',
                      hintText: 'e.g., Table1, VIP1',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a table ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tableTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Table Type',
                      hintText: 'e.g., Standard, VIP, Outdoor',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a table type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacity',
                      hintText: 'Number of guests',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter capacity';
                      }
                      try {
                        int capacity = int.parse(value);
                        if (capacity <= 0) {
                          return 'Capacity must be greater than 0';
                        }
                      } catch (e) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minimumSpendController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Spend (optional)',
                      hintText: 'Minimum amount in ₹',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    _tables[index] = {
                      'id': _tableIdController.text.trim(),
                      'type': _tableTypeController.text.trim(),
                      'capacity': int.parse(_capacityController.text.trim()),
                      'isAvailable': table['isAvailable'],
                      'minimumSpend': _minimumSpendController.text.isEmpty
                          ? 0.0
                          : double.parse(_minimumSpendController.text.trim()),
                    };
                  });
                  
                  // Clear form fields
                  _tableIdController.clear();
                  _tableTypeController.clear();
                  _capacityController.clear();
                  _minimumSpendController.clear();
                  
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }
  
  void _deleteTable(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: const Text('Are you sure you want to delete this table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tables.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTables,
            tooltip: 'Save changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No tables available',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addTable,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Table'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    table['id'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: table['isAvailable'],
                                  onChanged: (value) {
                                    setState(() {
                                      _tables[index]['isAvailable'] = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Type: ${table['type']}'),
                            Text('Capacity: ${table['capacity']} guests'),
                            Text('Minimum Spend: ₹${table['minimumSpend']}'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editTable(index),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteTable(index),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text('Delete', 
                                    style: TextStyle(color: Colors.red)
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _tables.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _addTable,
              child: const Icon(Icons.add),
            ),
    );
  }
} 