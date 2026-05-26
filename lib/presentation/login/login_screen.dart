import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    await context.read<UserProvider>().mockLogin(_emailController.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.accentSky],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 28,
                child: CircleAvatar(
                  backgroundColor: AppColors.accentTeal,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 78),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌊', style: TextStyle(fontSize: 48)),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.heading.copyWith(fontSize: 40),
                          children: const [
                            TextSpan(
                              text: 'Zen',
                              style: TextStyle(color: AppColors.accentTeal),
                            ),
                            TextSpan(
                              text: 'Zoo',
                              style: TextStyle(color: AppColors.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                top: 220,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(38, 30, 38, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(60),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          'Get Started!',
                          style: AppTextStyles.heading.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your email to sign up for this app',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'email@domain.com',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _continue,
                          child: const Text('Continue'),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text('or', style: AppTextStyles.muted),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _SocialButton(
                          icon: 'G',
                          label: 'Continue with Google',
                          onPressed: _continue,
                        ),
                        const SizedBox(height: 10),
                        _SocialButton(
                          icon: '',
                          label: 'Continue with Apple',
                          onPressed: _continue,
                        ),
                        const SizedBox(height: 10),
                        _SocialButton(
                          icon: 'f',
                          label: 'Continue with Facebook',
                          onPressed: _continue,
                        ),
                        const SizedBox(height: 48),
                        Text.rich(
                          TextSpan(
                            text: 'By clicking continue, you agree to our ',
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTextStyles.muted.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTextStyles.muted.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          style: AppTextStyles.muted,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
