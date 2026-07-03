import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart';
import '../../providers/payment_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../routes/app_routes.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({
    super.key,
    this.initialOrderId,
    this.initialStatus,
  });

  final String? initialOrderId;
  final String? initialStatus;

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  Timer? _pollTimer;
  String? _orderId;
  String _status = 'pending';
  int _pollCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _orderId = args['orderId'] as String?;
      _status = args['status'] as String? ?? 'pending';
    }
    _orderId ??= widget.initialOrderId;
    _status = widget.initialStatus ?? _status;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStatus();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_pollCount >= 40 || _isTerminal(_status)) {
          _pollTimer?.cancel();
          return;
        }
        _refreshStatus();
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _isTerminal(String status) {
    return status == 'paid' ||
        status == 'failed' ||
        status == 'canceled' ||
        status == 'expired' ||
        status == 'review';
  }

  Future<void> _refreshStatus() async {
    final orderId = _orderId;
    if (orderId == null || orderId.isEmpty) return;

    _pollCount++;
    try {
      final status = await context.read<PaymentProvider>().loadStatus(orderId);
      if (!mounted) return;
      setState(() => _status = status.status);
      if (status.isPaid) {
        await context.read<SubscriptionProvider>().load();
        _pollTimer?.cancel();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentProvider>();
    final visual = _PaymentVisual.fromStatus(_status);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: visual.gradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(visual.icon, size: 92, color: visual.color),
                const SizedBox(height: 18),
                Text(
                  visual.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(
                    color: const Color(0xFF1D293D),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  visual.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF45556C),
                    height: 1.4,
                  ),
                ),
                if (_orderId != null) ...[
                  const SizedBox(height: 18),
                  SelectableText(
                    'Order ID: $_orderId',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.muted.copyWith(
                      color: const Color(0xFF62748E),
                    ),
                  ),
                ],
                const Spacer(),
                if (payment.isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 18),
                ],
                ElevatedButton(
                  onPressed: _refreshStatus,
                  child: const Text('Refresh status'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                  },
                  child: const Text('Back to home'),
                ),
                if (_status != 'paid') ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.premium);
                    },
                    child: const Text('Try payment again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentVisual {
  const _PaymentVisual({
    required this.color,
    required this.gradient,
    required this.icon,
    required this.message,
    required this.title,
  });

  factory _PaymentVisual.fromStatus(String status) {
    if (status == 'paid') {
      return const _PaymentVisual(
        color: Color(0xFF16A34A),
        gradient: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        icon: Icons.check_circle,
        title: 'Zen Pro activated',
        message:
            'Your payment was confirmed. Premium features are now unlocked.',
      );
    }
    if (status == 'failed' || status == 'canceled' || status == 'expired') {
      return const _PaymentVisual(
        color: Color(0xFFDC2626),
        gradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
        icon: Icons.cancel,
        title: 'Payment failed',
        message:
            'The payment was not completed. You can try again whenever you are ready.',
      );
    }
    if (status == 'review') {
      return const _PaymentVisual(
        color: Color(0xFFF59E0B),
        gradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        icon: Icons.manage_search,
        title: 'Payment under review',
        message:
            'We received a payment signal, but it needs manual review before Zen Pro is activated.',
      );
    }
    return const _PaymentVisual(
      color: Color(0xFF2563EB),
      gradient: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
      icon: Icons.hourglass_top,
      title: 'Confirming payment',
      message:
          'If you already paid, ZenZoo is confirming your payment. This can take up to a few minutes.',
    );
  }

  final Color color;
  final List<Color> gradient;
  final IconData icon;
  final String message;
  final String title;
}
