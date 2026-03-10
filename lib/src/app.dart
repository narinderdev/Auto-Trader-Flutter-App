import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'features/wishlist/wishlist_controller.dart';
import 'pages/splash_page.dart';
import 'repositories/auto_trader_repository.dart';

void runAutoTraderApp() {
  runApp(const AutoTraderApp());
}

class AutoTraderApp extends StatelessWidget {
  const AutoTraderApp({super.key});

  @override
  Widget build(BuildContext context) {
    const canvasColor = Color(0xFFF5F1EB);
    const surfaceColor = Colors.white;
    const primaryColor = Color(0xFFB4232F);
    const textColor = Color(0xFF231815);

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: canvasColor,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        RepositoryProvider(create: (_) => AutoTraderRepository()),
        ChangeNotifierProvider(create: (_) => WishlistController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Auto Trader',
        theme: baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: textColor,
            elevation: 0,
            centerTitle: false,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD8D3CC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: primaryColor, width: 1.3),
            ),
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
