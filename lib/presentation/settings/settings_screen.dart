import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/native/focus_silence_service.dart';
import '../../models/user_settings.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final _focusSilence = const FocusSilenceService();
  bool _hasFocusSilenceAccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().load();
      _refreshFocusSilenceAccess();
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
      _refreshFocusSilenceAccess();
    }
  }

  Future<void> _refreshFocusSilenceAccess() async {
    final hasAccess = await _focusSilence.hasNotificationPolicyAccess();
    if (!mounted) return;
    setState(() => _hasFocusSilenceAccess = hasAccess);
  }

  Future<void> _openFocusSilenceSettings() async {
    await _focusSilence.openNotificationPolicySettings();
  }

  Future<void> _update(UserSettings settings) async {
    try {
      await context.read<SettingsProvider>().update(settings);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save settings.')));
    }
  }

  Future<void> _updateFocusSilence(bool enabled) async {
    if (enabled) {
      final hasAccess = await _focusSilence.hasNotificationPolicyAccess();
      if (mounted) {
        setState(() => _hasFocusSilenceAccess = hasAccess);
      }
      if (!hasAccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allow Do Not Disturb access so ZenZoo can silence notifications during focus.',
            ),
          ),
        );
        await _focusSilence.openNotificationPolicySettings();
      }
    }
    if (!mounted) return;
    await _update(
      context.read<SettingsProvider>().settings.copyWith(
        silenceNotificationsDuringFocus: enabled,
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<UserProvider>().logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final settings = provider.settings;
    final profile = provider.profile;
    final subscription = provider.subscription;

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
          child: provider.isLoading && provider.profile == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onBack: () => Navigator.of(context).pop()),
                      const SizedBox(height: 18),
                      _AccountCard(
                        name: profile?.displayName ?? 'Friend',
                        email: profile?.email ?? 'No email',
                        plan: subscription.displayName,
                      ),
                      const SizedBox(height: 16),
                      _SettingsCard(
                        settings: settings,
                        hasFocusSilenceAccess: _hasFocusSilenceAccess,
                        onChanged: _update,
                        onFocusSilenceChanged: _updateFocusSilence,
                        onOpenFocusSilenceSettings: _openFocusSilenceSettings,
                      ),
                      const SizedBox(height: 16),
                      _InfoCard(
                        title: 'Runtime',
                        lines: [
                          AppConstants.useTestFocusDuration
                              ? 'Test timer is ON: focus and break run ${AppConstants.testFocusSeconds}s.'
                              : 'Production timer is ON.',
                          'Backend API is connected through your local Docker service.',
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.appBlocking),
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Focus Guard'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.premium),
                        child: const Text('Manage Go Pro'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                        ),
                        child: const Text('Logout'),
                      ),
                      if (provider.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          provider.error!,
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
            'SETTINGS',
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.plan,
  });

  final String name;
  final String email;
  final String plan;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE0F2FE),
            child: Icon(Icons.person, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.title),
                Text(email, style: AppTextStyles.muted),
              ],
            ),
          ),
          _PlanBadge(plan: plan),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.settings,
    required this.hasFocusSilenceAccess,
    required this.onChanged,
    required this.onFocusSilenceChanged,
    required this.onOpenFocusSilenceSettings,
  });

  final UserSettings settings;
  final bool hasFocusSilenceAccess;
  final ValueChanged<UserSettings> onChanged;
  final ValueChanged<bool> onFocusSilenceChanged;
  final VoidCallback onOpenFocusSilenceSettings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound'),
            subtitle: const Text('Play small cues when focus ends'),
            value: settings.soundEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(soundEnabled: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vibration'),
            subtitle: const Text('Use haptic feedback for key actions'),
            value: settings.vibrationEnabled,
            onChanged: (value) =>
                onChanged(settings.copyWith(vibrationEnabled: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Focus reminders'),
            subtitle: const Text('Let Kiki remind you to keep the streak'),
            value: settings.focusReminders,
            onChanged: (value) =>
                onChanged(settings.copyWith(focusReminders: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Silence notifications during focus'),
            subtitle: const Text(
              'Uses Android Do Not Disturb while focus is running',
            ),
            value: settings.silenceNotificationsDuringFocus,
            onChanged: onFocusSilenceChanged,
          ),
          if (settings.silenceNotificationsDuringFocus) ...[
            const Divider(height: 22),
            _DndPermissionRow(
              granted: hasFocusSilenceAccess,
              onPressed: onOpenFocusSilenceSettings,
            ),
          ],
        ],
      ),
    );
  }
}

class _DndPermissionRow extends StatelessWidget {
  const _DndPermissionRow({required this.granted, required this.onPressed});

  final bool granted;
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
                'Do Not Disturb access',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1D293D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                granted
                    ? 'ZenZoo can silence notifications while focus is running.'
                    : 'Open Android settings and allow ZenZoo to control Do Not Disturb.',
                style: AppTextStyles.muted,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: granted ? null : onPressed,
          child: Text(granted ? 'Granted' : 'Open'),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line, style: AppTextStyles.muted),
            ),
          ),
        ],
      ),
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

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});

  final String plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: plan == 'Premium'
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        plan,
        style: AppTextStyles.muted.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
