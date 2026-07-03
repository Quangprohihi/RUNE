import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/payment_repository.dart';
import '../../routes/app_routes.dart';

class VietqrPaymentScreen extends StatelessWidget {
  const VietqrPaymentScreen({super.key, required this.checkout});

  final VietqrCheckout checkout;

  String get _amountText =>
      '${checkout.amountVnd.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]}.',
          )}đ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển khoản VietQR'),
        backgroundColor: const Color(0xFF48BB78),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Quét mã QR bằng app ngân hàng để chuyển khoản. Gói sẽ được kích '
                'hoạt sau khi khoản chuyển được xác nhận.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF45556C), height: 1.4),
              ),
              const SizedBox(height: 18),
              Center(
                child: Image.network(
                  checkout.qrImageUrl,
                  width: 240,
                  height: 240,
                  errorBuilder: (_, _, _) => Container(
                    width: 240,
                    height: 240,
                    alignment: Alignment.center,
                    color: const Color(0xFFF1F5F9),
                    child: const Text(
                      'Không tải được mã QR.\nDùng thông tin bên dưới để chuyển khoản.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF62748E)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: 'Ngân hàng', value: checkout.bankName),
              _DetailRow(
                label: 'Số tài khoản',
                value: checkout.accountNo,
                copyable: true,
              ),
              _DetailRow(label: 'Chủ tài khoản', value: checkout.accountName),
              _DetailRow(label: 'Số tiền', value: _amountText),
              _DetailRow(
                label: 'Nội dung',
                value: checkout.transferContent,
                copyable: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.paymentResult,
                      arguments: {
                        'orderId': checkout.orderId,
                        'status': 'pending',
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF48BB78),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Tôi đã chuyển khoản',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final String label;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF90A1B9)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1D293D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Color(0xFF48BB78)),
              tooltip: 'Sao chép',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép: $value')),
                );
              },
            ),
        ],
      ),
    );
  }
}
