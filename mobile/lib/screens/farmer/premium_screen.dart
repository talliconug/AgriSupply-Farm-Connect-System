import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  int _selectedPlan = 1; // 0: Monthly, 1: Yearly

  final List<PremiumPlan> _plans = [
    PremiumPlan(
      title: 'Monthly',
      price: 50000,
      period: 'month',
      savings: 0,
    ),
    PremiumPlan(
      title: 'Yearly',
      price: 450000,
      period: 'year',
      savings: 150000,
      isPopular: true,
    ),
  ];

  final List<PremiumFeature> _features = [
    PremiumFeature(
      icon: Icons.star,
      title: 'Priority Listing',
      description: 'Your products appear at the top of search results',
    ),
    PremiumFeature(
      icon: Icons.verified,
      title: 'Verified Badge',
      description: 'Stand out with a verified farmer badge',
    ),
    PremiumFeature(
      icon: Icons.smart_toy,
      title: 'AI Assistant',
      description: 'Get personalized farming advice and market insights',
    ),
    PremiumFeature(
      icon: Icons.analytics,
      title: 'Advanced Analytics',
      description: 'Detailed sales reports and performance metrics',
    ),
    PremiumFeature(
      icon: Icons.inventory,
      title: 'Unlimited Products',
      description: 'List unlimited products without restrictions',
    ),
    PremiumFeature(
      icon: Icons.support_agent,
      title: 'Priority Support',
      description: '24/7 dedicated customer support',
    ),
    PremiumFeature(
      icon: Icons.campaign,
      title: 'Promotional Tools',
      description: 'Create discounts and special offers',
    ),
    PremiumFeature(
      icon: Icons.remove_red_eye,
      title: 'Insights Dashboard',
      description: 'See who viewed your products and farm',
    ),
  ];

  @override
  Widget build(final BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_UG',
      symbol: 'UGX ',
      decimalDigits: 0,
    );

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // App Bar with Gradient
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.secondaryOrange,
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondaryOrange,
                        Color(0xFFFF6D00),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AgriSupply Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Grow your farming business',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Selection
                    const Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _plans.asMap().entries.map((final entry) {
                        final index = entry.key;
                        final plan = entry.value;
                        final isSelected = _selectedPlan == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPlan = index),
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index == 0 ? 8 : 0,
                                left: index == 1 ? 8 : 0,
                              ),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.secondaryOrange.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.secondaryOrange
                                      : AppColors.grey200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      if (plan.isPopular)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryOrange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Best Value',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (plan.isPopular)
                                        const SizedBox(height: 8),
                                      Text(
                                        plan.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.secondaryOrange
                                              : AppColors.grey700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        currencyFormat.format(plan.price),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? AppColors.secondaryOrange
                                              : AppColors.grey900,
                                        ),
                                      ),
                                      Text(
                                        '/${plan.period}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.grey600,
                                        ),
                                      ),
                                      if (plan.savings > 0) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Save ${currencyFormat.format(plan.savings)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.secondaryOrange,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Features
                    const Text(
                      'Premium Features',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(_features.map(_buildFeatureItem)),

                    const SizedBox(height: 32),

                    // Comparison
                    _buildComparisonCard(),

                    const SizedBox(height: 32),

                    // Testimonials
                    const Text(
                      'What Farmers Say',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTestimonialCard(
                      name: 'John Mukasa',
                      location: 'Mukono',
                      quote:
                          'Premium helped me increase my sales by 300% in just 3 months!',
                      rating: 5,
                    ),
                    _buildTestimonialCard(
                      name: 'Sarah Nakato',
                      location: 'Jinja',
                      quote:
                          'The AI assistant gives me great advice for my crops. Worth every shilling!',
                      rating: 5,
                    ),

                    const SizedBox(height: 32),

                    // FAQ
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFAQItem(
                      question: 'Can I cancel anytime?',
                      answer:
                          'Yes, you can cancel your subscription at any time. Your premium features will remain active until the end of your billing period.',
                    ),
                    _buildFAQItem(
                      question: 'How do I pay?',
                      answer:
                          'We accept Mobile Money (MTN and Airtel) and card payments. All payments are secure and encrypted.',
                    ),
                    _buildFAQItem(
                      question: 'Is there a free trial?',
                      answer:
                          'Yes! New users get a 7-day free trial of Premium features. No credit card required.',
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plans[_selectedPlan].title,
                        style: const TextStyle(
                          color: AppColors.grey600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        currencyFormat.format(_plans[_selectedPlan].price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: CustomButton(
                        text: 'Start Free Trial',
                        onPressed: _subscribe,
                        backgroundColor: AppColors.secondaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '7-day free trial • Cancel anytime',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.grey600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(final PremiumFeature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              feature.icon,
              color: AppColors.secondaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  feature.description,
                  style: const TextStyle(
                    color: AppColors.grey600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic vs Premium',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: [
              const TableRow(
                children: [
                  Text('Feature', style: TextStyle(fontWeight: FontWeight.w600)),
                  Center(
                    child: Text('Basic',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Center(
                    child: Text('Premium',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryOrange)),
                  ),
                ],
              ),
              _buildComparisonRow('Product Listings', '5', 'Unlimited'),
              _buildComparisonRow('Search Priority', 'Low', 'High'),
              _buildComparisonRow('AI Assistant', '❌', '✓'),
              _buildComparisonRow('Analytics', 'Basic', 'Advanced'),
              _buildComparisonRow('Support', 'Email', '24/7'),
              _buildComparisonRow('Verified Badge', '❌', '✓'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildComparisonRow(final String feature, final String basic, final String premium) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(feature, style: const TextStyle(fontSize: 13)),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              basic,
              style: TextStyle(
                fontSize: 13,
                color: basic == '❌' ? AppColors.error : AppColors.grey600,
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              premium,
              style: TextStyle(
                fontSize: 13,
                color: premium == '✓' ? AppColors.success : AppColors.grey900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialCard({
    required final String name,
    required final String location,
    required final String quote,
    required final int rating,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.grey200,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey700,
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
                      location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (final index) => const Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.secondaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$quote"',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required final String question,
    required final String answer,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: AppColors.grey600,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);

    try {
      // Show payment method selection
      final paymentMethod = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (final context) => _buildPaymentSheet(),
      );

      if (paymentMethod != null && mounted) {
        // Process payment
        await Future<void>.delayed(const Duration(seconds: 2));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium subscription activated!'),
            backgroundColor: AppColors.success,
          ),
        );

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUser();

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process payment'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPaymentSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildPaymentOption(
            icon: 'assets/images/mtn.png',
            title: 'MTN Mobile Money',
            subtitle: 'Pay with MTN MoMo',
            onTap: () => Navigator.pop(context, 'mtn'),
          ),
          _buildPaymentOption(
            icon: 'assets/images/airtel.png',
            title: 'Airtel Money',
            subtitle: 'Pay with Airtel Money',
            onTap: () => Navigator.pop(context, 'airtel'),
          ),
          _buildPaymentOption(
            title: 'Credit/Debit Card',
            subtitle: 'Visa, Mastercard',
            iconWidget: const Icon(Icons.credit_card, size: 32),
            onTap: () => Navigator.pop(context, 'card'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required final String title, required final String subtitle, required final VoidCallback onTap, final String? icon,
    final Widget? iconWidget,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: iconWidget ??
            (icon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(icon, fit: BoxFit.contain),
                  )
                : const Icon(Icons.payment)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class PremiumPlan {

  PremiumPlan({
    required this.title,
    required this.price,
    required this.period,
    required this.savings,
    this.isPopular = false,
  });
  final String title;
  final double price;
  final String period;
  final double savings;
  final bool isPopular;
}

class PremiumFeature {

  PremiumFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;
}
