import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rune/data/api/api_client.dart';
import 'package:rune/data/repositories/payment_repository.dart';

void main() {
  test('createVietqrPayment posts productCode and parses the QR payload', () async {
    late String capturedPath;
    final mock = MockClient((req) async {
      capturedPath = req.url.path;
      return http.Response(
        jsonEncode({
          'orderId': 'order-1',
          'qrImageUrl':
              'https://img.vietqr.io/image/970426-6102062004-compact2.png?amount=29000&addInfo=1720000123456',
          'bankName': 'MSB',
          'accountNo': '6102062004',
          'accountName': 'VU NGOC QUANG',
          'amountVnd': 29000,
          'transferContent': '1720000123456',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repo = PaymentRepository(
      ApiClient(baseUrl: 'http://test', httpClient: mock),
    );
    final checkout = await repo.createVietqrPayment('zen_pro_monthly');

    expect(capturedPath, '/payments/vietqr/create');
    expect(checkout.orderId, 'order-1');
    expect(checkout.bankName, 'MSB');
    expect(checkout.accountNo, '6102062004');
    expect(checkout.accountName, 'VU NGOC QUANG');
    expect(checkout.amountVnd, 29000);
    expect(checkout.transferContent, '1720000123456');
    expect(checkout.qrImageUrl, contains('img.vietqr.io'));
  });
}
