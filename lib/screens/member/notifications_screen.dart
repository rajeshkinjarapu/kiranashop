import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, it's just a UI placeholder for notifications.
    // In a real app, this would stream from Firestore.
    final List<Map<String, String>> notifications = [
      {
        'title': 'New Offer Available! 🎉',
        'body': 'Get 20% off on all grocery items this weekend. Shop now!',
        'time': '2 hours ago',
      },
      {
        'title': 'Order Delivered 📦',
        'body': 'Your order #ORD-12345 has been successfully delivered.',
        'time': 'Yesterday',
      },
      {
        'title': 'Welcome to Kirana Shop! 👋',
        'body': 'Thank you for registering. Start exploring our products.',
        'time': '2 days ago',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              subtitle: 'You have no new notifications right now.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final notif = notifications[i];
                final isNew = i == 0; // Just mock the first one as unread

                return Card(
                  elevation: isNew ? 2 : 0,
                  color: isNew ? Colors.blue.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isNew ? Colors.blue.shade200 : Colors.grey.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isNew ? AppTheme.primary : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active,
                            color: isNew ? Colors.white : Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title']!,
                                style: TextStyle(
                                  fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif['body']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                notif['time']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isNew ? AppTheme.primary : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
