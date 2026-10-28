import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentService {
  static const String razorpayKey =
      String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: '');
  final Razorpay _razorpay = Razorpay();

  // 🚀 Point this to your Cloudflare Worker
  final String _apiUrl = 'https://rohini-api.rohinixerox.workers.dev';

  String? _currentOrderId;
  BuildContext? _currentContext;
  Function(bool, String?)? _onPaymentComplete;

  PaymentService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> openCheckout({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required BuildContext context,
    Function(bool success, String? paymentId)? onPaymentComplete,
  }) async {
    if (razorpayKey.isEmpty) {
      throw StateError('Razorpay is not configured. Provide RAZORPAY_KEY_ID at build time.');
    }
    // Production requires a server-created Razorpay order and server-side signature verification.
    // This client integration must not be used to mark an order paid on its own.
    _currentOrderId = orderId;
    _currentContext = context;
    _onPaymentComplete = onPaymentComplete;

    var options = {
      'key': razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': 'Rohini Xerox',
      'description': 'Print Order #$orderId',
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'theme': {'color': '#E91E8C'},
      'notes': {'order_id': orderId},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
      _onPaymentComplete?.call(false, null);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');

    if (_currentOrderId != null) {
      // Payment must be verified by the backend before fulfillment.
    }

    if (_currentContext?.mounted == true) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Payment submitted. Awaiting server verification.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    _onPaymentComplete?.call(false, response.paymentId); // Not verified yet.
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');

    if (_currentOrderId != null) {
      // Do not let an unauthenticated client change payment state.
    }

    if (_currentContext?.mounted == true) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${response.message ?? "Please try again"}',
          ),
          backgroundColor: Colors.red[900],
        ),
      );
    }

    _onPaymentComplete?.call(false, null);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  Future<void> _updatePaymentStatus(
    String orderId,
    String? paymentId,
    bool success,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Prepare the payload for Cloudflare
      final payload = {
        'paymentStatus': success ? 'completed' : 'failed',
        if (paymentId != null) 'paymentId': paymentId,
      };

      // Send the update to Cloudflare D1 instead of Firestore
      final response = await http.put(
        Uri.parse('$_apiUrl/orders/$orderId/payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Payment status updated in Cloudflare for $orderId');
      } else {
        debugPrint(
          '❌ Failed to update payment status in Cloudflare: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
