import '../models/order_model.dart';
import 'api_service.dart';

enum PaymentProvider {
  marzPay,       // Unified mobile money (MTN & Airtel via MarzPay)
  mtnMobile,     // Legacy - prefer marzPay
  airtelMoney,   // Legacy - prefer marzPay
  card,
  cashOnDelivery,
}

class PaymentResult {

  PaymentResult({
    required this.success,
    this.transactionId,
    this.message,
    this.errorCode,
  });
  final bool success;
  final String? transactionId;
  final String? message;
  final String? errorCode;
}

class PaymentService {
  final ApiService _apiService = ApiService();

  // Initialize payment
  Future<PaymentResult> initiatePayment({
    required final String orderId,
    required final double amount,
    required final PaymentProvider provider,
    required final String phoneNumber,
  }) async {
    try {
      switch (provider) {
        case PaymentProvider.marzPay:
          return await _initiateMarzPayPayment(orderId, amount, phoneNumber);
        case PaymentProvider.mtnMobile:
          return await _initiateMTNPayment(orderId, amount, phoneNumber);
        case PaymentProvider.airtelMoney:
          return await _initiateAirtelPayment(orderId, amount, phoneNumber);
        case PaymentProvider.card:
          return await _initiateCardPayment(orderId, amount);
        case PaymentProvider.cashOnDelivery:
          return await _initiateCOD(orderId, amount);
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Payment initialization failed: $e',
      );
    }
  }

