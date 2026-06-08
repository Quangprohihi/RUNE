import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/login/login_screen.dart';
import 'providers/user_provider.dart';
import 'routes/app_routes.dart';

class ZenZooApp extends StatelessWidget {
  const ZenZooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();

    if (user.isRestoringSession) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZenZoo',
      theme: AppTheme.light,
      home: user.hasLoggedIn ? const HomeScreen() : const LoginScreen(),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
