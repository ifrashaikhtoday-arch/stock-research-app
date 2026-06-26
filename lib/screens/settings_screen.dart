// lib/screens/settings_screen.dart
//
// StockSense - Settings Screen
// Simple settings page. Includes a link to the Price Alerts screen.

import 'package:flutter/material.dart';
import 'alerts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -- Notifications section --------------------------------------
          _sectionLabel('Notifications'),
          _settingsTile(
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
          _sectionLabel('About'),
          _settingsTile(
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

  Widget _sectionLabel(String text) {
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
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
            color: const Color(0xFF1B5E20).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1B5E20), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}