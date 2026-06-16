import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color bgColor = Color(0xFFF5F7FA);

  bool _notificationsEnabled = true;
  bool _isLoading = false;
  int _watchlistCount = 0;
  String _chartType = 'Line';
  String _timePeriod = '1D';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadPreferences();
    await _loadWatchlistCount();
    await _loadUserName();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
        _chartType = prefs.getString('chartType') ?? 'Line';
        _timePeriod = prefs.getString('timePeriod') ?? '1D';
      });
    }
  }

  Future<void> _loadWatchlistCount() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('watchlist')
          .get();
      if (mounted) {
        setState(() => _watchlistCount = snapshot.docs.length);
      }
    } catch (e) {
      print('Error loading watchlist: $e');
    }
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await _db.collection('users').doc(uid).get();
      if (mounted) {
        setState(() {
          _userName = doc.data()?['name'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading name: $e');
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  String get _avatarLetter {
    if (_userName.isNotEmpty) return _userName[0].toUpperCase();
    final email = FirebaseAuth.instance.currentUser?.email ?? 'U';
    return email[0].toUpperCase();
  }

  String get _userEmail {
    return FirebaseAuth.instance.currentUser?.email ?? 'No email';
  }

  String get _memberSince {
    final creationTime =
        FirebaseAuth.instance.currentUser?.metadata.creationTime;
    if (creationTime == null) return 'Unknown';
    return '${creationTime.day}/${creationTime.month}/${creationTime.year}';
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    await _authService.logOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

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

  void _showChangePasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.updatePassword(passwordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await _db.collection('users').doc(uid).delete();
                }
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Stats
                  _buildStatsCard(),
                  const SizedBox(height: 16),

                  // Notification settings
                  _buildSettingsCard(),
                  const SizedBox(height: 16),

                  // App preferences
                  _buildPreferencesCard(),
                  const SizedBox(height: 16),

                  // About section
                  _buildAboutCard(),
                  const SizedBox(height: 16),

                  // Danger zone
                  _buildDangerZoneCard(),
                  const SizedBox(height: 16),

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
                              fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: primaryGreen,
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: Text(
                  _avatarLetter,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryGreen, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: primaryGreen, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          if (_userName.isNotEmpty)
            Text(
              _userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

          // Email
          Text(
            _userEmail,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),

          // Member since
          Text(
            'Member since $_memberSince',
            style: TextStyle(color: Colors.green.shade100, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.notifications_outlined),
              title: const Text('Price Alerts',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Get notified on price changes'),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _savePreference('notifications', value);
                },
                activeColor: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Preferences',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),

            // Chart type
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.show_chart),
              title: const Text('Default Chart',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['Line', 'Candle'].map((type) {
                  final isSelected = _chartType == type;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _chartType = type);
                      _savePreference('chartType', type);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            // Time period
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.access_time),
              title: const Text('Default Period',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['1D', '1M', '1Y'].map((period) {
                  final isSelected = _timePeriod == period;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _timePeriod = period);
                      _savePreference('timePeriod', period);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryGreen : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),

            // App version
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.info_outline),
              title: const Text('App Version',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Text('1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),

            const Divider(height: 1),

            // Rate us
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.star_outline),
              title: const Text('Rate Us',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Rate us on Play Store'),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Play Store link coming soon!')),
                );
              },
            ),

            const Divider(height: 1),

            // Share app
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.share_outlined),
              title: const Text('Share App',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('Share StockSense with friends'),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing coming soon!')),
                );
              },
            ),

            const Divider(height: 1),

            // Contact support
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.email_outlined),
              title: const Text('Contact Support',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              subtitle: const Text('support@stocksense.app'),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Opening email...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),

            // Change password
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.lock_outline),
              title: const Text('Change Password',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
              onTap: _showChangePasswordDialog,
            ),

            const Divider(height: 1),

            // Delete account
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: Colors.red.shade600),
              ),
              title: Text('Delete Account',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade600)),
              subtitle: const Text('Permanently delete your account'),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: primaryGreen),
    );
  }
}