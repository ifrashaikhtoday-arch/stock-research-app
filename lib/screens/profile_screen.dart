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
          .where('inWatchlist', isEqualTo: true)
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

  void _showLogoutDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(ThemeData theme) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: theme.colorScheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  _buildHeader(theme),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Column(
                      children: [
                        _buildStatsRow(theme),
                        const SizedBox(height: 16),
                        _buildSettingsCard(theme),
                        const SizedBox(height: 16),
                        _buildPreferencesCard(theme),
                        const SizedBox(height: 16),
                        _buildAboutCard(theme),
                        const SizedBox(height: 16),
                        _buildDangerZoneCard(theme),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () => _showLogoutDialog(theme),
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text('Logout',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(
                                    color: Colors.red.shade200, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 60, top: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.5), width: 2),
              ),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white,
                child: Text(
                  _avatarLetter,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_userName.isNotEmpty)
              Text(
                _userName,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                  color: theme.colorScheme.onPrimary.withOpacity(0.75),
                  fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Member since $_memberSince',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _statItem(
                theme,
                icon: Icons.bookmark_outline,
                value: '$_watchlistCount',
                label: 'Watchlist',
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _statItem(
                theme,
                icon: Icons.notifications_active_outlined,
                value: _notificationsEnabled ? 'On' : 'Off',
                label: 'Alerts',
              ),
            ),
            Container(
              width: 1,
              height: 36,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _statItem(
                theme,
                icon: Icons.show_chart,
                value: _chartType,
                label: 'Chart',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(ThemeData theme,
      {required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                theme, 'Notifications', Icons.notifications_outlined),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.notifications_outlined, theme),
              title: const Text('Price Alerts',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Get notified on price changes',
                  style: TextStyle(fontSize: 12)),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  _savePreference('notifications', value);
                },
                activeColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(theme, 'App Preferences', Icons.tune),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.show_chart, theme),
              title: const Text('Default Chart',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.access_time, theme),
              title: const Text('Default Period',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
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

  Widget _buildAboutCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(theme, 'About', Icons.info_outline),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.info_outline, theme),
              title: const Text('App Version',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Text('1.0.0',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.star_outline, theme),
              title: const Text('Rate Us',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Rate us on Play Store',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 13, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Play Store link coming soon!')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.share_outlined, theme),
              title: const Text('Share App',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Share StockSense with friends',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 13, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing coming soon!')),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.email_outlined, theme),
              title: const Text('Contact Support',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('support@stocksense.app',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 13, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildCard(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(theme, 'Account', Icons.manage_accounts_outlined),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _buildIconBox(Icons.lock_outline, theme),
              title: const Text('Change Password',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 13, color: Colors.grey),
              onTap: () => _showChangePasswordDialog(theme),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
              ),
              title: Text('Delete Account',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.red.shade600)),
              subtitle: const Text('Permanently delete your account',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 13, color: Colors.grey),
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required ThemeData theme, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIconBox(IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 19),
    );
  }
}