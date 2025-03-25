import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/date_format_util.dart';

class TableBookingAnalyticsPage extends StatefulWidget {
  const TableBookingAnalyticsPage({super.key});

  @override
  State<TableBookingAnalyticsPage> createState() => _TableBookingAnalyticsPageState();
}

class _TableBookingAnalyticsPageState extends State<TableBookingAnalyticsPage> {
  bool _isLoading = false;
  String _selectedPeriod = 'This Week';
  
  // Mock data for table bookings
  final List<Map<String, dynamic>> _dailyBookings = [
    {'day': 'Mon', 'bookings': 3, 'canceled': 1},
    {'day': 'Tue', 'bookings': 5, 'canceled': 0},
    {'day': 'Wed', 'bookings': 4, 'canceled': 1},
    {'day': 'Thu', 'bookings': 7, 'canceled': 2},
    {'day': 'Fri', 'bookings': 9, 'canceled': 1},
    {'day': 'Sat', 'bookings': 12, 'canceled': 2},
    {'day': 'Sun', 'bookings': 8, 'canceled': 1},
  ];
  
  // Table occupancy by time slots
  final Map<String, int> _timeSlotOccupancy = {
    '12:00 - 14:00': 6,
    '14:00 - 16:00': 4,
    '16:00 - 18:00': 2,
    '18:00 - 20:00': 8,
    '20:00 - 22:00': 7,
  };
  
  // Table size preference
  final Map<String, int> _tableSizePreference = {
    '2 Persons': 18,
    '4 Persons': 12,
    '6 Persons': 6,
    '8+ Persons': 4,
  };
  
  // Recent bookings
  final List<Map<String, dynamic>> _recentBookings = [
    {'customerName': 'John Smith', 'date': 'May 15, 2023', 'time': '7:30 PM', 'status': 'Confirmed'},
    {'customerName': 'Alice Johnson', 'date': 'May 14, 2023', 'time': '6:00 PM', 'status': 'Confirmed'},
    {'customerName': 'Robert Brown', 'date': 'May 14, 2023', 'time': '8:00 PM', 'status': 'Confirmed'},
    {'customerName': 'Mary Williams', 'date': 'May 13, 2023', 'time': '7:00 PM', 'status': 'Canceled'},
    {'customerName': 'David Miller', 'date': 'May 12, 2023', 'time': '6:30 PM', 'status': 'Confirmed'},
  ];

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
            '48',
            Icons.book_online,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Occupancy Rate',
            '76%',
            Icons.people,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'No-Show Rate',
            '5%',
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10, // Adjust based on your data
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
    if (_tableSizePreference.values.every((value) => value == 0)) {
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
              booking['customerName'],
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${booking['date']} at ${booking['time']}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              booking['status'],
              style: TextStyle(
                fontSize: 12,
                color: booking['status'] == 'Confirmed' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            dense: true,
          ),
        );
      },
    );
  }
} 