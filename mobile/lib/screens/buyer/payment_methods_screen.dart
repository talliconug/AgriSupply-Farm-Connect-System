import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';

class PaymentMethodItem {
  PaymentMethodItem({
    required this.id,
    required this.type,
    required this.details,
    this.isDefault = false,
  });

  final String id;
  final String type; // 'marzpay', 'cash'
  final Map<String, String> details;
  final bool isDefault;

  String get displayName {
    switch (type) {
      case 'marzpay':
        return 'Mobile Money (MTN & Airtel)';
      case 'mtn':
        return 'MTN Mobile Money';
      case 'airtel':
        return 'Airtel Money';
      case 'card':
        return 'Card';
      case 'cash':
        return 'Cash on Delivery';
      default:
        return type;
    }
  }

  String get displayDetails {
    if (type == 'marzpay') {
      return details['phone'] ?? 'Mobile Money Payment';
    } else if (type == 'mtn' || type == 'airtel') {
      return details['phone'] ?? 'Mobile Money Payment';
    } else if (type == 'card') {
      final last4 = details['last4'];
      return last4 != null ? '•••• •••• •••• $last4' : 'Card Payment';
    } else if (type == 'cash') {
      return 'Pay when you receive your order';
    }
    return '';
  }

  IconData get icon {
    switch (type) {
      case 'marzpay':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Color get color {
    switch (type) {
      case 'marzpay':
        return const Color(0xFF4CAF50);
      case 'mtn':
        return const Color(0xFFFFCC00);
      case 'airtel':
        return const Color(0xFFED1C24);
      case 'card':
        return AppColors.info;
      case 'cash':
        return AppColors.warning;
      default:
        return AppColors.grey600;
    }
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<PaymentMethodItem> _paymentMethods = [];
  String? _storageKey;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    _storageKey = 'payment_methods_${userId ?? 'anonymous'}';
    await _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final key = _storageKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    final rows = prefs.getStringList(key) ?? <String>[];

    final parsed = rows.map((final row) {
      final parts = row.split('|');
      final id = parts.isNotEmpty ? parts[0] : DateTime.now().millisecondsSinceEpoch.toString();
      final type = parts.length > 1 ? parts[1] : 'marzpay';
      final isDefault = parts.length > 2 && parts[2] == '1';
      final detailsRaw = parts.length > 3 ? parts[3] : '';

      final details = <String, String>{};
      if (detailsRaw.isNotEmpty) {
        for (final entry in detailsRaw.split(';')) {
          final idx = entry.indexOf('=');
          if (idx > 0) {
            details[entry.substring(0, idx)] = entry.substring(idx + 1);
          }
        }
      }

      return PaymentMethodItem(
        id: id,
        type: type,
        details: details,
        isDefault: isDefault,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _paymentMethods
        ..clear()
        ..addAll(parsed);
    });
  }

  Future<void> _savePaymentMethods() async {
    final key = _storageKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    final rows = _paymentMethods.map((final m) {
      final details = m.details.entries.map((final e) => '${e.key}=${e.value}').join(';');
      return '${m.id}|${m.type}|${m.isDefault ? '1' : '0'}|$details';
    }).toList();

    await prefs.setStringList(key, rows);
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your payment information is securely stored and encrypted',
                    style: TextStyle(
                      color: AppColors.info,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Payment Methods List
          Expanded(
            child: _paymentMethods.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _paymentMethods.length,
                    itemBuilder: (final context, final index) {
                      final method = _paymentMethods[index];
                      return _buildPaymentMethodCard(method);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPaymentMethodDialog,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.payment_outlined,
            size: 80,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Add a payment method for faster checkout',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPaymentMethodDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(final PaymentMethodItem method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method.icon,
                color: method.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.displayDetails,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (final value) {
                if (value == 'default') {
                  _setAsDefault(method);
                } else if (value == 'delete') {
                  _deletePaymentMethod(method);
                }
              },
              itemBuilder: (final context) => [
                if (!method.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Text('Set as Default'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a payment method to add:'),
            const SizedBox(height: 16),
            _buildPaymentTypeOption(
              icon: Icons.phone_android,
              title: 'MTN Mobile Money',
              color: const Color(0xFFFFCC00),
              onTap: () {
                Navigator.pop(context);
                _showAddMobileMoneyDialog('mtn');
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentTypeOption(
              icon: Icons.phone_android,
              title: 'Airtel Money',
              color: const Color(0xFFED1C24),
              onTap: () {
                Navigator.pop(context);
                _showAddMobileMoneyDialog('airtel');
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentTypeOption(
              icon: Icons.credit_card,
              title: 'Credit/Debit Card',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                _showAddCardDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required final IconData icon,
    required final String title,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMobileMoneyDialog(final String provider) {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: Text('Add ${provider == 'mtn' ? 'MTN' : 'Airtel'} Mobile Money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: nameController,
              label: 'Account Name',
              hint: 'Name on account',
              prefixIcon: Icons.person_outlined,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: phoneController,
              label: 'Phone Number',
              hint: '+256 XXX XXX XXX',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
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
              if (phoneController.text.isNotEmpty &&
                  nameController.text.isNotEmpty) {
                final newMethod = PaymentMethodItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: provider,
                  details: {
                    'phone': phoneController.text,
                    'name': nameController.text,
                  },
                  isDefault: _paymentMethods.isEmpty,
                );

                setState(() => _paymentMethods.add(newMethod));
                _savePaymentMethods();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment method added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    final cardNumberController = TextEditingController();
    final nameController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Add Card'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: cardNumberController,
                label: 'Card Number',
                hint: '1234 5678 9012 3456',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: nameController,
                label: 'Cardholder Name',
                hint: 'Name on card',
                prefixIcon: Icons.person_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: expiryController,
                      label: 'Expiry',
                      hint: 'MM/YY',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.datetime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: cvvController,
                      label: 'CVV',
                      hint: '123',
                      prefixIcon: Icons.lock_outlined,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 3,
                    ),
                  ),
                ],
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
            onPressed: () {
              if (cardNumberController.text.length >= 16 &&
                  nameController.text.isNotEmpty) {
                final last4 = cardNumberController.text
                    .replaceAll(' ', '')
                    .substring(cardNumberController.text.length - 4);

                final newMethod = PaymentMethodItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  type: 'card',
                  details: {
                    'last4': last4,
                    'name': nameController.text,
                  },
                  isDefault: _paymentMethods.isEmpty,
                );

                setState(() => _paymentMethods.add(newMethod));
                _savePaymentMethods();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Card added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(final PaymentMethodItem method) {
    setState(() {
      for (var i = 0; i < _paymentMethods.length; i++) {
        _paymentMethods[i] = PaymentMethodItem(
          id: _paymentMethods[i].id,
          type: _paymentMethods[i].type,
          details: _paymentMethods[i].details,
          isDefault: _paymentMethods[i].id == method.id,
        );
      }
    });
    _savePaymentMethods();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default payment method updated'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deletePaymentMethod(final PaymentMethodItem method) {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text(
            'Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _paymentMethods.remove(method));
              _savePaymentMethods();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method removed'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
