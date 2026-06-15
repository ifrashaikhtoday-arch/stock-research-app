import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Color primaryGreen = Color(0xFF2E7D32);

  bool _notificationsEnabled = true;
  int _watchlistCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWatchlistCount();
  }

  // Load how many stocks the user has in their watchlist
  Future<void> _loadWatchlistCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

   final snapshot = await _db
    .collection('users')
    .doc(uid)
    .collection('watchlist')
    .get();

if (mounted) {
  setState(() {
    _watchlistCount = snapshot.docs.length;
  });
}
  }

  // Get the first letter of the user's email for the avatar
  String get _avatarLetter {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'U';
    return email[0].toUpperCase();
  }

  // Get the user's email
  String get _userEmail {
    return FirebaseAuth.instance.currentUser?.email ?? 'No email';
  }

  // Get member since date
  String get _memberSince {
    final creationTime =
        FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (creationTime == null) return 'Unknown';
    return '${creationTime.day}/${creationTime.month}/${creationTime.year}';
  }

  // Handle logout
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    await _authService.logOut();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // removes all previous screens
      );
    }
  }

  // Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Top green header with avatar
                  Container(
                    width: double.infinity,
                    color: primaryGreen,
                    padding: const EdgeInsets.only(bottom: 30, top: 10),
                    child: Column(
                      children: [
                        // Avatar circle
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _avatarLetter,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Email
                        Text(
                          _userEmail,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Member since
                        Text(
                          'Member since $_memberSince',
                          style: TextStyle(
                            color: Colors.green.shade100,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Watchlist count
                            Column(
                              children: [
                                Text(
                                  '$_watchlistCount',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                                const Text(
                                  'Stocks in Watchlist',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Settings section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Notifications toggle
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: primaryGreen,
                              ),
                            ),
                            title: const Text(
                              'Price Alerts',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: const Text('Get notified on price changes'),
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (value) {
                                setState(
                                    () => _notificationsEnabled = value);
                              },
                              activeColor: primaryGreen,
                            ),
                          ),

                          const Divider(height: 1),

                          // App version
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: primaryGreen,
                              ),
                            ),
                            title: const Text(
                              'App Version',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            trailing: const Text(
                              '1.0.0',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}