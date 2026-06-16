import 'package:flutter/material.dart';

/// The three theme modes the Settings screen lets the user pick from.
enum AppThemeMode { light, dark, green }

/// Central place for all of StockSense's brand colors.
class AppColors {
  static const Color primaryDarkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF2E7D32);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color accentGreen = Color(0xFF00C853);
  static const Color textPrimary = Color(0xFF1A1A1A);
}

/// Holds the currently selected theme mode and notifies the rest of the
/// app whenever it changes, so widgets rebuild with the new theme.
class ThemeNotifier extends ChangeNotifier { 
  AppThemeMode _mode = AppThemeMode.green; // Green theme is the default.

  AppThemeMode get mode => _mode;

  /// Call this from the Settings screen when the user picks a new theme.
  void setTheme(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// The ThemeData that MaterialApp should currently use.
  ThemeData get currentTheme {
    switch (_mode) {
      case AppThemeMode.light:
        return _lightTheme;
      case AppThemeMode.dark:
        return _darkTheme;
      case AppThemeMode.green:
        return _greenTheme;
    }
  }

  static final ThemeData _greenTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primaryDarkGreen,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDarkGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryDarkGreen,
      secondary: AppColors.accentGreen,
      surface: AppColors.cardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDarkGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardColor: AppColors.cardColor,
    cardTheme: CardThemeData(
      color: AppColors.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryDarkGreen,
      unselectedItemColor: Colors.grey,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentGreen,
      foregroundColor: Colors.white,
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    primaryColor: Colors.blueGrey,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.light,
      secondary: AppColors.accentGreen,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      centerTitle: false,
    ),
    cardColor: Colors.white,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blueGrey,
      unselectedItemColor: Colors.grey,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: AppColors.lightGreen,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lightGreen,
      brightness: Brightness.dark,
      primary: AppColors.lightGreen,
      secondary: AppColors.accentGreen,
      surface: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardColor: const Color(0xFF1E1E1E),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: ThemeData.dark().textTheme,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: AppColors.accentGreen,
      unselectedItemColor: Colors.grey,
    ),
  );
}