import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'routes/app_routes.dart';

class ZenZooApp extends StatelessWidget {
  const ZenZooApp({super.key});

  @override
  Widget build(BuildContext context) {
    final hasLoggedIn = context.watch<UserProvider>().hasLoggedIn;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZenZoo',
      theme: AppTheme.light,
      initialRoute: hasLoggedIn ? AppRoutes.home : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
