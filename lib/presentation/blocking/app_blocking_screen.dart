import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_block_provider.dart';

class AppBlockingScreen extends StatefulWidget {
  const AppBlockingScreen({super.key});

  @override
  State<AppBlockingScreen> createState() => _AppBlockingScreenState();
}

class _AppBlockingScreenState extends State<AppBlockingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppBlockProvider>().refreshPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppBlockProvider>().refreshPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBlock = context.watch<AppBlockProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8FBF8), Color(0xFFEAF7FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(onBack: () => Navigator.of(context).pop()),
                const SizedBox(height: 18),
                _OverviewCard(appBlock: appBlock),
                const SizedBox(height: 16),
                _PermissionCard(appBlock: appBlock),
                const SizedBox(height: 16),
                const _HowItWorksCard(),
                if (appBlock.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    appBlock.error!,
                    style: AppTextStyles.muted.copyWith(
                      color: Colors.redAccent,
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryBlue),
        ),
        Expanded(
          child: Text(
            'FOCUS GUARD',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.appBlock});

  final AppBlockProvider appBlock;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE0F2FE),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Protect focus sessions',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Switch(
                value: appBlock.blockingEnabled,
                onChanged: appBlock.setBlockingEnabled,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Strict Focus keeps you inside ZenZoo while the timer is running. To leave, cancel the focus session.',
            style: AppTextStyles.muted.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.appBlock});

  final AppBlockProvider appBlock;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Required permissions', style: AppTextStyles.title),
          const SizedBox(height: 12),
          _PermissionRow(
            title: 'Usage Access',
            subtitle:
                'Lets ZenZoo detect when another app becomes active during focus.',
            granted: appBlock.hasUsageAccess,
            buttonLabel: 'Grant',
            onPressed: appBlock.openUsageAccessSettings,
          ),
          const Divider(height: 22),
          _PermissionRow(
            title: 'Notifications',
            subtitle:
                'Keeps the focus guard service visible while it is active.',
            granted: appBlock.hasNotificationPermission,
            buttonLabel: 'Allow',
            onPressed: appBlock.requestNotificationPermission,
          ),
          const Divider(height: 22),
          _PermissionRow(
            title: 'Accessibility',
            subtitle:
                'Required for Strict Focus to bring you back immediately after leaving ZenZoo.',
            granted: appBlock.hasAccessibilityPermission,
            buttonLabel: 'Open',
            onPressed: appBlock.openAccessibilitySettings,
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool granted;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.info_outline,
          color: granted ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1D293D),
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.muted),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: granted ? null : onPressed,
          child: Text(granted ? 'Granted' : buttonLabel),
        ),
      ],
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How Strict Focus works', style: AppTextStyles.title),
          const SizedBox(height: 12),
          const _GuardRule(
            icon: Icons.home_outlined,
            title: 'Leaving ZenZoo is blocked',
            text: 'Pressing Home or opening another app brings you back.',
          ),
          const SizedBox(height: 12),
          const _GuardRule(
            icon: Icons.notifications_outlined,
            title: 'Notifications can still appear',
            text: 'Opening a notification also returns you to focus.',
          ),
          const SizedBox(height: 12),
          const _GuardRule(
            icon: Icons.cancel_outlined,
            title: 'Cancel focus to leave',
            text: 'Use the Cancel focus button when you really need to stop.',
          ),
          const SizedBox(height: 14),
          Text(
            'Soft Focus with app allowlists can be added later.',
            style: AppTextStyles.muted.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuardRule extends StatelessWidget {
  const _GuardRule({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFE0F2FE),
          child: Icon(icon, color: AppColors.primaryBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  color: const Color(0xFF1D293D),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: AppTextStyles.muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
