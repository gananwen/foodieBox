import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../util/styles.dart';

// Helper class for data model
class AppNotification {
  final String title;
  final String body;
  final String time;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType { order, offer, update }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Mock data for the notification list
  final List<AppNotification> _notifications = [
    AppNotification(
      title: 'Order Delivered! 🎉',
      body: 'Your FoodieBox order #20241031 is now complete. Enjoy your items!',
      time: 'Just now',
      type: NotificationType.order,
    ),
    AppNotification(
      title: 'Syok Deal: RM10 OFF!',
      body: 'Grab RM10 off your next BlindBox purchase. Limited time offer!',
      time: '5 minutes ago',
      type: NotificationType.offer,
      isRead: true,
    ),
    AppNotification(
      title: 'Order Confirmed',
      body: 'We\'ve received your order #20241030. Preparation is underway.',
      time: '1 hour ago',
      type: NotificationType.order,
      isRead: true,
    ),
    AppNotification(
      title: 'App Update Available',
      body: 'New filter options and stability improvements are now live.',
      time: 'Yesterday',
      type: NotificationType.update,
      isRead: true,
    ),
    AppNotification(
      title: 'New Store Alert!',
      body:
          'We\'ve added Tesco to our sustainable network. Find great discounts!',
      time: '2 days ago',
      type: NotificationType.update,
      isRead: true,
    ),
  ];

  // Function to mark all unread notifications as read
  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  // Helper widget to get icon based on notification type
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.update:
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count unread notifications
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white, // Base is white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // *** ADDED BACK BUTTON HERE ***
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        // *****************************
        title: const Text('Notifications', style: TextStyle(color: kTextColor)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: unreadCount > 0 ? _markAllAsRead : null,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: unreadCount > 0 ? kPrimaryActionColor : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                final isUnread = !notification.isRead;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    color: kCardColor, // Always white card background
                    elevation: isUnread ? 2 : 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isUnread
                          ? const BorderSide(
                              color: kYellowMedium,
                              width: 1,
                            ) // Highlight unread
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          notification.isRead = true;
                        });
                        // TODO: Navigate to the corresponding page (e.g., Order Details)
                      },
                      leading: Icon(
                        _getIconForType(notification.type),
                        size: 30,
                        // Use PrimaryActionColor or Amber for visual pop
                        color: isUnread ? kPrimaryActionColor : Colors.grey,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
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
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Small indicator for unread
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 11,
                              color: isUnread
                                  ? kPrimaryActionColor
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                );
              },
            ),
    );
  }
}
