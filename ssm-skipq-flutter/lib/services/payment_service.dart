import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/order.dart';
import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  PaymentService(this._api);

  final ApiClient _api;
  Razorpay? _razorpay;

  Future<PaymentConfig> fetchConfig() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/payments/config');
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    return PaymentConfig.fromJson(data);
  }

  Future<RazorpayPaymentResult> openRazorpayCheckout({
    required RazorpayCheckoutDetails checkout,
    required String skipqOrderId,
    required String customerName,
    required String customerMobile,
    required String description,
  }) async {
    final completer = Completer<RazorpayPaymentResult>();

    _razorpay?.clear();
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (completer.isCompleted) return;
      completer.complete(
        RazorpayPaymentResult(
          razorpayPaymentId: response.paymentId ?? '',
          razorpayOrderId: response.orderId ?? checkout.orderId,
          razorpaySignature: response.signature ?? '',
        ),
      );
    });

    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      final message = response.message ?? 'Payment failed';
      completer.completeError(message);
    });

    _razorpay!.open({
      'key': checkout.keyId,
      'amount': checkout.amount,
      'currency': checkout.currency,
      'name': 'SkipQ@SSM',
      'description': description,
      'order_id': checkout.orderId,
      'prefill': {
        'contact': customerMobile,
        'name': customerName,
      },
      'notes': {
        'skipq_order_id': skipqOrderId,
      },
      'theme': {
        'color': '#FE4101',
      },
    });

    return completer.future;
  }

  Future<Order> verifyRazorpayPayment({
    required String orderId,
    required RazorpayPaymentResult payment,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/payments/razorpay/verify',
      data: {
        'orderId': orderId,
        'razorpayOrderId': payment.razorpayOrderId,
        'razorpayPaymentId': payment.razorpayPaymentId,
        'razorpaySignature': payment.razorpaySignature,
      },
    );
    final order = (response.data?['data'] as Map<String, dynamic>)['order'];
    return Order.fromJson(order as Map<String, dynamic>);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
