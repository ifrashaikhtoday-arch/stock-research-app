// lib/screens/settings_screen.dart
//
// StockSense - Settings Screen
// Includes a theme switcher (Green / Light / Dark) and a link to Price Alerts.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Appearance section -----------------------------------------
          _sectionLabel(context, 'Appearance'),
          _buildThemeCard(context, themeNotifier),

          const SizedBox(height: 24),

          // -- Notifications section --------------------------------------
          _sectionLabel(context, 'Notifications'),
          _settingsTile(
            context: context,
            icon: Icons.notifications_active_outlined,
            title: 'Price Alerts',
            subtitle: 'View and manage your price alerts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlertsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // -- About section ----------------------------------------------
          _sectionLabel(context, 'About'),
          _settingsTile(
            context: context,
            icon: Icons.info_outline_rounded,
            title: 'About StockSense',
            subtitle: 'Stock research for Indian investors',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'StockSense',
                applicationVersion: '1.0.0',
                children: const [
                  Text(
                    'A stock research app for Indian investors. '
                    'Prices may be delayed by 15-20 minutes.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // -- Theme picker card ----------------------------------------------------
  Widget _buildThemeCard(BuildContext context, ThemeNotifier themeNotifier) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _themeOption(
            context: context,
            themeNotifier: themeNotifier,
            mode: AppThemeMode.green,
            title: 'Green',
            subtitle: 'Default StockSense theme',
            icon: Icons.eco_outlined,
            color: AppColors.primaryDarkGreen,
          ),
          _themeDivider(context),
          _themeOption(
            context: context,
            themeNotifier: themeNotifier,
            mode: AppThemeMode.light,
            title: 'Light',
            subtitle: 'Bright and clean',
            icon: Icons.light_mode_outlined,
            color: Colors.blueGrey,
          ),
          _themeDivider(context),
          _themeOption(
            context: context,
            themeNotifier: themeNotifier,
            mode: AppThemeMode.dark,
            title: 'Dark',
            subtitle: 'Easy on the eyes',
            icon: Icons.dark_mode_outlined,
            color: const Color(0xFF1E1E1E),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required BuildContext context,
    required ThemeNotifier themeNotifier,
    required AppThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isSelected = themeNotifier.mode == mode;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : Icon(Icons.circle_outlined, color: Colors.grey.shade300),
      onTap: () => themeNotifier.setTheme(mode),
    );
  }

  Widget _themeDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.withOpacity(0.15),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}