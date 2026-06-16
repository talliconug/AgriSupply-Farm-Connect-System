import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/loading_overlay.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  Map<String, dynamic> _dashboard = <String, dynamic>{};
  Map<String, dynamic> _settings = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final dashboard = await _adminService.getDashboard();
      final settings = await _adminService.getSettings();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _settings = settings;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load admin data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showBroadcastDialog() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String? role;

    await showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Send Broadcast'),
        content: StatefulBuilder(
          builder: (final context, final setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Target role (optional)'),
                items: const [
                  DropdownMenuItem(value: 'buyer', child: Text('Buyers')),
                  DropdownMenuItem(value: 'farmer', child: Text('Farmers')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                ],
                onChanged: (final v) => setModalState(() => role = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final message = messageController.text.trim();
              if (title.isEmpty || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title and message are required')),
                );
                return;
              }
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _adminService.sendBroadcast(
                  title: title,
                  message: message,
                  targetRole: role,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Broadcast sent successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Broadcast failed: $e')),
                );
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    titleController.dispose();
    messageController.dispose();
  }

  Future<void> _toggleMaintenanceMode(final bool value) async {
    setState(() => _isLoading = true);
    try {
      final updated = await _adminService.updateSettings({'maintenance_mode': value});
      if (!mounted) return;
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Maintenance mode enabled' : 'Maintenance mode disabled'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    final users = (_dashboard['users'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final products = (_dashboard['products'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final orders = (_dashboard['orders'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final maintenanceMode = (_settings['maintenance_mode'] as bool?) ?? false;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          actions: [
            IconButton(
              onPressed: _loadAdminData,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadAdminData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _metricCard('Users', '${users['total'] ?? 0}', Icons.people, AppColors.info),
                  _metricCard('Products', '${products['total'] ?? 0}', Icons.inventory_2, AppColors.success),
                  _metricCard('Orders', '${orders['total'] ?? 0}', Icons.receipt_long, AppColors.primaryGreen),
                  _metricCard('Revenue', _formatCompactCurrency((orders['revenue'] as num?)?.toDouble() ?? 0), Icons.payments, AppColors.secondaryOrange),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _actionTile(
                icon: Icons.manage_accounts,
                title: 'User Management',
                subtitle: 'Verify, suspend, and manage all users',
                onTap: () => Navigator.pushNamed(context, AppRoutes.userManagement),
              ),
              _actionTile(
                icon: Icons.category,
                title: 'Product Management',
                subtitle: 'Approve/reject listings and moderate catalog',
                onTap: () => Navigator.pushNamed(context, AppRoutes.productManagement),
              ),
              _actionTile(
                icon: Icons.local_shipping,
                title: 'Order Management',
                subtitle: 'Monitor and update order statuses',
                onTap: () => Navigator.pushNamed(context, AppRoutes.orderManagement),
              ),
              _actionTile(
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'Live sales, users, and regional insights',
                onTap: () => Navigator.pushNamed(context, AppRoutes.analytics),
              ),
              _actionTile(
                icon: Icons.campaign,
                title: 'Broadcast Notification',
                subtitle: 'Send real in-app notifications to users',
                onTap: _showBroadcastDialog,
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                value: maintenanceMode,
                onChanged: _toggleMaintenanceMode,
                title: const Text('Maintenance Mode'),
                subtitle: const Text('Block normal user traffic while performing updates'),
                activeColor: AppColors.primaryGreen,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.signOut();
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (final route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Platform Control Center',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(final String title, final String value, final IconData icon, final Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: AppColors.grey600)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required final IconData icon,
    required final String title,
    required final String subtitle,
    required final VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _formatCompactCurrency(final double amount) {
    return 'UGX ${NumberFormat.compact().format(amount)}';
  }
}
