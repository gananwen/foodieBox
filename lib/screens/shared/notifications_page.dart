// 路径: lib/screens/shared/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../util/styles.dart';
// FIX: Using relative path for repository
import '../../repositories/notification_repository.dart'; 
// FIX: Using relative path for model
import '../../models/notification_model.dart'; 

// Utility function to format Timestamp (since we removed the static 'time' field)
String _formatTimeDifference(Timestamp timestamp) {
  final difference = DateTime.now().difference(timestamp.toDate());
  if (difference.inHours > 24) {
    return '${difference.inDays}d ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}

class NotificationsPage extends StatefulWidget {
  final String userRole; 

  // NOTE: Assuming this file moved to lib/screens/shared/notifications_page.dart
  const NotificationsPage({super.key, required this.userRole});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // --- Repository and Stream ---
  final NotificationRepository _notificationRepo = NotificationRepository();
  late final Stream<List<AppNotification>> _notificationsStream; 

  @override
  void initState() {
    super.initState();
    // Use the stream from the repository
    _notificationsStream = _notificationRepo.getNotificationsStream();
  }

  // --- Utility to map Firestore status to UI icon ---
  IconData _getIconForType(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('order') || lowerStatus.contains('received')) return Icons.shopping_bag_outlined;
    if (lowerStatus.contains('offer') || lowerStatus.contains('promo')) return Icons.local_offer_outlined;
    if (lowerStatus.contains('product')) return Icons.inventory_2_outlined;
    if (lowerStatus.contains('redeem') || lowerStatus.contains('verified')) return Icons.check_circle_outline;
    return Icons.notifications_none;
  }

  void _markAllAsRead(List<AppNotification> notifications) async {
    // This call now works because the method was added to the repository
    await _notificationRepo.markAllAsRead(notifications);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: kTextColor)),
        centerTitle: true,
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => !n.isRead).length;

              return TextButton(
                onPressed: unreadCount > 0 ? () => _markAllAsRead(notifications) : null,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: unreadCount > 0 ? kPrimaryActionColor : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading notifications: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];
          
          if (notifications.isEmpty) {
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
          }
          
          return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !notification.isRead;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    color: kCardColor,
                    elevation: isUnread ? 2 : 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isUnread
                          ? const BorderSide(
                              color: kYellowMedium,
                              width: 1,
                            )
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      onTap: () {
                        // Mark as read when tapped
                        if (isUnread) {
                            _notificationRepo.markAsRead(notification.id);
                        }
                        // TODO: Implement navigation based on notification.orderId or status
                      },
                      leading: Icon(
                        _getIconForType(notification.type), // Use the 'type' field from the model
                        size: 30,
                        color: isUnread ? kPrimaryActionColor : Colors.grey,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.normal,
                          color: kTextColor,
                        ),
                      ),
                      subtitle: Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnread ? kTextColor : Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      trailing: Text(
                        _formatTimeDifference(notification.timestamp), // Use helper for time
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isUnread ? kPrimaryActionColor : Colors.grey,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                );
              },
            );;
        }
      ),
    );
  }
}