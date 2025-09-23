import 'package:flutter/material.dart';
import '../../utils/date_format_util.dart';
import 'package:flutter/widgets.dart';

class BloggerAnalyticsPage extends StatefulWidget {
  const BloggerAnalyticsPage({super.key});

  @override
  State<BloggerAnalyticsPage> createState() => _BloggerAnalyticsPageState();
}

class _BloggerAnalyticsPageState extends State<BloggerAnalyticsPage> {
  bool _isLoading = false;
  String _selectedPeriod = 'This Week';

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with time period selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items: const [
                        DropdownMenuItem(
                          value: 'Today',
                          child: Text('Today'),
                        ),
                        DropdownMenuItem(
                          value: 'This Week',
                          child: Text('This Week'),
                        ),
                        DropdownMenuItem(
                          value: 'This Month',
                          child: Text('This Month'),
                        ),
                        DropdownMenuItem(
                          value: 'All Time',
                          child: Text('All Time'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPeriod = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Key metrics
                const Text(
                  'Key Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMetricCard('Total Views', '542', Icons.visibility, Colors.blue),
                    _buildMetricCard('Likes', '128', Icons.favorite, Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildMetricCard('Comments', '24', Icons.comment, Colors.orange),
                    _buildMetricCard('Shares', '18', Icons.share, Colors.green),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Performance graph placeholder
                const Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_chart_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Performance Graph',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Top posts
                const Text(
                  'Top Performing Posts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTopPostCard(
                  'Getting Started with Food Blogging',
                  'Lorem ipsum dolor sit amet...',
                  245,
                  32,
                  'https://via.placeholder.com/150',
                ),
                const SizedBox(height: 16),
                _buildTopPostCard(
                  'Top 10 Street Foods You Must Try',
                  'Lorem ipsum dolor sit amet...',
                  187,
                  24,
                  'https://via.placeholder.com/150',
                ),
                
                const SizedBox(height: 32),
                
                // Audience insights
                const Text(
                  'Audience Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top Locations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLocationRow('Mumbai, Maharashtra', 37),
                        const SizedBox(height: 8),
                        _buildLocationRow('Delhi NCR', 25),
                        const SizedBox(height: 8),
                        _buildLocationRow('Bangalore, Karnataka', 18),
                        const SizedBox(height: 8),
                        _buildLocationRow('Pune, Maharashtra', 12),
                        const SizedBox(height: 8),
                        _buildLocationRow('Other Indian Cities', 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildSafeImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final String safeUrl = (url ?? '').trim();
    final bool isValidNetwork = safeUrl.startsWith('http://') || safeUrl.startsWith('https://');

    final Widget placeholder = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(Icons.broken_image, color: Colors.grey[500], size: (width != null ? width / 2 : 24)),
    );

    if (!isValidNetwork) return placeholder;

    return Image.network(
      safeUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    // Format numbers using Indian format if they are numeric
    String displayValue = value;
    try {
      final numValue = int.parse(value);
      displayValue = DateFormatUtil.formatNumberIndian(numValue);
    } catch (e) {
      // If not a number, use original value
      displayValue = value;
    }
    
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPostCard(String title, String preview, int views, int likes, String image) {
    // Format numbers using Indian number format
    final formattedViews = DateFormatUtil.formatNumberIndian(views);
    final formattedLikes = DateFormatUtil.formatNumberIndian(likes);
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildSafeImage(image, width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              formattedViews,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              formattedLikes,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String location, int percentage) {
    final formattedPercentage = DateFormatUtil.formatNumberIndian(percentage);
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(location),
        ),
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$formattedPercentage%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 