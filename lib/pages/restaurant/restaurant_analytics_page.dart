import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/date_format_util.dart';
import 'table_booking_analytics_page.dart';

class RestaurantAnalyticsPage extends StatefulWidget {
  const RestaurantAnalyticsPage({super.key});

  @override
  State<RestaurantAnalyticsPage> createState() => _RestaurantAnalyticsPageState();
}

class _RestaurantAnalyticsPageState extends State<RestaurantAnalyticsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _metricsSub;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Defaults start from 0 for new restaurants
  List<double> _weeklyRevenue = [0, 0, 0, 0, 0, 0, 0];
  Map<String, double> _categoryRevenue = {
    'Main Courses': 0,
    'Appetizers': 0,
    'Desserts': 0,
    'Beverages': 0,
  };
  List<Map<String, dynamic>> _topSellingItems = [];
  List<Map<String, dynamic>> _customerTrends = [
    {'day': 'Mon', 'new': 0, 'returning': 0},
    {'day': 'Tue', 'new': 0, 'returning': 0},
    {'day': 'Wed', 'new': 0, 'returning': 0},
    {'day': 'Thu', 'new': 0, 'returning': 0},
    {'day': 'Fri', 'new': 0, 'returning': 0},
    {'day': 'Sat', 'new': 0, 'returning': 0},
    {'day': 'Sun', 'new': 0, 'returning': 0},
  ];
  // Orders analytics
  int _ordersCount = 0;
  double _totalRevenueValue = 0;
  double _averageOrderValue = 0;
  Map<String, double> _orderTypes = { 'Dine-in': 0, 'Takeaway': 0 };
  List<double> _orderTimes = [8, 12, 25, 18, 20, 28, 22];
  Map<String, int> _orderStatuses = { 'Completed': 0, 'In Progress': 0, 'Cancelled': 0 };
  int _reviewsCount = 0;
  int _averageOrderMinutes = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _startMetricsStream();
  }
  
  @override
  void dispose() {
    _metricsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startMetricsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }
    _metricsSub = _firestore
        .collection('restaurants')
        .doc(user.uid)
        .collection('analytics')
        .doc('metrics')
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      setState(() {
        // Weekly revenue
        final List<dynamic>? wr = data?['weeklyRevenue'] as List<dynamic>?;
        _weeklyRevenue = wr?.map((e) => (e as num).toDouble()).toList() ?? _weeklyRevenue;

        // Totals
        _totalRevenueValue = (data?['totalRevenue'] as num?)?.toDouble() ?? _totalRevenueValue;
        _ordersCount = (data?['ordersCount'] as num?)?.toInt() ?? _ordersCount;
        _averageOrderValue = (data?['averageOrderValue'] as num?)?.toDouble() ?? (_ordersCount > 0 ? _totalRevenueValue / _ordersCount : 0);

        // Category revenue
        final Map<String, dynamic>? cr = data?['categoryRevenue'] as Map<String, dynamic>?;
        if (cr != null) {
          _categoryRevenue = cr.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }

        // Top items
        final List<dynamic>? ti = data?['topSellingItems'] as List<dynamic>?;
        _topSellingItems = ti?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? _topSellingItems;

        // Customer trends
        final List<dynamic>? ct = data?['customerTrends'] as List<dynamic>?;
        if (ct != null && ct.isNotEmpty) {
          _customerTrends = ct.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        // Order types
        final Map<String, dynamic>? ot = data?['orderTypes'] as Map<String, dynamic>?;
        if (ot != null) {
          _orderTypes = ot.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }

        // Order times (7 slots)
        final List<dynamic>? times = data?['orderTimes'] as List<dynamic>?;
        _orderTimes = times?.map((e) => (e as num).toDouble()).toList() ?? _orderTimes;

        // Statuses
        final Map<String, dynamic>? st = data?['orderStatuses'] as Map<String, dynamic>?;
        if (st != null) {
          _orderStatuses = st.map((k, v) => MapEntry(k, (v as num).toInt()));
        }

        // Reviews count
        _reviewsCount = (data?['reviewsCount'] as num?)?.toInt() ?? _reviewsCount;

        // Average order time in minutes
        _averageOrderMinutes = (data?['averageOrderMinutes'] as num?)?.toInt() ?? _averageOrderMinutes;

        _isLoading = false;
      });
    }, onError: (_) {
      setState(() { _isLoading = false; });
    });
  }

  String _computeRetentionRate() {
    final int newCustomers = _customerTrends.fold<int>(0, (sum, d) => sum + (d['new'] as num).toInt());
    final int returningCustomers = _customerTrends.fold<int>(0, (sum, d) => sum + (d['returning'] as num).toInt());
    final int total = newCustomers + returningCustomers;
    if (total <= 0) return '0%';
    final double rate = (returningCustomers / total) * 100.0;
    return '${rate.toStringAsFixed(0)}%';
  }

  String _getReviewsCountText() {
    return _reviewsCount.toString();
  }

  String _computeAverageOrderTimeText() {
    if (_averageOrderMinutes <= 0) return '—';
    return '${_averageOrderMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: const Text('Analytics'),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Sales'),
                  Tab(text: 'Menu Performance'),
                  Tab(text: 'Customer Trends'),
                  Tab(text: 'Order Analytics'),
                  Tab(text: 'Table Bookings'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(),
                _buildMenuPerformanceTab(),
                _buildCustomerTrendsTab(),
                _buildOrderAnalyticsTab(),
                const TableBookingAnalyticsPage(),
              ],
            ),
          );
  }
  
  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time period selector
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String>(
                value: 'This Week',
                items: ['This Week', 'This Month', 'This Year', 'Custom']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // Handle time period change
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Revenue overview
          const Text(
            'Revenue Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: _buildRevenueChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Revenue summary
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Revenue',
                  DateFormatUtil.formatCurrencyIndian(_totalRevenueValue),
                  Icons.attach_money,
                  Colors.green,
                  '',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Average Order',
                  DateFormatUtil.formatCurrencyIndian(_averageOrderValue),
                  Icons.receipt_long,
                  Colors.blue,
                  '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Orders',
                  _ordersCount.toString(),
                  Icons.shopping_cart,
                  Colors.orange,
                  '',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Revenue by category
          const Text(
            'Revenue by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: _buildCategoryRevenueChart(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top selling items
          const Text(
            'Top Selling Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: Column(
              children: [
                if (_topSellingItems.isEmpty)
                  const Text('No data yet', style: TextStyle(color: Colors.grey))
                else
                for (var item in _topSellingItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item['sales']} sold',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormatUtil.formatCurrencyIndian((item['revenue'] as num).toDouble()),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Items with low performance
          const Text(
            'Items with Low Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: Column(
              children: [
                const Text('No data yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recommendations
          const Text(
            'Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text('No recommendations yet', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildCustomerTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer trends
          const Text(
            'Customer Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: _buildCustomerTrendsChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Customer statistics
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'New Customers',
                  _customerTrends.fold<int>(0, (sum, d) => sum + (d['new'] as num).toInt()).toString(),
                  Icons.person_add,
                  Colors.purple,
                  '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Returning Customers',
                  _customerTrends.fold<int>(0, (sum, d) => sum + (d['returning'] as num).toInt()).toString(),
                  Icons.people,
                  Colors.teal,
                  '',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Retention Rate',
                  _computeRetentionRate(),
                  Icons.repeat,
                  Colors.blue,
                  '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Reviews',
                  _getReviewsCountText(),
                  Icons.star,
                  Colors.amber,
                  '',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Customer feedback summary
          const Text(
            'Customer Feedback Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: Column(
              children: [
                _buildFeedbackItem('Food Quality', 4.8, Colors.green),
                _buildFeedbackItem('Service', 4.5, Colors.green),
                _buildFeedbackItem('Speed', 4.2, Colors.amber),
                _buildFeedbackItem('Value for Money', 4.0, Colors.amber),
                _buildFeedbackItem('Ambiance', 4.6, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order statistics
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Orders',
                  _ordersCount.toString(),
                  Icons.receipt_long,
                  Colors.blue,
                  '',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Average Time',
                  _computeAverageOrderTimeText(),
                  Icons.access_time,
                  Colors.orange,
                  '',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Order types
          const Text(
            'Order Types',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildOrderTypesChart(),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Dine-in', Colors.orange),
                      const SizedBox(height: 8),
                      _buildLegendItem('Takeaway', Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Order times
          const Text(
            'Order Times',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
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
            child: _buildOrderTimesChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Order status breakdown
          const Text(
            'Order Status Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildOrderStatusCard('Completed', _orderStatuses['Completed'] ?? 0, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderStatusCard('In Progress', _orderStatuses['In Progress'] ?? 0, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderStatusCard('Cancelled', _orderStatuses['Cancelled'] ?? 0, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRevenueChart() {
    // Check if there's any non-zero revenue
    bool hasData = _weeklyRevenue.any((revenue) => revenue > 0);
    
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No revenue data available yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // Find maximum value for proper scaling
    double maxRevenue = _weeklyRevenue.reduce((a, b) => a > b ? a : b);
    maxRevenue = maxRevenue <= 0 ? 1000 : maxRevenue * 1.2; // Add 20% padding
    
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final intValue = value.toInt();
                if (intValue >= 0 && intValue < days.length) {
                  return Text(days[intValue]);
                }
                return const Text('');
              },
              reservedSize: 22,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxRevenue,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < _weeklyRevenue.length; i++)
                FlSpot(i.toDouble(), _weeklyRevenue[i]),
            ],
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryRevenueChart() {
    final categories = _categoryRevenue.keys.toList();
    final values = _categoryRevenue.values.toList();
    final total = values.fold(0.0, (a, b) => a + b);
    
    // Handle case when all values are zero
    if (total <= 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No revenue data available yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(categories.length, (i) {
          final percentage = (values[i] / total * 100).toStringAsFixed(1);
          return PieChartSectionData(
            color: _getCategoryColor(i),
            value: values[i],
            title: '$percentage%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildCustomerTrendsChart() {
    // Check if there's any data
    bool hasData = _customerTrends.any((day) => 
      (day['new'] as num) > 0 || (day['returning'] as num) > 0);
    
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No customer data available yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 35,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < _customerTrends.length) {
                  return Text(_customerTrends[index]['day'] as String);
                }
                return const Text('');
              },
              reservedSize: 22,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          _customerTrends.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (((_customerTrends[index]['new'] as num) + (_customerTrends[index]['returning'] as num))).toDouble(),
                color: Colors.blue.shade800,
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    (_customerTrends[index]['new'] as num).toDouble(),
                    Colors.blue.shade300,
                  ),
                  BarChartRodStackItem(
                    (_customerTrends[index]['new'] as num).toDouble(),
                    ((_customerTrends[index]['new'] as num) + (_customerTrends[index]['returning'] as num)).toDouble(),
                    Colors.blue.shade800,
                  ),
                ],
                borderRadius: BorderRadius.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderTypesChart() {
    // Using sample data for visualization
    final double dineIn = _orderTypes['Dine-in'] ?? 0;
    final double takeaway = _orderTypes['Takeaway'] ?? 0;
    bool hasData = dineIn + takeaway > 0;
    
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No order type data available yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.orange,
            value: dineIn,
            title: dineIn + takeaway > 0 ? '${(dineIn/(dineIn+takeaway)*100).toStringAsFixed(0)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.blue,
            value: takeaway,
            title: dineIn + takeaway > 0 ? '${(takeaway/(dineIn+takeaway)*100).toStringAsFixed(0)}%' : '',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderTimesChart() {
    bool hasData = _orderTimes.any((v) => v > 0);
    
    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No order time data available yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 30,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final timeSlots = ['8-10', '10-12', '12-2', '2-4', '4-6', '6-8', '8-10'];
                final index = value.toInt();
                if (index >= 0 && index < timeSlots.length) {
                  return Text(timeSlots[index]);
                }
                return const Text('');
              },
              reservedSize: 22,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: (i < _orderTimes.length ? _orderTimes[i] : 0), color: Colors.blue, width: 20)],
        )),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: trend.startsWith('+') ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    color: trend.startsWith('+') ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLowPerformingItem(String name, int sales, int percentChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$sales sold',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$percentChange%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopMenuItem(String name, int sales, double revenue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$sales sold',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              DateFormatUtil.formatCurrencyIndian(revenue),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeedbackItem(String category, double rating, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(category),
          ),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rating / 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderStatusCard(String status, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            status,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
} 