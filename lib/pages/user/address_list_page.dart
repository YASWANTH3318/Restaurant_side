import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import 'edit_address_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  bool _isLoading = true;
  List<AddressModel> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final addresses = await AddressService.getUserAddresses(user.uid);
      if (mounted) {
        setState(() {
          _addresses = addresses;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final success = await AddressService.deleteAddress(user.uid, address.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
        _loadAddresses();
      }
    } catch (e) {
      print('Error deleting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting address: $e')),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(AddressModel address) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final success = await AddressService.setDefaultAddress(user.uid, address.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default address updated')),
        );
        _loadAddresses();
      }
    } catch (e) {
      print('Error setting default address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating default address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No addresses found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first delivery address',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditAddressPage(),
                            ),
                          );
                          if (result == true && mounted) {
                            _loadAddresses();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Address'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final address = _addresses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: address.isDefault
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          title: Text(
                            '${address.houseName} ${address.houseNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (address.landmark.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Near ${address.landmark}'),
                              ],
                              const SizedBox(height: 4),
                              Text(address.street),
                              Text('${address.city}, ${address.state}'),
                              Text('PIN: ${address.pincode}'),
                              if (address.isDefault) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Default',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              if (!address.isDefault)
                                PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.check_circle_outline),
                                      SizedBox(width: 8),
                                      Text('Set as Default'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: const [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: const [
                                    Icon(Icons.delete_outline, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              switch (value) {
                                case 'default':
                                  await _setDefaultAddress(address);
                                  break;
                                case 'edit':
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditAddressPage(
                                        address: address,
                                      ),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    _loadAddresses();
                                  }
                                  break;
                                case 'delete':
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Address'),
                                      content: const Text(
                                        'Are you sure you want to delete this address?'
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && mounted) {
                                    await _deleteAddress(address);
                                  }
                                  break;
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditAddressPage(),
                  ),
                );
                if (result == true && mounted) {
                  _loadAddresses();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
} 