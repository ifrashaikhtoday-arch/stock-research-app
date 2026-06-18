import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      '🎨 App Theme',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Choose how StockSense looks across the whole app.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  _buildThemeOption(
                    context,
                    title: 'Green theme (default)',
                    subtitle: 'StockSense classic green look',
                    color: const Color(0xFF1B5E20),
                    mode: AppThemeMode.green,
                    current: themeNotifier.mode,
                    onChanged: themeNotifier.setTheme,
                  ),
                  _buildThemeOption(
                    context,
                    title: 'Light mode',
                    subtitle: 'Bright, neutral colors',
                    color: Colors.blueGrey,
                    mode: AppThemeMode.light,
                    current: themeNotifier.mode,
                    onChanged: themeNotifier.setTheme,
                  ),
                  _buildThemeOption(
                    context,
                    title: 'Dark mode',
                    subtitle: 'Dark background, green accents',
                    color: Colors.black87,
                    mode: AppThemeMode.dark,
                    current: themeNotifier.mode,
                    onChanged: themeNotifier.setTheme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required AppThemeMode mode,
    required AppThemeMode current,
    required void Function(AppThemeMode) onChanged,
  }) {
    return RadioListTile<AppThemeMode>(
      value: mode,
      groupValue: current,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: CircleAvatar(backgroundColor: color, radius: 14),
    );
  }
}