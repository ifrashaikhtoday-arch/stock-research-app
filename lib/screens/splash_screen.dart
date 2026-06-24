import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'walkthrough_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  // Decides which screen to go to after the splash animation:
  // 1. If user has never seen the walkthrough -> show Walkthrough
  // 2. If user is not logged in -> show Login
  // 3. If user is logged in but hasn't finished onboarding -> show Onboarding
  // 4. If user is logged in and onboarding is done -> go straight to Home
  Future<Widget> _decideNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final seenWalkthrough = prefs.getBool('seen_walkthrough') ?? false;

    if (!seenWalkthrough) {
      return const WalkthroughScreen();
    }

    final user = FirebaseAuth.instance.currentUser;

    // Not logged in -> show login screen
    if (user == null) {
      return const LoginScreen();
    }

    // Logged in -> check if onboarding is complete
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final onboardingComplete = doc.data()?['onboardingComplete'] == true;

      if (onboardingComplete) {
        return const HomeScreen();
      } else {
        return const OnboardingScreen();
      }
    } catch (e) {
      // If Firestore check fails for some reason, default to Home
      // since the user is at least already logged in.
      return const HomeScreen();
    }
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      final nextScreen = await _decideNextScreen();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF5F7FA)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo sliding up from bottom
            SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/icon.png',
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // StockSense text fading in
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'StockSense',
                style: TextStyle(
                  color: Color(0xFF1B5E20),
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            FadeTransition(
              opacity: _fadeAnimation,
              child: const Text(
                'Your smart stock research app',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Loading dots
            FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}