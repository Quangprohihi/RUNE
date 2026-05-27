import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pet_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/pet_animated_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();

  // Entrance animation controllers
  late AnimationController _logoController;
  late AnimationController _panelController;
  late AnimationController _petController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoFloat;

  late Animation<Offset> _panelSlide;
  late Animation<double> _panelFade;

  late Animation<double> _petFade;
  late Animation<Offset> _petSlide;

  @override
  void initState() {
    super.initState();

    // Logo: scale + fade, 600ms
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoFloat = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Panel: slide up after 300ms
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOut));
    _panelFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOut));

    // Kiki welcome: fade + slide from right
    _petController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _petFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _petController, curve: Curves.easeOut));
    _petSlide = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _petController, curve: Curves.easeOut));

    // Stagger the animations
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _logoController.forward();
      _petController.forward();
      await Future.delayed(const Duration(milliseconds: 150));
      _panelController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _logoController.dispose();
    _panelController.dispose();
    _petController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    try {
      final user = context.read<UserProvider>();
      await user.login(_emailController.text);
      final wallet = user.latestWallet;
      final pet = user.latestPet;
      if (wallet != null && mounted) {
        context.read<TokenProvider>().syncWallet(wallet);
      }
      if (pet != null && mounted) context.read<PetProvider>().syncPet(pet);
      if (mounted) {
        context.read<StreakProvider>().syncFromJson(user.latestStreak);
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $error')));
    }
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
              // --- Back button (static) ---
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

              // --- Kiki welcome character (top-right area) ---
              Positioned(
                top: 130,
                right: 16,
                child: FadeTransition(
                  opacity: _petFade,
                  child: SlideTransition(
                    position: _petSlide,
                    child: PetAnimatedWidget(
                      imagePath: 'assets/images/fox.png',
                      width: 90,
                      state: PetAnimationState.idle,
                    ),
                  ),
                ),
              ),

              // --- ZenZoo logo (scale + fade entrance) ---
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 78),
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: SlideTransition(
                      position: _logoFloat,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🌊', style: TextStyle(fontSize: 48)),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 40,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Zen',
                                    style: TextStyle(
                                      color: AppColors.accentTeal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Zoo',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- White panel slides up ---
              Positioned.fill(
                top: 220,
                child: FadeTransition(
                  opacity: _panelFade,
                  child: SlideTransition(
                    position: _panelSlide,
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
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 24,
                              ),
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
                              icon: '',
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
