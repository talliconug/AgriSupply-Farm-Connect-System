import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../services/admin_service.dart';
import '../../widgets/loading_overlay.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  String _selectedPeriod = 'This Month';
  int _touchedIndex = -1;

  Map<String, dynamic> _salesAnalytics = <String, dynamic>{};
  Map<String, dynamic> _userAnalytics = <String, dynamic>{};
  Map<String, dynamic> _productAnalytics = <String, dynamic>{};
  Map<String, dynamic> _regionalAnalytics = <String, dynamic>{};

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  String _periodToApiValue() {
    switch (_selectedPeriod) {
      case 'Today':
        return '7d';
      case 'This Week':
        return '7d';
      case 'This Month':
        return '30d';
      case 'This Year':
        return '1y';
      default:
        return '30d';
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final period = _periodToApiValue();
      final sales = await _adminService.getSalesAnalytics(period: period);
      final users = await _adminService.getUserAnalytics(period: period);
      final products = await _adminService.getProductAnalytics();
      final regions = await _adminService.getRegionalAnalytics();

      if (!mounted) return;
      setState(() {
        _salesAnalytics = sales;
        _userAnalytics = users;
        _productAnalytics = products;
        _regionalAnalytics = regions;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );
    final totalRevenue = (_salesAnalytics['totalSales'] as num?)?.toDouble() ?? 0;
    final totalOrders = (_salesAnalytics['totalOrders'] as num?)?.toInt() ?? 0;
    final avgOrderValue = (_salesAnalytics['averageOrderValue'] as num?)?.toDouble() ?? 0;
    final commission = totalRevenue * 0.05;
    final newFarmers = (_userAnalytics['newFarmers'] as num?)?.toInt() ?? 0;
    final newBuyers = (_userAnalytics['newBuyers'] as num?)?.toInt() ?? 0;
    final totalNewUsers = (_userAnalytics['totalNewUsers'] as num?)?.toInt() ?? 0;
    final totalProducts = (_productAnalytics['totalProducts'] as num?)?.toInt() ?? 0;
    final activeProducts = (_productAnalytics['activeProducts'] as num?)?.toInt() ?? 0;
    final farmerShare = totalNewUsers > 0 ? ((newFarmers / totalNewUsers) * 100).toStringAsFixed(0) : '0';
    final buyerShare = totalNewUsers > 0 ? ((newBuyers / totalNewUsers) * 100).toStringAsFixed(0) : '0';

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.grey900,
          elevation: 0,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedPeriod,
                underline: const SizedBox.shrink(),
                items: _periods.map((final period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (final value) {
                  if (value != null) {
                    setState(() => _selectedPeriod = value);
                    _loadAnalytics();
                  }
                },
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAnalytics,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Revenue Overview
              _buildSectionHeader('Revenue Overview'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          currencyFormat.format(totalRevenue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                _selectedPeriod,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRevenueMetric('Orders', '$totalOrders'),
                        _buildRevenueMetric('Avg. Order', currencyFormat.format(avgOrderValue)),
                        _buildRevenueMetric('Commission', currencyFormat.format(commission)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Revenue Chart
              _buildSectionHeader('Revenue Trend'),
              const SizedBox(height: 12),
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _maxSalesY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.grey900,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItem: (final group, final groupIndex, final rod, final rodIndex) {
                          return BarTooltipItem(
                            '${_getMonthName(group.x)}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'UGX ${rod.toY.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (final value, final meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getMonthName(value.toInt()),
                                style: const TextStyle(
                                  color: AppColors.grey600,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (final value, final meta) {
                            return Text(
                              NumberFormat.compact().format(value),
                              style: const TextStyle(
                                color: AppColors.grey500,
                                fontSize: 10,
                              ),
                            );
                          },
                          reservedSize: 32,
                        ),
                      ),
                      topTitles:
                          const AxisTitles(),
                      rightTitles:
                          const AxisTitles(),
                    ),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (final value) => const FlLine(
                        color: AppColors.grey200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _salesBarGroups,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Analytics
              _buildSectionHeader('User Growth'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'New Farmers',
                      value: '$newFarmers',
                      change: '$farmerShare%',
                      icon: Icons.agriculture,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'New Buyers',
                      value: '$newBuyers',
                      change: '$buyerShare%',
                      icon: Icons.shopping_cart,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Products',
                      value: '$totalProducts',
                      change: '$activeProducts active',
                      icon: Icons.inventory_2,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'New Users',
                      value: '$totalNewUsers',
                      change: _selectedPeriod,
                      icon: Icons.person_add,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Distribution
              _buildSectionHeader('Sales by Category'),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (final event, final pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _buildPieSections(),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildCategoryLegends(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top Products
              _buildSectionHeader('Top Products'),
              const SizedBox(height: 12),
              ..._buildTopProducts(),
              const SizedBox(height: 24),

              // Regional Distribution
              _buildSectionHeader('Orders by Region'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ..._buildRegionalBars(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(final String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildRevenueMetric(final String label, final String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required final String title,
    required final String value,
    required final String change,
    required final IconData icon,
    required final Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(final int x, final double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primaryGreen,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  String _getMonthName(final int index) {
    final sortedKeys = (_salesAnalytics['salesByDate'] as Map<String, dynamic>? ?? <String, dynamic>{})
        .keys
        .toList()
      ..sort();
    if (sortedKeys.isEmpty || index >= sortedKeys.length) {
      return '';
    }
    final date = DateTime.tryParse(sortedKeys[index]);
    if (date == null) return '';
    return DateFormat('MMM').format(date);
  }

  List<MapEntry<String, double>> get _salesEntries {
    final map = _salesAnalytics['salesByDate'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final entries = map.entries.toList()..sort((final a, final b) => a.key.compareTo(b.key));

    return entries
        .map((final entry) {
          final value = entry.value as Map<String, dynamic>?;
          final amount = (value?['amount'] as num?)?.toDouble() ?? 0;
          return MapEntry(entry.key, amount);
        })
        .toList();
  }

  List<BarChartGroupData> get _salesBarGroups {
    final entries = _salesEntries;
    if (entries.isEmpty) {
      return [_makeBarGroup(0, 0)];
    }

    return entries.asMap().entries
        .map((final entry) => _makeBarGroup(entry.key, entry.value.value))
        .toList();
  }

  double get _maxSalesY {
    final entries = _salesEntries;
    if (entries.isEmpty) return 10;

    final maxValue = entries
        .map((final e) => e.value)
        .fold<double>(0, (final prev, final value) => value > prev ? value : prev);

    if (maxValue <= 0) return 10;
    return maxValue * 1.2;
  }

  List<PieChartSectionData> _buildPieSections() {
    final byCategory = _productAnalytics['byCategory'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final values = byCategory.values
        .map((final v) => (v as num?)?.toDouble() ?? 0)
        .toList();
    if (values.isEmpty || values.every((final v) => v == 0)) {
      return [
        PieChartSectionData(
          color: AppColors.grey200,
          value: 1,
          title: '',
          radius: 50,
        ),
      ];
    }
    final data = [
      (values.length > 0 ? values[0] : 1.0, AppColors.primaryGreen),
      (values.length > 1 ? values[1] : 1.0, AppColors.secondaryOrange),
      (values.length > 2 ? values[2] : 1.0, AppColors.info),
      (values.length > 3 ? values[3] : 1.0, AppColors.warning),
      (values.length > 4 ? values[4] : 1.0, AppColors.grey500),
    ];

    return data.asMap().entries.map((final entry) {
      final isTouched = entry.key == _touchedIndex;
      final radius = isTouched ? 60.0 : 50.0;

      return PieChartSectionData(
        color: entry.value.$2,
        value: entry.value.$1,
        title: '',
        radius: radius,
      );
    }).toList();
  }

  List<Widget> _buildCategoryLegends() {
    final byCategory = _productAnalytics['byCategory'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final entries = byCategory.entries.toList();
    final total = entries.fold<num>(0, (final sum, final e) => sum + ((e.value as num?) ?? 0));

    if (entries.isEmpty || total == 0) {
      return [_buildLegendItem('No data', AppColors.grey500, '0%')];
    }

    final colors = [
      AppColors.primaryGreen,
      AppColors.secondaryOrange,
      AppColors.info,
      AppColors.warning,
      AppColors.grey500,
    ];

    return entries.asMap().entries.take(5).map((final entry) {
      final value = (entry.value.value as num?) ?? 0;
      final percent = ((value / total) * 100).toStringAsFixed(0);
      return _buildLegendItem(
        entry.value.key,
        colors[entry.key % colors.length],
        '$percent%',
      );
    }).toList();
  }

  Widget _buildLegendItem(final String label, final Color color, final String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
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
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopProducts() {
    final products = (_productAnalytics['topByViews'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .take(5)
        .toList();

    if (products.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No product analytics available yet.'),
        ),
      ];
    }

    return products.asMap().entries.map((final entry) {
      final index = entry.key;
      final product = entry.value;
      final name = (product['name'] as String?) ?? 'Product';
      final views = (product['views_count'] as num?)?.toInt() ?? 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                    '📦',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$views views',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$views views',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  'Rank #${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRegionalBars() {
    final map = _regionalAnalytics['ordersByRegion'] as Map<String, dynamic>? ?? <String, dynamic>{};
    if (map.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(12),
          child: Text('No regional analytics available yet.'),
        ),
      ];
    }

    final entries = map.entries.toList();
    final maxCount = entries.fold<int>(0, (final prev, final e) {
      final count = ((e.value as Map<String, dynamic>)['count'] as num?)?.toInt() ?? 0;
      return count > prev ? count : prev;
    });

    return entries.map((final entry) {
      final value = entry.value as Map<String, dynamic>;
      final count = (value['count'] as num?)?.toInt() ?? 0;
      final percentage = maxCount == 0 ? 0.0 : count / maxCount;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildRegionBar(entry.key, percentage, count),
      );
    }).toList();
  }

  Widget _buildRegionBar(final String region, final double percentage, final int orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              region,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$orders orders',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
