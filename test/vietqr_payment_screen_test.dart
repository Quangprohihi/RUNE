import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rune/data/repositories/payment_repository.dart';
import 'package:rune/presentation/payment/vietqr_payment_screen.dart';

void main() {
  testWidgets('renders bank details and the transfer content', (tester) async {
    const checkout = VietqrCheckout(
      orderId: 'order-1',
      qrImageUrl: 'https://img.vietqr.io/image/970426-6102062004-compact2.png',
      bankName: 'MSB',
      accountNo: '6102062004',
      accountName: 'VU NGOC QUANG',
      amountVnd: 29000,
      transferContent: '1720000123456',
    );

    await tester.pumpWidget(
      const MaterialApp(home: VietqrPaymentScreen(checkout: checkout)),
    );

    expect(find.text('6102062004'), findsOneWidget);
    expect(find.text('VU NGOC QUANG'), findsOneWidget);
    expect(find.text('1720000123456'), findsOneWidget);
    expect(find.textContaining('29'), findsWidgets);
    expect(find.text('Tôi đã chuyển khoản'), findsOneWidget);
  });
}
