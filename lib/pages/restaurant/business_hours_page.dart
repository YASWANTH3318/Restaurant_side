import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/restaurant_service.dart';

class BusinessHoursPage extends StatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  State<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends State<BusinessHoursPage> {
  bool _isLoading = true;
  final Map<String, Map<String, dynamic>> _businessHours = {
    'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'sunday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
  };

  @override
  void initState() {
    super.initState();
    _loadBusinessHours();
  }

  Future<void> _loadBusinessHours() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('businessHours')) {
        setState(() {
          _businessHours.clear();
          _businessHours.addAll(
            Map<String, Map<String, dynamic>>.from(
              doc.data()!['businessHours'],
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business hours: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBusinessHours() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save to users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'businessHours': _businessHours});

      // Sync to restaurants collection
      await RestaurantService.updateRestaurantHours(user.uid, _businessHours);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business hours updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving business hours: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        if (isOpenTime) {
          _businessHours[day]!['openTime'] = time;
        } else {
          _businessHours[day]!['closeTime'] = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Hours'),
        actions: [
          TextButton(
            onPressed: _saveBusinessHours,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _businessHours.entries.map((entry) {
                final day = entry.key;
                final hours = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day.substring(0, 1).toUpperCase() +
                                  day.substring(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: hours['isOpen'],
                              onChanged: (value) {
                                setState(() {
                                  _businessHours[day]!['isOpen'] = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (hours['isOpen']) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  onTap: () => _selectTime(day, true),
                                  decoration: const InputDecoration(
                                    labelText: 'Opening Time',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(
                                    text: hours['openTime'],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  onTap: () => _selectTime(day, false),
                                  decoration: const InputDecoration(
                                    labelText: 'Closing Time',
                                    border: OutlineInputBorder(),
                                  ),
                                  controller: TextEditingController(
                                    text: hours['closeTime'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
} 