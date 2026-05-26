import 'package:flutter/material.dart';

import '../presentation/focus/focus_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/pet/pet_profile_screen.dart';
import '../presentation/shop/shop_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String home = '/home';
  static const String focus = '/focus';
  static const String pet = '/pet';
  static const String shop = '/shop';

  static Map<String, WidgetBuilder> get routes => {
    login: (_) => const LoginScreen(),
    home: (_) => const HomeScreen(),
    focus: (_) => const FocusScreen(),
    pet: (_) => const PetProfileScreen(),
    shop: (_) => const ShopScreen(),
  };
}
