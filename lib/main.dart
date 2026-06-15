import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/news_screen.dart';
import 'screens/search_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedColor = prefs.getInt('themeColor') ?? 0xFF4F46E5;
  runApp(MyApp(initialColor: Color(savedColor)));
}

class MyApp extends StatefulWidget {
  final Color initialColor;
  const MyApp({super.key, required this.initialColor});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Color _themeColor;

  @override
  void initState() {
    super.initState();
    _themeColor = widget.initialColor;
  }

  void _updateTheme(Color newColor) {
    setState(() => _themeColor = newColor);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Research App',
      theme: ThemeData(
     colorScheme: ColorScheme.fromSeed(seedColor: _themeColor),
    scaffoldBackgroundColor: ColorScheme.fromSeed(seedColor: _themeColor).primaryContainer,
    useMaterial3: true,
    ), 
      home: MainScreen(onThemeChanged: _updateTheme),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(Color) onThemeChanged;
  const MainScreen({super.key, required this.onThemeChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const WatchlistScreen(),
            NewsScreen(),
      const SearchScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmarks_outlined), activeIcon: Icon(Icons.bookmarks_rounded), label: 'Watchlist'),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper_outlined), activeIcon: Icon(Icons.newspaper_rounded), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), activeIcon: Icon(Icons.search_rounded), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}