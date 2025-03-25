import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessHoursPage extends StatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  State<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends State<BusinessHoursPage> {
  bool _isLoading = true;
  final Map<String, bool> _isOpenMap = {};
  final Map<String, TimeOfDay?> _openingTimeMap = {};
  final Map<String, TimeOfDay?> _closingTimeMap = {};
  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeBusinessHours();
    _loadBusinessHours();
  }

  void _initializeBusinessHours() {
    for (var day in _weekDays) {
      _isOpenMap[day] = true;
      _openingTimeMap[day] = const TimeOfDay(hour: 9, minute: 0);
      _closingTimeMap[day] = const TimeOfDay(hour: 21, minute: 0);
    }
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
        final businessHours = doc.data()!['businessHours'] as Map<String, dynamic>;
        
        setState(() {
          for (var day in _weekDays) {
            if (businessHours.containsKey(day)) {
              final dayData = businessHours[day] as Map<String, dynamic>;
              _isOpenMap[day] = dayData['isOpen'] ?? true;
              
              if (dayData['openingTime'] != null) {
                final openTime = dayData['openingTime'].toString().split(':');
                _openingTimeMap[day] = TimeOfDay(
                  hour: int.parse(openTime[0]),
                  minute: int.parse(openTime[1]),
                );
              }
              
              if (dayData['closingTime'] != null) {
                final closeTime = dayData['closingTime'].toString().split(':');
                _closingTimeMap[day] = TimeOfDay(
                  hour: int.parse(closeTime[0]),
                  minute: int.parse(closeTime[1]),
                );
              }
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading business hours: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(BuildContext context, String day, bool isOpeningTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpeningTime 
          ? _openingTimeMap[day] ?? const TimeOfDay(hour: 9, minute: 0)
          : _closingTimeMap[day] ?? const TimeOfDay(hour: 21, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isOpeningTime) {
          _openingTimeMap[day] = picked;
        } else {
          _closingTimeMap[day] = picked;
        }
      });
    }
  }

  Future<void> _saveBusinessHours() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not found');

      final Map<String, Map<String, dynamic>> businessHours = {};

      for (var day in _weekDays) {
        businessHours[day] = {
          'isOpen': _isOpenMap[day],
          'openingTime': _openingTimeMap[day] != null 
              ? '${_openingTimeMap[day]!.hour}:${_openingTimeMap[day]!.minute.toString().padLeft(2, '0')}'
              : null,
          'closingTime': _closingTimeMap[day] != null 
              ? '${_closingTimeMap[day]!.hour}:${_closingTimeMap[day]!.minute.toString().padLeft(2, '0')}'
              : null,
        };
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'businessHours': businessHours});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business hours saved successfully')),
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

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final day = _weekDays[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: _isOpenMap[day] ?? true,
                              onChanged: (value) {
                                setState(() => _isOpenMap[day] = value);
                              },
                            ),
                          ],
                        ),
                        if (_isOpenMap[day] ?? true) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Opening Time',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                  onTap: () => _selectTime(context, day, true),
                                  controller: TextEditingController(
                                    text: _formatTimeOfDay(_openingTimeMap[day]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Closing Time',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.access_time),
                                  ),
                                  onTap: () => _selectTime(context, day, false),
                                  controller: TextEditingController(
                                    text: _formatTimeOfDay(_closingTimeMap[day]),
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
              },
            ),
    );
  }
} 