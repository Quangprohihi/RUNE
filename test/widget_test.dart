import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rune/app.dart';
import 'package:rune/data/repositories/focus_repository.dart';
import 'package:rune/data/repositories/pet_repository.dart';
import 'package:rune/data/repositories/shop_repository.dart';
import 'package:rune/data/repositories/streak_repository.dart';
import 'package:rune/data/repositories/token_repository.dart';
import 'package:rune/data/repositories/user_repository.dart';
import 'package:rune/providers/focus_provider.dart';
import 'package:rune/providers/pet_provider.dart';
import 'package:rune/providers/shop_provider.dart';
import 'package:rune/providers/streak_provider.dart';
import 'package:rune/providers/token_provider.dart';
import 'package:rune/providers/user_provider.dart';

void main() {
  testWidgets('ZenZoo starts on mock login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => UserProvider(UserRepository(prefs)),
          ),
          ChangeNotifierProvider(
            create: (_) => TokenProvider(TokenRepository(prefs)),
          ),
          ChangeNotifierProvider(
            create: (_) => PetProvider(PetRepository(prefs)),
          ),
          ChangeNotifierProvider(
            create: (_) => StreakProvider(StreakRepository(prefs)),
          ),
          ChangeNotifierProvider(
            create: (_) => FocusProvider(FocusRepository(prefs)),
          ),
          ChangeNotifierProvider(
            create: (_) => ShopProvider(ShopRepository(prefs)),
          ),
        ],
        child: const ZenZooApp(),
      ),
    );

    expect(find.text('Get Started!'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
