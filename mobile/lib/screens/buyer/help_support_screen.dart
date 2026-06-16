import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Contact Support Section
          _buildSectionHeader(context, 'Contact Us'),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.phone,
            title: 'Phone Support',
            subtitle: '+256 753 520 987',
            color: AppColors.primaryGreen,
            onTap: () => _launchPhone('+256753520987'),
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'agrisupply@gmail.com',
            color: AppColors.info,
            onTap: () => _launchEmail('agrisupply@gmail.com'),
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.chat_bubble_outline,
            title: 'WhatsApp',
            subtitle: 'Chat with us on WhatsApp',
            color: AppColors.success,
            onTap: () => _launchWhatsApp('+256753520987'),
          ),
          const SizedBox(height: 24),

          // FAQ Section
          _buildSectionHeader(context, 'Frequently Asked Questions'),
          const SizedBox(height: 12),
          _buildFAQItem(
            context,
            question: 'How do I place an order?',
            answer: 'Browse products, add items to your cart, then proceed to checkout. '
                'Select your delivery address and payment method to complete your order.',
          ),
          _buildFAQItem(
            context,
            question: 'What payment methods are supported?',
            answer: 'We accept Mobile Money (MTN and Airtel) and Cash on Delivery for most locations.',
          ),
          _buildFAQItem(
            context,
            question: 'How long does delivery take?',
            answer: 'Delivery typically takes 1-3 business days depending on your location. '
                'Central region orders are usually delivered within 24 hours.',
          ),
          _buildFAQItem(
            context,
            question: 'Can I cancel my order?',
            answer: 'Yes, you can cancel your order before it has been shipped. '
                'Go to My Orders, select the order, and tap Cancel Order.',
          ),
          _buildFAQItem(
            context,
            question: 'What is your refund policy?',
            answer: 'We offer full refunds for damaged or incorrect items. '
                'Contact support within 24 hours of delivery to initiate a refund.',
          ),
          _buildFAQItem(
            context,
            question: 'How do I track my order?',
            answer: 'Go to My Orders and tap on any order to see its current status and tracking information.',
          ),
          const SizedBox(height: 24),

          // Quick Actions
          _buildSectionHeader(context, 'Quick Actions'),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            icon: Icons.report_problem_outlined,
            title: 'Report an Issue',
            color: AppColors.warning,
            onTap: () => _showReportDialog(context),
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            color: AppColors.info,
            onTap: () => _showFeedbackDialog(context),
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            icon: Icons.help_outline,
            title: 'App Tutorial',
            color: AppColors.primaryGreen,
            onTap: () => _showTutorial(context),
          ),
          const SizedBox(height: 24),

          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'AgriSupply',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(color: AppColors.grey600, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  '© 2026 AgriSupply. All rights reserved.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(final BuildContext context, final String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildContactCard({
    required final IconData icon,
    required final String title,
    required final String subtitle,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildFAQItem(
    final BuildContext context, {
    required final String question,
    required final String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required final IconData icon,
    required final String title,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Future<void> _launchPhone(final String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(final String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(final String phoneNumber) async {
    final uri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showReportDialog(final BuildContext context) {
    final issueController = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the issue you encountered:'),
            const SizedBox(height: 16),
            TextField(
              controller: issueController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send issue report to backend
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your report!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(final BuildContext context) {
    final feedbackController = TextEditingController();
    
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("We'd love to hear your thoughts!"),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Your feedback...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Send feedback to backend
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTutorial(final BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('App Tutorial'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Browse Products',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Explore fresh produce from local farmers.'),
              SizedBox(height: 12),
              Text(
                '2. Add to Cart',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Select quantity and add items to your cart.'),
              SizedBox(height: 12),
              Text(
                '3. Checkout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Enter delivery details and choose payment method.'),
              SizedBox(height: 12),
              Text(
                '4. Track Order',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Monitor your order status in My Orders.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
