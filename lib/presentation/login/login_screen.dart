import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/friendly_error.dart';
import '../../core/session/session_reset.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/pet_provider.dart';
import '../../providers/streak_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/pet_animated_widget.dart';

enum _AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _logoController.dispose();
    _panelController.dispose();
    _petController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final displayName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showAuthMessage('Please enter email and password.');
      return;
    }
    if (_mode == _AuthMode.register) {
      if (displayName.length < 2) {
        _showAuthMessage('Please enter your name.');
        return;
      }
      if (password.length < 6) {
        _showAuthMessage('Password must be at least 6 characters.');
        return;
      }
      if (password != confirmPassword) {
        _showAuthMessage('Password confirmation does not match.');
        return;
      }
    }

    try {
      final user = context.read<UserProvider>();
      if (_mode == _AuthMode.login) {
        await user.login(email: email, password: password);
      } else {
        await user.register(
          displayName: displayName,
          email: email,
          password: password,
        );
      }
      if (mounted) _finishLogin(user);
    } catch (error) {
      if (!mounted) return;
      _showAuthMessage(
        friendlyError(
          error,
          fallback: _mode == _AuthMode.login
              ? 'Login failed. Please try again.'
              : 'Sign up failed. Please try again.',
        ),
      );
    }
  }

  /// Shared post-auth path for every sign-in method: reset all account-scoped
  /// state when a different account signed in, then layer the new user's
  /// server data on top and enter the app.
  void _finishLogin(UserProvider user) {
    if (user.consumeAccountSwitched()) {
      SessionReset.resetAll(context);
    }
    final wallet = user.latestWallet;
    final pet = user.latestPet;
    if (wallet != null) context.read<TokenProvider>().syncWallet(wallet);
    if (pet != null) context.read<PetProvider>().syncPet(pet);
    context.read<StreakProvider>().syncFromJson(user.latestStreak);
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _showAuthMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _continueWithGoogle() async {
    try {
      final user = context.read<UserProvider>();
      final signedIn = await user.loginWithGoogle();
      // The user closed the account picker — not an error, stay quiet.
      if (!signedIn) return;
      if (mounted) _finishLogin(user);
    } catch (error) {
      if (!mounted) return;
      _showAuthMessage(
        friendlyError(
          error,
          fallback: 'Google sign-in failed. Please try again.',
        ),
      );
    }
  }

  void _showSocialComingSoon() {
    _showAuthMessage('This social login will be added later.');
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == _AuthMode.register;
    final userState = context.watch<UserProvider>();
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
                              isRegister ? 'Create Account' : 'Welcome Back',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRegister
                                  ? 'Sign up to start growing Kiki.'
                                  : 'Log in with your email and password.',
                              style: AppTextStyles.body,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            _AuthModeSwitch(
                              mode: _mode,
                              onChanged: (mode) => setState(() => _mode = mode),
                            ),
                            const SizedBox(height: 18),
                            if (isRegister) ...[
                              TextField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'Your name',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'email@domain.com',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: isRegister
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onSubmitted: (_) {
                                if (!isRegister) _continue();
                              },
                              decoration: InputDecoration(
                                hintText: 'Password',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                            if (isRegister) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _continue(),
                                decoration: InputDecoration(
                                  hintText: 'Confirm password',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: userState.isLoading ? null : _continue,
                              child: userState.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(isRegister ? 'Sign up' : 'Log in'),
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
                              icon: const _GoogleLogo(),
                              label: 'Continue with Google',
                              onPressed: userState.isLoading
                                  ? null
                                  : _continueWithGoogle,
                            ),
                            const SizedBox(height: 10),
                            _SocialButton(
                              icon: const Icon(
                                Icons.apple,
                                size: 22,
                                color: Colors.black,
                              ),
                              label: 'Continue with Apple',
                              onPressed: _showSocialComingSoon,
                            ),
                            const SizedBox(height: 10),
                            _SocialButton(
                              icon: const _FacebookLogo(),
                              label: 'Continue with Facebook',
                              onPressed: _showSocialComingSoon,
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

class _AuthModeSwitch extends StatelessWidget {
  const _AuthModeSwitch({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _AuthModePill(
            label: 'Log in',
            selected: mode == _AuthMode.login,
            onTap: () => onChanged(_AuthMode.login),
          ),
          _AuthModePill(
            label: 'Sign up',
            selected: mode == _AuthMode.register,
            onTap: () => onChanged(_AuthMode.register),
          ),
        ],
      ),
    );
  }
}

class _AuthModePill extends StatelessWidget {
  const _AuthModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: selected ? Colors.white : AppColors.primaryBlue,
            ),
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

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFF2F4F7),
          foregroundColor: const Color(0xFF202124),
          disabledBackgroundColor: const Color(0xFFE8EAED),
          disabledForegroundColor: const Color(0xFF8A8F98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 24, height: 24, child: Center(child: icon)),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: const Color(0xFF202124),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Arial',
        ),
        children: [
          TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
        ],
      ),
    );
  }
}

class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1,
          fontWeight: FontWeight.w800,
          fontFamily: 'Arial',
        ),
      ),
    );
  }
}
