import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class FarmerAnalyticsScreen extends StatefulWidget {
  const FarmerAnalyticsScreen({super.key});

  @override
  State<FarmerAnalyticsScreen> createState() => _FarmerAnalyticsScreenState();
}

class _FarmerAnalyticsScreenState extends State<FarmerAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  Timer? _refreshTimer;
  bool _isLoading = true;
  String selectedPeriod = '7days';

  // Analytics Data
  int _totalProducts = 0;
  int _activeOrders = 0;
  int _completedOrders = 0;
  double _totalRevenue = 0;
  double _averageRating = 0;
  int _totalReviews = 0;
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, dynamic> _salesData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (final timer) {
      if (mounted) {
        _loadAnalytics(showLoader: false);
      }
    });
  }

  Future<void> _loadAnalytics({final bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final farmerId = authProvider.currentUser?.id;

      if (farmerId == null) return;

      // Fetch analytics from backend
      final response = await _apiService.get('/users/farmers/$farmerId/analytics', 
        queryParams: {'period': selectedPeriod}
      );

      if (!mounted) return;

      final recentOrdersRaw = response['recent_orders'] as List<dynamic>? ?? [];
      final topProductsRaw = response['top_products'] as List<dynamic>? ?? [];
      final salesDataRaw = response['sales_data'] as Map<String, dynamic>? ?? {};

      setState(() {
        _totalProducts = (response['total_products'] as int?) ?? 0;
        _activeOrders = (response['active_orders'] as int?) ?? 0;
        _completedOrders = (response['completed_orders'] as int?) ?? 0;
        _totalRevenue = ((response['total_revenue'] as num?) ?? 0).toDouble();
        _averageRating = ((response['average_rating'] as num?) ?? 0.0).toDouble();
        _totalReviews = (response['total_reviews'] as int?) ?? 0;
        _recentOrders = recentOrdersRaw
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
        _topProducts = topProductsRaw
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
        _salesData = Map<String, dynamic>.from(salesDataRaw);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load analytics: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedPeriod,
            onSelected: (final value) {
              setState(() => selectedPeriod = value);
              _loadAnalytics();
            },
            itemBuilder: (final context) => [
              const PopupMenuItem(value: '7days', child: Text('Last 7 Days')),
              const PopupMenuItem(value: '30days', child: Text('Last 30 Days')),
              const PopupMenuItem(value: '90days', child: Text('Last 3 Months')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Revenue Chart
                    _buildRevenueChart(),
                    const SizedBox(height: 24),

                    // Top Products
                    _buildTopProducts(),
                    const SizedBox(height: 24),

                    // Recent Orders
                    _buildRecentOrders(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Products',
                _totalProducts.toString(),
                Icons.inventory,
                AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Active Orders',
                _activeOrders.toString(),
                Icons.shopping_bag,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Completed',
                _completedOrders.toString(),
                Icons.check_circle,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Revenue',
                'UGX ${_formatNumber(_totalRevenue.toInt())}',
                Icons.monetization_on,
                AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Rating',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($_totalReviews reviews)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.grey600,
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
      ],
    );
  }

  Widget _buildSummaryCard(final String title, final String value, final IconData icon, final Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primaryGreen),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Revenue Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _salesData.isEmpty
                ? const Center(child: Text('No sales data available'))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getSalesSpots(),
                          isCurved: true,
                          color: AppColors.primaryGreen,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primaryGreen.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSalesSpots() {
    final values = _salesData.values
        .map((final value) => (value as num?)?.toDouble() ?? 0.0)
        .toList();

    if (values.isEmpty) {
      return [FlSpot.zero];
    }

    final maxValue = values.reduce((final a, final b) => a > b ? a : b);
    if (maxValue <= 0) {
      return List.generate(values.length, (final index) => FlSpot(index.toDouble(), 0));
    }

    return List.generate(
      values.length,
      (final index) => FlSpot(index.toDouble(), (values[index] / maxValue) * 10),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: AppColors.warning),
              SizedBox(width: 12),
              Text(
                'Top Selling Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_topProducts.isEmpty) const Center(child: Text('No product data available')) else Column(
                  children: _topProducts.take(5).map((final product) {
                    return _buildProductTile(
                      (product['name'] as String?) ?? 'Product',
                      (product['sold'] as int?) ?? 0,
                      ((product['revenue'] as num?) ?? 0.0).toDouble(),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildProductTile(final String name, final int sold, final double revenue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.eco,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$sold sold',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'UGX ${_formatNumber(revenue.toInt())}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.info),
              SizedBox(width: 12),
              Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentOrders.isEmpty) const Center(child: Text('No recent orders')) else Column(
                  children: _recentOrders.take(5).map((final order) {
                    return _buildOrderTile(
                      (order['order_number'] as String?) ?? 'N/A',
                      (order['buyer_name'] as String?) ?? 'Customer',
                      ((order['total'] as num?) ?? 0.0).toDouble(),
                      (order['status'] as String?) ?? 'pending',
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(final String orderNumber, final String buyer, final double total, final String status) {
    var statusColor = AppColors.warning;
    if (status == 'completed') statusColor = AppColors.success;
    if (status == 'cancelled') statusColor = AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$orderNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  buyer,
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
                'UGX ${_formatNumber(total.toInt())}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(final int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (final m) => '${m[1]},',
        );
  }
}
