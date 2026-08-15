class PaymentConfig {
  const PaymentConfig({
    required this.enabled,
    required this.keyId,
    required this.testMode,
  });

  final bool enabled;
  final String keyId;
  final bool testMode;

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    final razorpay = json['razorpay'] as Map<String, dynamic>? ?? {};
    return PaymentConfig(
      enabled: razorpay['enabled'] as bool? ?? false,
      keyId: razorpay['keyId'] as String? ?? '',
      testMode: razorpay['testMode'] as bool? ?? false,
    );
  }
}

class RazorpayCheckoutDetails {
  const RazorpayCheckoutDetails({
    required this.orderId,
    required this.keyId,
    required this.amount,
    required this.currency,
    required this.testMode,
  });

  final String orderId;
  final String keyId;
  final int amount;
  final String currency;
  final bool testMode;

  factory RazorpayCheckoutDetails.fromJson(Map<String, dynamic> json) {
    return RazorpayCheckoutDetails(
      orderId: json['orderId'] as String? ?? '',
      keyId: json['keyId'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      testMode: json['testMode'] as bool? ?? false,
    );
  }
}

class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });

  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
}
