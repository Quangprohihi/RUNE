import '../../models/subscription.dart';
import '../api/api_client.dart';

class PaymentRepository {
  const PaymentRepository(this._api);

  final ApiClient _api;

  Future<PaymentCheckout> createVnpayPayment(String productCode) async {
    final response =
        await _api.post(
              '/payments/vnpay/create',
              body: {'productCode': productCode},
            )
            as Map<String, dynamic>;
    return PaymentCheckout.fromJson(response);
  }

  Future<PaymentStatus> getPaymentStatus(String orderId) async {
    final response =
        await _api.get('/payments/$orderId/status') as Map<String, dynamic>;
    return PaymentStatus.fromJson(response);
  }
}

class PaymentCheckout {
  const PaymentCheckout({required this.orderId, required this.paymentUrl});

  factory PaymentCheckout.fromJson(Map<String, dynamic> json) {
    return PaymentCheckout(
      orderId: json['orderId'] as String? ?? '',
      paymentUrl: json['paymentUrl'] as String? ?? '',
    );
  }

  final String orderId;
  final String paymentUrl;
}

class PaymentStatus {
  const PaymentStatus({
    required this.orderId,
    required this.status,
    required this.productCode,
    required this.amountVnd,
    this.subscription,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>? ?? const {};
    final subscriptionJson = json['subscription'] as Map<String, dynamic>?;
    return PaymentStatus(
      orderId: order['id'] as String? ?? '',
      status: order['status'] as String? ?? 'pending',
      productCode: order['productCode'] as String? ?? '',
      amountVnd: order['amountVnd'] as int? ?? 0,
      subscription: subscriptionJson == null
          ? null
          : Subscription.fromJson(subscriptionJson),
    );
  }

  final String orderId;
  final String status;
  final String productCode;
  final int amountVnd;
  final Subscription? subscription;

  bool get isPaid => status == 'paid';
  bool get isFailed =>
      status == 'failed' || status == 'canceled' || status == 'expired';
}
