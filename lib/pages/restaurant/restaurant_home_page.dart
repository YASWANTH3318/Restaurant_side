import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../services/restaurant_auth_service.dart';
import '../../services/restaurant_management_service.dart';
import '../../config/restaurant_database_structure.dart';
import 'restaurant_dashboard_page.dart';
import 'restaurant_menu_page.dart';
import 'restaurant_orders_page.dart';
import 'restaurant_profile_page.dart';
import 'restaurant_analytics_page.dart';
import 'restaurant_details_page.dart';
import 'restaurant_tables_page.dart';
import 'restaurant_notifications_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/storage_service.dart';
import '../../services/restaurant_storage_service.dart';
import '../login_page.dart';

class RestaurantHomePage extends StatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  State<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends State<RestaurantHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const RestaurantDashboardPage(),
    const RestaurantOrdersPage(),
    const RestaurantMenuPage(),
    const RestaurantAnalyticsPage(),
    const RestaurantProfilePage(),
  ];

  Future<void> _handleSignOut(BuildContext context) async {
    try {
      await RestaurantAuthService.signOutRestaurant();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }
  
  void _openQuickSetupSheet() {
    final TextEditingController tablesController = TextEditingController();
    int currentTables = 0;
    bool saving = false;

    Future<void> loadCurrent() async {
      try {
        final tables = await RestaurantManagementService.getRestaurantTables();
        currentTables = tables.length;
        tablesController.text = currentTables.toString();
      } catch (_) {}
    }

    Future<void> saveTablesCount(int count, void Function(void Function()) setModalState) async {
      try {
        setModalState(() { saving = true; });
        
        // Clear existing tables
        final existingTables = await RestaurantManagementService.getRestaurantTables();
        for (final table in existingTables) {
          await RestaurantManagementService.deleteTable(table['id']);
        }
        
        // Add new tables
        for (int i = 0; i < count; i++) {
          await RestaurantManagementService.addTable({
            'id': 'T${i + 1}',
            'type': 'Standard',
            'capacity': 2,
            'isAvailable': true,
            'minimumSpend': 0.0,
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tables updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update tables: $e')),
          );
        }
      } finally {
        setModalState(() { saving = false; });
      }
    }

    Future<void> pickAndUploadPhoto(void Function(void Function()) setModalState) async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image == null) return;
        setModalState(() { saving = true; });
        
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        
        final url = await RestaurantStorageService.uploadRestaurantProfileImage(File(image.path), user.uid);
        await RestaurantManagementService.updateRestaurantProfile({
          'image': url,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload photo: $e')),
          );
        }
      } finally {
        setModalState(() { saving = false; });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Load once
            if (tablesController.text.isEmpty) {
              loadCurrent();
            }
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.storefront),
                      SizedBox(width: 8),
                      Text('Quick Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Number of tables
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tablesController,
                          decoration: const InputDecoration(
                            labelText: 'Number of tables',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      saving
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : ElevatedButton(
                              onPressed: () {
                                final int? count = int.tryParse(tablesController.text.trim());
                                if (count == null || count < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Enter a valid number')),
                                  );
                                  return;
                                }
                                saveTablesCount(count, setModalState);
                              },
                              child: const Text('Save'),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Add menu manually
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restaurant_menu),
                    title: const Text('Add menu items manually'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() { _selectedIndex = 2; });
                    },
                  ),
                  // Add photo
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_a_photo),
                    title: const Text('Add restaurant photo'),
                    onTap: () => pickAndUploadPhoto(setModalState),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.storefront),
          tooltip: 'Quick setup',
          onPressed: _openQuickSetupSheet,
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseAuth.instance.currentUser == null
                ? const Stream.empty()
                : FirebaseFirestore.instance
                    .collection('restaurants')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RestaurantNotificationsPage(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 