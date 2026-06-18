import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This class holds the current theme and notifies the whole app
// whenever the color changes — Provider watches this and rebuilds
// any screen that uses Provider.of<ThemeNotifier>(context).
class ThemeNotifier extends ChangeNotifier {
  Color _themeColor = const Color(0xFF4F46E5); // default indigo

  Color get themeColor => _themeColor;

  // The actual ThemeData built from the current color
  ThemeData get currentTheme => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _themeColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: _themeColor,
          unselectedItemColor: Colors.grey,
        ),
        cardColor: const Color(0xFF1A1A1A),
      );

  ThemeNotifier() {
    _loadSavedColor();
  }

  // Loads the saved color when the app starts
  Future<void> _loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('themeColor');
    if (saved != null) {
      _themeColor = Color(saved);
      notifyListeners();
    }
  }

  // Called from the Settings screen when the user picks a new color
  Future<void> setColor(Color color) async {
    _themeColor = color;
    notifyListeners(); // tells every screen using Provider to rebuild

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.value);
  }
}