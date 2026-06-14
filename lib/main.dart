import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Remember login even after closing the app
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // Fix Firestore offline issue on Chrome
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  runApp(const MyApp());
=======
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
>>>>>>> 6b57c735ad8e418d013a11977c4363f8d8aaccce
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
<<<<<<< HEAD
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final onboardingComplete =
          doc.data()?['onboardingComplete'] == true;

      if (onboardingComplete) {
        return const HomeScreen();
      } else {
        return const OnboardingScreen();
      }
    } catch (e) {
      // If Firestore fails, just go to home screen
      return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getStartScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B5E20),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        return snapshot.data ?? const LoginScreen();
      },
=======
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
      const NewsScreen(),
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
>>>>>>> 6b57c735ad8e418d013a11977c4363f8d8aaccce
    );
  }
}