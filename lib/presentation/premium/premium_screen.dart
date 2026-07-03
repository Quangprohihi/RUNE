import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_text_styles.dart';
import '../../providers/payment_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../routes/app_routes.dart';
import '../payment/vietqr_payment_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _yearly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().load();
    });
  }

  Future<void> _upgrade() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Chọn phương thức thanh toán',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: Color(0xFF48BB78)),
              title: const Text('Chuyển khoản VietQR'),
              subtitle: const Text('Quét mã QR, kích hoạt sau khi xác nhận'),
              onTap: () => Navigator.of(sheetContext).pop('vietqr'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Color(0xFF2563EB)),
              title: const Text('Thẻ / VNPay'),
              subtitle: const Text('Thanh toán qua cổng VNPay'),
              onTap: () => Navigator.of(sheetContext).pop('vnpay'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || method == null) return;

    final productCode = _yearly ? 'zen_pro_yearly' : 'zen_pro_monthly';
    if (method == 'vietqr') {
      await _startVietqr(productCode);
    } else {
      await _startVnpay(productCode);
    }
  }

  Future<void> _startVietqr(String productCode) async {
    try {
      final checkout = await context.read<PaymentProvider>().createVietqrPayment(
        productCode,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VietqrPaymentScreen(checkout: checkout),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được mã VietQR: $error')),
      );
    }
  }

  Future<void> _startVnpay(String productCode) async {
    try {
      final checkout = await context.read<PaymentProvider>().createVnpayPayment(
        productCode,
      );
      final launched = await launchUrl(
        Uri.parse(checkout.paymentUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open VNPAY checkout.');
      }
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRoutes.paymentResult,
        arguments: {'orderId': checkout.orderId, 'status': 'pending'},
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start VNPAY payment: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final payment = context.watch<PaymentProvider>();
    final subscription = provider.subscription;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0FFF4), Color(0xFFE2FBE9), Color(0xFFD1F2D6)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 16),
                _BillingToggle(
                  yearly: _yearly,
                  onChanged: (value) => setState(() => _yearly = value),
                ),
                const SizedBox(height: 18),
                _StandardPlanCard(isCurrent: !subscription.isPremium),
                const SizedBox(height: 22),
                _ZenProCard(
                  isCurrent: subscription.isPremium,
                  isLoading: provider.isLoading || payment.isLoading,
                  price: _yearly ? '279k VND' : '29k VND',
                  onUpgrade: _upgrade,
                ),
                const SizedBox(height: 16),
                _MasterCard(
                  price: _yearly ? '470k VND' : '49k VND',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Master plan is planned after MVP.'),
                      ),
                    );
                  },
                ),
                if (subscription.expiresAt != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Zen Pro expires: ${subscription.expiresAt!.day}/${subscription.expiresAt!.month}/${subscription.expiresAt!.year}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.muted.copyWith(
                      color: const Color(0xFF62748E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Terms & Conditions apply',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.muted.copyWith(
                    color: const Color(0xCC90A1B9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left, color: Color(0xFF48BB78)),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'ELEVATE YOUR FOCUS',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppTextStyles.heading.copyWith(
                fontSize: 24,
                color: const Color(0xFF4D6EA3),
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  ),
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 4,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 202,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x80DCFCE7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BillingButton(
                label: 'Monthly',
                selected: !yearly,
                onTap: () => onChanged(false),
              ),
            ),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _BillingButton(
                    label: 'Yearly',
                    selected: yearly,
                    onTap: () => onChanged(true),
                  ),
                  const Positioned(
                    right: -9,
                    top: -13,
                    child: _DiscountBadge(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingButton extends StatelessWidget {
  const _BillingButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x3348BB78),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? const Color(0xFF48BB78) : const Color(0xFF62748E),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB900),
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '-20%',
        style: AppTextStyles.muted.copyWith(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StandardPlanCard extends StatelessWidget {
  const _StandardPlanCard({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return _PlanShell(
      background: Colors.white.withValues(alpha: 0.84),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PlanHeader(
            title: 'Standard',
            subtitle: 'Basic Focus',
            price: '0 VND',
            priceColor: Color(0xFF1D293D),
            subtitleColor: Color(0xFF90A1B9),
          ),
          const SizedBox(height: 18),
          const _FeatureLine(
            text: 'Basic Focus Timer',
            color: Color(0xFF45556C),
            muted: true,
          ),
          const SizedBox(height: 8),
          const _FeatureLine(
            text: '1 Habitat',
            color: Color(0xFF45556C),
            muted: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                disabledForegroundColor: const Color(0xFF90A1B9),
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(isCurrent ? 'Current Plan' : 'Included'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZenProCard extends StatelessWidget {
  const _ZenProCard({
    required this.isCurrent,
    required this.isLoading,
    required this.price,
    required this.onUpgrade,
  });

  final bool isCurrent;
  final bool isLoading;
  final String price;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _PlanShell(
          background: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF48BB78), Color(0xFF009966)],
          ),
          borderColor: const Color(0x8048BB78),
          shadowColor: const Color(0x4D48BB78),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlanHeader(
                title: 'Zen Pro',
                subtitle: 'Advanced Tools',
                price: price,
                priceColor: Colors.white,
                subtitleColor: const Color(0xFFD0FAE5),
                titleColor: Colors.white,
              ),
              const SizedBox(height: 22),
              const _FeatureLine(
                text: 'Advanced AI Planner',
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              const _FeatureLine(text: 'New Habitats', color: Colors.white),
              const SizedBox(height: 10),
              const _FeatureLine(
                text: 'Cloud Sync & Backup',
                color: Colors.white,
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || isCurrent ? null : onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.8,
                    ),
                    foregroundColor: const Color(0xFF48BB78),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black26,
                  ),
                  child: Text(
                    isCurrent
                        ? 'Current Plan'
                        : isLoading
                        ? 'Upgrading...'
                        : 'Upgrade Now',
                    style: AppTextStyles.label.copyWith(
                      color: const Color(0xFF48BB78),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -14,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB900), Color(0xFFFF8904)],
                ),
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'BEST VALUE',
                style: AppTextStyles.muted.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.price, required this.onTap});

  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PlanShell(
      background: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D293D), Color(0xFF022F2E)],
      ),
      borderColor: const Color(0x80005F5A),
      shadowColor: const Color(0x660F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanHeader(
            title: 'Master',
            subtitle: 'Ultimate Focus',
            price: price,
            priceColor: Colors.white,
            subtitleColor: const Color(0x9996F7E4),
            titleColor: const Color(0xFFFFB900),
          ),
          const SizedBox(height: 20),
          const _FeatureLine(
            text: 'Everything in Pro',
            color: Color(0xE6CBFBF1),
            checkColor: Color(0xFFFFB900),
            dark: true,
          ),
          const SizedBox(height: 8),
          const _FeatureLine(
            text: '9-Tailed Fox Avatar',
            color: Color(0xE6CBFBF1),
            checkColor: Color(0xFFFFB900),
            dark: true,
          ),
          const SizedBox(height: 8),
          const _FeatureLine(
            text: 'Lifetime Access Options',
            color: Color(0xE6CBFBF1),
            checkColor: Color(0xFFFFB900),
            dark: true,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB900),
                foregroundColor: const Color(0xFF0F172B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
                shadowColor: const Color(0x55F59E0B),
              ),
              child: Text(
                'Go Master',
                style: AppTextStyles.label.copyWith(
                  color: const Color(0xFF0F172B),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanShell extends StatelessWidget {
  const _PlanShell({
    required this.child,
    required this.background,
    this.borderColor = const Color(0xFFF1F5F9),
    this.shadowColor = const Color(0x08000000),
  });

  final Widget child;
  final Object background;
  final Color borderColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: background is Color ? background as Color : null,
        gradient: background is Gradient ? background as Gradient : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceColor,
    required this.subtitleColor,
    this.titleColor = const Color(0xFF314158),
  });

  final String title;
  final String subtitle;
  final String price;
  final Color priceColor;
  final Color subtitleColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  color: titleColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.label.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            text: price,
            style: AppTextStyles.title.copyWith(
              color: priceColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            children: [
              TextSpan(
                text: '/mo',
                style: AppTextStyles.muted.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({
    required this.text,
    required this.color,
    this.checkColor = const Color(0xFF5EE9B5),
    this.muted = false,
    this.dark = false,
  });

  final String text;
  final Color color;
  final Color checkColor;
  final bool muted;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: dark ? 18 : 20,
          height: dark ? 18 : 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: muted
                ? const Color(0xFFE2E8F0)
                : dark
                ? const Color(0xCC005F5A)
                : const Color(0x8000D492),
            border: muted ? null : Border.all(color: checkColor),
          ),
          child: Icon(
            Icons.check,
            size: muted ? 12 : 14,
            color: muted ? const Color(0xFFCBD5E1) : checkColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.label.copyWith(
              color: color,
              fontWeight: muted ? FontWeight.w600 : FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
