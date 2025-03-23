import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RestaurantAnalyticsPage extends StatefulWidget {
  const RestaurantAnalyticsPage({super.key});

  @override
  State<RestaurantAnalyticsPage> createState() => _RestaurantAnalyticsPageState();
}

class _RestaurantAnalyticsPageState extends State<RestaurantAnalyticsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  
  // Mock data
  List<double> _weeklyRevenue = [410.50, 680.25, 590.75, 720.30, 850.20, 950.75, 780.40];
  Map<String, double> _categoryRevenue = {
    'Main Courses': 3250.75,
    'Appetizers': 1850.30,
    'Desserts': 1250.85,
    'Beverages': 1050.20,
  };
  List<Map<String, dynamic>> _topSellingItems = [
    {'name': 'Grilled Salmon', 'sales': 124, 'revenue': 2351.76},
    {'name': 'Caesar Salad', 'sales': 98, 'revenue': 881.02},
    {'name': 'Chocolate Cake', 'sales': 76, 'revenue': 531.24},
    {'name': 'Iced Tea', 'sales': 156, 'revenue': 466.44},
    {'name': 'Burger', 'sales': 65, 'revenue': 877.50},
  ];
  List<Map<String, dynamic>> _customerTrends = [
    {'day': 'Mon', 'new': 5, 'returning': 18},
    {'day': 'Tue', 'new': 7, 'returning': 15},
    {'day': 'Wed', 'new': 4, 'returning': 20},
    {'day': 'Thu', 'new': 9, 'returning': 22},
    {'day': 'Fri', 'new': 12, 'returning': 28},
    {'day': 'Sat', 'new': 14, 'returning': 32},
    {'day': 'Sun', 'new': 8, 'returning': 25},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  '\$4,983.15',
                  Icons.attach_money,
                  Colors.green,
                  '+12.5% vs last week',
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
                  '\$31.52',
                  Icons.receipt_long,
                  Colors.blue,
                  '+5.3% vs last week',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Orders',
                  '158',
                  Icons.shopping_cart,
                  Colors.orange,
                  '+8.7% vs last week',
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
                for (var item in _topSellingItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            item['name'],
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
                            '\$${item['revenue'].toStringAsFixed(2)}',
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
                _buildLowPerformingItem('Vegetarian Pizza', 12, -15),
                _buildLowPerformingItem('Garden Salad', 8, -25),
                _buildLowPerformingItem('Vanilla Milkshake', 10, -12),
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
          
          _buildRecommendationCard(
            'Consider a promotion for Vegetarian Pizza',
            'It has 15% lower sales compared to last month',
            Icons.local_offer,
            Colors.amber,
          ),
          
          const SizedBox(height: 12),
          
          _buildRecommendationCard(
            'Add new dessert options',
            'Desserts have the highest profit margin in your menu',
            Icons.cake,
            Colors.pink,
          ),
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
                  '59',
                  Icons.person_add,
                  Colors.purple,
                  '+12.5% vs last week',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Returning Customers',
                  '160',
                  Icons.people,
                  Colors.teal,
                  '+7.2% vs last week',
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
                  '73%',
                  Icons.repeat,
                  Colors.blue,
                  '+3.5% vs last week',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Reviews',
                  '48',
                  Icons.star,
                  Colors.amber,
                  '+15.2% vs last week',
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
                  '158',
                  Icons.receipt_long,
                  Colors.blue,
                  '+8.7% vs last week',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Average Time',
                  '24 min',
                  Icons.access_time,
                  Colors.orange,
                  '-2.3 min vs last week',
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
            child: _buildOrderTypesChart(),
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
                child: _buildOrderStatusCard('Completed', 132, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderStatusCard('In Progress', 15, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderStatusCard('Cancelled', 11, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRevenueChart() {
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
        maxY: 1000,
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
    final total = values.reduce((a, b) => a + b);
    
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
                  return Text(_customerTrends[index]['day']);
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
                toY: (_customerTrends[index]['new'] + _customerTrends[index]['returning']).toDouble(),
                color: Colors.blue.shade800,
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    _customerTrends[index]['returning'].toDouble(),
                    Colors.blue.shade300,
                  ),
                  BarChartRodStackItem(
                    _customerTrends[index]['returning'].toDouble(),
                    (_customerTrends[index]['new'] + _customerTrends[index]['returning']).toDouble(),
                    Colors.purple.shade300,
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
                width: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOrderTypesChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: Colors.orange,
            value: 65,
            title: '65%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.blue,
            value: 35,
            title: '35%',
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
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 8, color: Colors.blue, width: 20)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 12, color: Colors.blue, width: 20)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 25, color: Colors.blue, width: 20)],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 18, color: Colors.blue, width: 20)],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [BarChartRodData(toY: 20, color: Colors.blue, width: 20)],
          ),
          BarChartGroupData(
            x: 5,
            barRods: [BarChartRodData(toY: 28, color: Colors.blue, width: 20)],
          ),
          BarChartGroupData(
            x: 6,
            barRods: [BarChartRodData(toY: 22, color: Colors.blue, width: 20)],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, [String? subtitle]) {
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
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitle.contains('+') ? Colors.green : Colors.red,
              ),
            ),
          ],
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
            rating.toString(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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