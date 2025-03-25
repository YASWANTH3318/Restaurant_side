import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/restaurant.dart';
import '../models/pre_order.dart';
import '../models/reservation.dart';
import '../services/pre_order_service.dart';
import '../services/reservation_service.dart';
import 'pre_order_page.dart';

class TableBookingPage extends StatefulWidget {
  final Restaurant restaurant;
  final String userId;

  const TableBookingPage({
    super.key,
    required this.restaurant,
    required this.userId,
  });

  @override
  State<TableBookingPage> createState() => _TableBookingPageState();
}

class _TableBookingPageState extends State<TableBookingPage> {
  DateTime _selectedDate = DateTime.now();
  int _numberOfGuests = 2;
  String? _selectedTime;
  bool _isLoading = false;
  String? _reservationId;
  String? _specialRequests;

  final List<String> _availableTimes = [
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00', '18:30',
    '19:00', '19:30', '20:00', '20:30', '21:00', '21:30', '22:00', '22:30',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Table'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.restaurant.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.restaurant.cuisine),
                    Text(widget.restaurant.address),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Calendar
            Card(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 30)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _selectedTime = null;
                  });
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Number of Guests
            Text(
              'Number of Guests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _numberOfGuests > 1
                      ? () => setState(() => _numberOfGuests--)
                      : null,
                ),
                Text(
                  _numberOfGuests.toString(),
                  style: const TextStyle(fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _numberOfGuests < 10
                      ? () => setState(() => _numberOfGuests++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Time Selection
            Text(
              'Select Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTimes.map((time) {
                final isSelected = _selectedTime == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = selected ? time : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Special Requests
            Text(
              'Special Requests (Optional)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'e.g., Birthday celebration, Allergies, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => _specialRequests = value,
            ),
            const SizedBox(height: 32),

            // Pre-order Option
            if (_selectedTime != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Pre-order Food'),
                  subtitle: const Text('Order your food in advance to save time'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _showPreOrderPage(),
                ),
              ),
            const SizedBox(height: 16),

            // Book Table Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTime != null ? _bookTable : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Book Table'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreOrderPage() {
    if (_selectedTime == null) return;

    final reservationDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(_selectedTime!.split(':')[0]),
      int.parse(_selectedTime!.split(':')[1]),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreOrderPage(
          restaurant: widget.restaurant,
          reservationId: _reservationId ?? '',
          userId: widget.userId,
          reservationDate: reservationDateTime,
          numberOfGuests: _numberOfGuests,
        ),
      ),
    );
  }

  Future<void> _bookTable() async {
    if (_selectedTime == null) return;

    setState(() => _isLoading = true);

    try {
      // Create a unique reservation ID
      _reservationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Find an available table that matches the guest count
      final availableTable = widget.restaurant.availableTables
          .firstWhere((table) => 
              table.isAvailable && 
              table.capacity >= _numberOfGuests &&
              table.capacity <= _numberOfGuests + 2,
            orElse: () => widget.restaurant.availableTables
                .firstWhere((table) => table.isAvailable,
                    orElse: () => throw Exception('No tables available')));

      final reservation = Reservation(
        id: _reservationId!,
        userId: widget.userId,
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        restaurantImage: widget.restaurant.image,
        reservationDate: _selectedDate,
        reservationTime: _selectedTime!,
        numberOfGuests: _numberOfGuests,
        tableId: availableTable.id,
        tableType: availableTable.type,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        specialRequests: _specialRequests?.trim(),
      );

      await ReservationService.createReservation(reservation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Table booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking table: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
} 