  // MarzPay Mobile Money payment (Unified MTN & Airtel)
  Future<PaymentResult> _initiateMarzPayPayment(
    final String orderId,
    final double amount,
    final String phoneNumber,
  ) async {
    try {
      // Use the unified /payments/initiate endpoint
      final response = await _apiService.post('/payments/initiate', body: {
        'orderId': orderId,
        'method': 'marzpay',
        'phone': phoneNumber,
      });

      if (response['success'] == true) {
        final data = response['data'];
        return PaymentResult(
          success: true,
          transactionId: data['transactionRef'] as String?,
          message: response['message'] as String? ?? 'Please confirm payment on your phone',
        );
      } else {
        return PaymentResult(
          success: false,
          message: (response['message'] as String?) ?? 'Payment failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Mobile money payment failed: $e',
      );
    }
  }

  // MTN Mobile Money payment (Legacy)
  Future<PaymentResult> _initiateMTNPayment(
    final String orderId,
    final double amount,
    final String phoneNumber,
  ) async {
    try {
      final response = await _apiService.post('/payments/initiate', body: {
        'orderId': orderId,
        'method': 'mtn_mobile',
        'phone': phoneNumber,
      });

      if (response['success'] == true) {
        final data = response['data'];

        return PaymentResult(
          success: true,
          transactionId: data['transactionRef'] as String?,
          message: response['message'] as String? ?? 'Please confirm payment on your phone',
        );
      } else {
        return PaymentResult(
          success: false,
          message: (response['message'] as String?) ?? 'Payment failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'MTN payment failed: $e',
      );
    }
  }

  // Airtel Money payment
  Future<PaymentResult> _initiateAirtelPayment(
    final String orderId,
    final double amount,
    final String phoneNumber,
  ) async {
    try {
      final response = await _apiService.post('/payments/initiate', body: {
        'orderId': orderId,
        'method': 'airtel_money',
        'phone': phoneNumber,
      });

      if (response['success'] == true) {
        final data = response['data'];

        return PaymentResult(
          success: true,
          transactionId: data['transactionRef'] as String?,
          message: response['message'] as String? ?? 'Please confirm payment on your phone',
        );
      } else {
        return PaymentResult(
          success: false,
          message: (response['message'] as String?) ?? 'Payment failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Airtel payment failed: $e',
      );
    }
  }

  // Card payment (Flutterwave/Paystack)
  Future<PaymentResult> _initiateCardPayment(
    final String orderId,
    final double amount,
  ) async {
    try {
      final response = await _apiService.post('/payments/initiate', body: {
        'orderId': orderId,
        'method': 'card',
      });

      if (response['success'] == true) {
        final data = response['data'];

        return PaymentResult(
          success: true,
          transactionId: data['transactionRef'] as String?,
          message: data['paymentUrl'] as String? ?? 'Card payment initialized',
        );
      } else {
        return PaymentResult(
          success: false,
          message: (response['message'] as String?) ?? 'Card payment initialization failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Card payment failed: $e',
      );
    }
  }

  // Cash on Delivery
  Future<PaymentResult> _initiateCOD(
    final String orderId,
    final double amount,
  ) async {
    try {
      await _recordPayment(
        orderId: orderId,
        amount: amount,
        provider: 'cash_on_delivery',
        status: 'pending',
      );

      // Update order payment status
      await _apiService.update('orders', orderId, {
        'payment_status': 'pending',
        'payment_method': 'cash_on_delivery',
        'updated_at': DateTime.now().toIso8601String(),
      });

      return PaymentResult(
        success: true,
        message: 'Cash on delivery selected. Pay when you receive your order.',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Failed to set COD: $e',
      );
    }
  }

  // Check payment status by order ID
  Future<String> checkPaymentStatus(final String orderId) async {
    try {
      final response = await _apiService.get('/payments/$orderId/status');
      final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final status = (data['status'] as String?)?.toLowerCase() ?? 'pending';

      switch (status) {
        case 'completed':
        case 'successful':
        case 'paid':
          return PaymentStatus.completed;
        case 'pending':
          return PaymentStatus.pending;
        case 'processing':
          return PaymentStatus.processing;
        case 'failed':
          return PaymentStatus.failed;
        default:
          return PaymentStatus.pending;
      }
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  // Verify payment callback
  Future<bool> verifyPayment(final String transactionId) async {
    try {
      final response = await _apiService.get('/payments/verify/$transactionId');
      
      if (response['verified'] == true) {
        // Update payment record
        await _updatePaymentStatus(transactionId, 'completed');
        
        // Update order payment status
        final payment = await _getPaymentByTransactionId(transactionId);
        if (payment != null) {
          await _apiService.update('orders', payment['order_id'] as String, {
            'payment_status': 'completed',
            'paid_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Process refund
  Future<PaymentResult> processRefund({
    required final String orderId,
    required final String transactionId,
    required final double amount,
    final String? reason,
  }) async {
    try {
      final response = await _apiService.post('/payments/$orderId/refund', body: {
        'amount': amount,
        'reason': reason,
      });

      if (response['status'] == 'success') {
        // Update order status
        await _apiService.update('orders', orderId, {
          'status': 'refunded',
          'payment_status': 'refunded',
          'refunded_at': DateTime.now().toIso8601String(),
          'refund_amount': amount,
          'updated_at': DateTime.now().toIso8601String(),
        });

        return PaymentResult(
          success: true,
          transactionId: response['refund_transaction_id'] as String?,
          message: 'Refund processed successfully',
        );
      } else {
        return PaymentResult(
          success: false,
          message: (response['message'] as String?) ?? 'Refund failed',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Refund processing failed: $e',
      );
    }
  }

  // Get payment history for order
  Future<List<Map<String, dynamic>>> getPaymentHistory(final String orderId) async {
    try {
      final payments = await _apiService.query(
        'payments',
        filters: {'order_id': orderId},
        orderBy: 'created_at',
      );
      return payments;
    } catch (e) {
      throw Exception('Failed to fetch payment history: $e');
    }
  }

  // Record payment in database
  Future<void> _recordPayment({
    required final String orderId,
    required final double amount,
    required final String provider,
    required final String status, final String? transactionId,
  }) async {
    await _apiService.insert('payments', {
      'order_id': orderId,
      'amount': amount,
      'provider': provider,
      'transaction_id': transactionId,
      'status': status,
      'currency': 'UGX',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Update payment status
  Future<void> _updatePaymentStatus(final String transactionId, final String status) async {
    try {
      final payments = await _apiService.query(
        'payments',
        filters: {'transaction_id': transactionId},
        limit: 1,
      );

      if (payments.isNotEmpty) {
        await _apiService.update('payments', payments[0]['id'] as String, {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  // Get payment by transaction ID
  Future<Map<String, dynamic>?> _getPaymentByTransactionId(
    final String transactionId,
  ) async {
    try {
      final payments = await _apiService.query(
        'payments',
        filters: {'transaction_id': transactionId},
        limit: 1,
      );

      return payments.isNotEmpty ? payments.first : null;
    } catch (e) {
      return null;
    }
  }

  // Validate phone number for mobile money
  bool validatePhoneNumber(final String phone, final PaymentProvider provider) {
    // Remove spaces and dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Check Uganda phone format
    if (!cleanPhone.startsWith('+256') && !cleanPhone.startsWith('0')) {
      return false;
    }

    final phoneDigits = cleanPhone.startsWith('+256')
        ? cleanPhone.substring(4)
        : cleanPhone.substring(1);

    if (phoneDigits.length != 9) return false;

    // MTN Uganda prefixes: 77, 78, 76
    if (provider == PaymentProvider.mtnMobile) {
      return phoneDigits.startsWith('77') ||
          phoneDigits.startsWith('78') ||
          phoneDigits.startsWith('76');
    }

    // Airtel Uganda prefixes: 70, 75, 74
    if (provider == PaymentProvider.airtelMoney) {
      return phoneDigits.startsWith('70') ||
          phoneDigits.startsWith('75') ||
          phoneDigits.startsWith('74');
    }

    return true;
  }

  // Format amount for display
  String formatAmount(final double amount) {
    return 'UGX ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (final m) => '${m[1]},',
        )}';
  }
}
