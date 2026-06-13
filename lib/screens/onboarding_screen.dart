import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color bgColor = Color(0xFFF5F7FA);

  // Current page index (0, 1, 2)
  int _currentPage = 0;
  final PageController _pageController = PageController();

  // Page 1 — Profile setup
  final TextEditingController _nameController = TextEditingController();
  File? _profileImage;
  bool _isLoadingPage1 = false;

  // Page 2 — Sector interests
  final List<String> _allSectors = [
    'IT', 'Banking', 'Auto', 'Pharma', 'Energy', 'FMCG'
  ];
  final List<String> _selectedSectors = [];
  bool _isLoadingPage2 = false;

  // Page 3 — Experience level
  String? _selectedExperience;
  bool _isLoadingPage3 = false;

  final List<Map<String, String>> _experienceOptions = [
    {'title': 'Just starting', 'subtitle': 'I am new to investing', 'icon': '🌱'},
    {'title': 'Less than 1 year', 'subtitle': 'I have dabbled a bit', 'icon': '📈'},
    {'title': '1–3 years', 'subtitle': 'I know the basics', 'icon': '💼'},
    {'title': '3+ years', 'subtitle': 'I am experienced', 'icon': '🏆'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Pick profile photo from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  // Save page 1 data and go to page 2
  Future<void> _savePage1() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    setState(() => _isLoadingPage1 = true);

    try {
      final uid = _auth.currentUser!.uid;
      await _db.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'onboardingStep': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }

    setState(() => _isLoadingPage1 = false);
  }

  // Save page 2 data and go to page 3
  Future<void> _savePage2() async {
    if (_selectedSectors.isEmpty) {
      _showError('Please select at least one sector');
      return;
    }

    setState(() => _isLoadingPage2 = true);

    try {
      final uid = _auth.currentUser!.uid;
      await _db.collection('users').doc(uid).set({
        'sectors': _selectedSectors,
        'onboardingStep': 2,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }

    setState(() => _isLoadingPage2 = false);
  }

  // Save page 3 data and go to HomeScreen
  Future<void> _savePage3() async {
    if (_selectedExperience == null) {
      _showError('Please select your experience level');
      return;
    }

    setState(() => _isLoadingPage3 = true);

    try {
      final uid = _auth.currentUser!.uid;
      await _db.collection('users').doc(uid).set({
        'experience': _selectedExperience,
        'onboardingComplete': true, // marks onboarding as done
        'onboardingStep': 3,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    }

    setState(() => _isLoadingPage3 = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar at top
            _buildProgressBar(),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // disable swipe
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Progress bar showing which step user is on
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? primaryGreen
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =============================================
  // PAGE 1 — Profile Setup
  // =============================================
  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          // Title
          const Text(
            'What should we\ncall you?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Set up your profile to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 40),

          // Profile photo picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: primaryGreen,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Tap to add photo (optional)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),

          const SizedBox(height: 32),

          // Name field
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Daniya',
              prefixIcon:
                  const Icon(Icons.person_outline, color: primaryGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: primaryGreen, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoadingPage1 ? null : _savePage1,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoadingPage1
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Continue →',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PAGE 2 — Sector Interests
  // =============================================
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          const Text(
            'What sectors\ninterest you?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select all that apply — we will personalize your feed',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 40),

          // Sector chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _allSectors.map((sector) {
              final isSelected = _selectedSectors.contains(sector);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSectors.remove(sector);
                    } else {
                      _selectedSectors.add(sector);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? primaryGreen : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    sector,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          // Continue button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoadingPage2 ? null : _savePage2,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoadingPage2
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Continue →',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PAGE 3 — Experience Level
  // =============================================
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          const Text(
            'How long have you\nbeen investing?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'This helps us show the right content for you',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 40),

          // Experience option cards
          ..._experienceOptions.map((option) {
            final isSelected = _selectedExperience == option['title'];
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedExperience = option['title']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryGreen.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? primaryGreen : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      option['icon']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title']!,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isSelected
                                  ? primaryGreen
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            option['subtitle']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                          color: primaryGreen, size: 22),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Get Started button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoadingPage3 ? null : _savePage3,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoadingPage3
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      '🚀 Get Started',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}