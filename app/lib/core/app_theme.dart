import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B0D10);
  static const surface = Color(0xFF14171C);
  static const raised = Color(0xFF20252C);
  static const blue = Color(0xFF263746);
  static const red = Color(0xFFB8202E);
  static const redLight = Color(0xFFE04450);
  static const gold = Color(0xFFE6B84A);
  static const muted = Color(0xFF9BA2AC);
  static const border = Color(0xFF2B313A);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.red,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme.copyWith(primary: AppColors.red, secondary: AppColors.blue),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, elevation: 0),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.red.withValues(alpha: .22),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
