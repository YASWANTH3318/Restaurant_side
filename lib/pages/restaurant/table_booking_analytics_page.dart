import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/date_format_util.dart';

class TableBookingAnalyticsPage extends StatefulWidget {
  const TableBookingAnalyticsPage({super.key});

  @override
  State<TableBookingAnalyticsPage> createState() => _TableBookingAnalyticsPageState();
}

class _TableBookingAnalyticsPageState extends State<TableBookingAnalyticsPage> {
  bool _isLoading = true;
  String _selectedPeriod = 'This Week';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  // Dynamic data for table bookings
  List<Map<String, dynamic>> _dailyBookings = const [
    {'day': 'Mon', 'bookings': 0, 'canceled': 0},
    {'day': 'Tue', 'bookings': 0, 'canceled': 0},
    {'day': 'Wed', 'bookings': 0, 'canceled': 0},
    {'day': 'Thu', 'bookings': 0, 'canceled': 0},
    {'day': 'Fri', 'bookings': 0, 'canceled': 0},
    {'day': 'Sat', 'bookings': 0, 'canceled': 0},
    {'day': 'Sun', 'bookings': 0, 'canceled': 0},
  ];
  
  // Table occupancy by time slots
  Map<String, int> _timeSlotOccupancy = const {};
  
  // Table size preference
  Map<String, int> _tableSizePreference = const {};
  
  // Recent bookings
  List<Map<String, dynamic>> _recentBookings = const [];

  int _totalBookings = 0;
  int _occupancyRate = 0; // percentage
  int _noShowRate = 0; // percentage

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startStream() {
    final user = _auth.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }
    _sub = _firestore
        .collection('restaurants')
        .doc(user.uid)
        .collection('analytics')
        .doc('table_bookings')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      setState(() {
        // Daily bookings
        final List<dynamic>? daily = data?['dailyBookings'] as List<dynamic>?;
        if (daily != null && daily.isNotEmpty) {
          _dailyBookings = daily.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        // Time slot occupancy
        final Map<String, dynamic>? occ = data?['timeSlotOccupancy'] as Map<String, dynamic>?;
        if (occ != null) {
          _timeSlotOccupancy = occ.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
        // Table size preference
        final Map<String, dynamic>? tsp = data?['tableSizePreference'] as Map<String, dynamic>?;
        if (tsp != null) {
          _tableSizePreference = tsp.map((k, v) => MapEntry(k, (v as num).toInt()));
        }
        // Recent bookings
        final List<dynamic>? rb = data?['recentBookings'] as List<dynamic>?;
        _recentBookings = rb?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? _recentBookings;
        // Summary
        _totalBookings = (data?['totalBookings'] as num?)?.toInt() ?? _totalBookings;
        _occupancyRate = (data?['occupancyRate'] as num?)?.toInt() ?? _occupancyRate;
        _noShowRate = (data?['noShowRate'] as num?)?.toInt() ?? _noShowRate;
        _isLoading = false;
      });
    }, onError: (_) { setState(() => _isLoading = false); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Booking Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time period selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Table Booking Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: ['This Week', 'This Month', 'Last Month', 'Custom']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPeriod = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Summary cards
                  _buildSummaryRow(),
                  
                  const SizedBox(height: 24),
                  
                  // Daily bookings chart
                  const Text(
                    'Daily Bookings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDailyBookingsChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Most popular time slots
                  const Text(
                    'Popular Time Slots',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeSlotChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Table size preference chart
                  const Text(
                    'Table Size Preference',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTableSizeChart(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent bookings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Bookings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to detailed booking list
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRecentBookingsList(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Bookings',
            _totalBookings.toString(),
            Icons.book_online,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Occupancy Rate',
            _occupancyRate > 0 ? '${_occupancyRate}%' : '0%',
            Icons.people,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'No-Show Rate',
            _noShowRate > 0 ? '${_noShowRate}%' : '0%',
            Icons.person_off,
            Colors.red,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDailyBookingsChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: (_dailyBookings.isEmpty || _dailyBookings.every((d) => (d['bookings'] as num) == 0))
          ? const Center(child: Text('No data available'))
          : BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (_dailyBookings.fold<num>(0, (m, d) => ((d['bookings'] as num) > m ? (d['bookings'] as num) : m))).toDouble() + 2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.grey.shade800,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = _dailyBookings[groupIndex]['day'];
                final bookings = rod.toY.toInt();
                return BarTooltipItem(
                  '$day: $bookings bookings',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _dailyBookings[value.toInt()]['day'],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 2 != 0) return const SizedBox();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 2,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          barGroups: _dailyBookings.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data['bookings'].toDouble(),
                  color: Theme.of(context).primaryColor,
                  width: 14,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildTimeSlotChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _timeSlotOccupancy.isEmpty
          ? const Center(child: Text('No data available'))
          : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10, // Adjust based on your data
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.grey.shade800,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final timeSlots = _timeSlotOccupancy.keys.toList();
                        if (value.toInt() >= timeSlots.length) return const SizedBox();
                        
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              timeSlots[value.toInt()].split(' - ')[0],
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 != 0) return const SizedBox();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(), 
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 2,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: _timeSlotOccupancy.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value.toDouble(),
                        color: Colors.orange,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
  
  Widget _buildTableSizeChart() {
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    
    int i = 0;
    for (final entry in _tableSizePreference.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: entry.value > 0 ? '${entry.key}\n${entry.value}' : '',
          color: colors[i % colors.length],
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    }
    
    // If all values are 0, show empty state
    if (_tableSizePreference.isEmpty || _tableSizePreference.values.every((value) => value == 0)) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No table size data available yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < _tableSizePreference.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: colors[i % colors.length],
                        ),
                        const SizedBox(width: 8),
                        Text(_tableSizePreference.keys.elementAt(i)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentBookingsList() {
    if (_recentBookings.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_online, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No recent bookings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'New bookings will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentBookings.length > 5 ? 5 : _recentBookings.length,
      itemBuilder: (context, index) {
        final booking = _recentBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.event, color: Colors.orange, size: 20),
            ),
            title: Text(
              booking['customerName'] ?? 'Customer',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _formatRecentBookingSubtitle(booking),
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              (booking['status'] ?? 'Pending').toString(),
              style: TextStyle(
                fontSize: 12,
                color: ((booking['status'] ?? '').toString().toLowerCase() == 'confirmed') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            dense: true,
          ),
        );
      },
    );
  }

  String _formatRecentBookingSubtitle(Map<String, dynamic> booking) {
    final date = booking['date'];
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${DateFormatUtil.formatDateIndian(dt)} at ${booking['time'] ?? ''}';
    }
    return '${booking['date'] ?? ''} at ${booking['time'] ?? ''}';
  }
} 