import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notifications — will be replaced with real data from Firebase later
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Price Alert Triggered',
      'body': 'Reliance Industries crossed ₹2,900',
      'time': '2 mins ago',
      'icon': Icons.trending_up,
      'color': Color(0xFF00C853),
      'read': false,
    },
    {
      'title': 'Market Update',
      'body': 'Nifty 50 is up 1.2% today',
      'time': '1 hour ago',
      'icon': Icons.show_chart,
      'color': Color(0xFF00C853),
      'read': false,
    },
    {
      'title': 'Price Alert Triggered',
      'body': 'TCS dropped below ₹3,500',
      'time': '3 hours ago',
      'icon': Icons.trending_down,
      'color': Color(0xFFFF3B30),
      'read': true,
    },
    {
      'title': 'Portfolio Update',
      'body': 'Your portfolio is up ₹2,340 today',
      'time': 'Yesterday',
      'icon': Icons.pie_chart_outline,
      'color': Color(0xFF00C853),
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n['read']).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(
          unreadCount > 0
              ? 'Notifications ($unreadCount)'
              : 'Notifications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n['read'] = true;
                  }
                });
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                    color: theme.colorScheme.onPrimary, fontSize: 13),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmpty(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(theme, _notifications[index], index);
              },
            ),
    );
  }

  Widget _buildNotificationCard(
      ThemeData theme, Map<String, dynamic> notification, int index) {
    final isUnread = !notification['read'];

    return GestureDetector(
      onTap: () {
        setState(() => _notifications[index]['read'] = true);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? theme.colorScheme.primary.withOpacity(0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2))
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (notification['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notification['icon'] as IconData,
                color: notification['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'],
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.6),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(
            'Set price alerts to get notified\nwhen your stocks hit target prices.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}