// 路径: lib/shared/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../util/styles.dart';

// (模型和枚举保持不变)
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

enum NotificationType { order, offer, update, product, redeem } // ( ✨ 新增了类型 ✨ )

class NotificationsPage extends StatefulWidget {
  // --- ( ✨ 1. 新增参数 ✨ ) ---
  final String userRole; // 接收 "User" 或 "Vendor"

  const NotificationsPage({super.key, required this.userRole});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // --- ( ✨ 2. 已修改 ✨ ) ---
  // 列表现在是空的，将在 initState 中填充
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    // --- ( ✨ 3. 新增函数 ✨ ) ---
    // 根据传入的角色加载不同的数据
    _loadNotificationsForRole(widget.userRole);
  }

  // --- ( ✨ 4. 新增函数：加载模拟数据 ✨ ) ---
  void _loadNotificationsForRole(String role) {
    if (role == 'Vendor') {
      // --- 这是你的供应商通知列表 ---
      setState(() {
        _notifications = [
          AppNotification(
            title: 'New Order Received! 💰',
            body:
                'Order #20241032 has been placed for 2x Blindbox 1. Please prepare for pickup.',
            time: 'Just now',
            type: NotificationType.order, // (使用新类型)
          ),
          AppNotification(
            title: 'Promotion Fully Redeemed',
            body:
                'Your "Weekend 20% Off" deal has been fully redeemed (100/100).',
            time: '1 hour ago',
            type: NotificationType.redeem, // (使用新类型)
            isRead: true,
          ),
          AppNotification(
            title: 'Product Updated',
            body:
                'Your "Fresh Apples" product details were successfully updated.',
            time: '3 hours ago',
            type: NotificationType.product, // (使用新类型)
            isRead: true,
          ),
          AppNotification(
            title: 'Deal Redemption',
            body:
                'Your "Weekend 20% Off" deal has 50/100 redemptions remaining.',
            time: 'Yesterday',
            type: NotificationType.redeem,
            isRead: true,
          ),
          AppNotification(
            title: 'Promotion Successfully Posted!',
            body:
                'Your "Weekend 20% Off" deal is now live and visible to users.',
            time: '2 days ago',
            type: NotificationType.offer,
            isRead: true,
          ),
        ];
      });
    } else {
      // --- 这是你的用户通知列表 (来自你之前的文件) ---
      setState(() {
        _notifications = [
          AppNotification(
            title: 'Order Delivered! 🎉',
            body:
                'Your FoodieBox order #20241031 is now complete. Enjoy your items!',
            time: 'Just now',
            type: NotificationType.order,
          ),
          AppNotification(
            title: 'Payment Successful',
            body: 'Your payment for order #20241031 was successful. Thank you!',
            time: '5 minutes ago',
            type: NotificationType.order,
            isRead: true,
          ),
          AppNotification(
            title: 'Syok Deal: RM10 OFF!',
            body:
                'Grab RM10 off your next BlindBox purchase. Limited time offer!',
            time: '1 hour ago',
            type: NotificationType.offer,
            isRead: true,
          ),
          AppNotification(
            title: 'Order Confirmed (Received)',
            body:
                'We\'ve received your order #20241030. Preparation is underway.',
            time: '1 hour ago',
            type: NotificationType.order,
            isRead: true,
          ),
          AppNotification(
            title: 'Promotion Update',
            body:
                'Wolo Hotel buffet has just posted a new 30% Off deal! Check it out.',
            time: 'Yesterday',
            type: NotificationType.offer,
            isRead: true,
          ),
        ];
      });
    }
  }

  // (函数不变)
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

  // --- ( ✨ 5. 已修改：添加新图标 ✨ ) ---
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag_outlined;
      case NotificationType.offer:
        return Icons.local_offer_outlined;
      case NotificationType.product: // (新增)
        return Icons.inventory_2_outlined;
      case NotificationType.redeem: // (新增)
        return Icons.check_circle_outline;
      case NotificationType.update:
        return Icons.info_outline;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    // (Count unread 逻辑不变)
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (AppBar 逻辑不变) ...
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
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
      // ( ✨ 已修改 ✨ )
      // body 现在会根据 _notifications 列表是否为空来构建
      body: _notifications.isEmpty
          ? Center(
              // (空状态不变)
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
              // (列表构建逻辑不变)
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
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
                        setState(() {
                          notification.isRead = true;
                        });
                        // TODO: 导航
                      },
                      leading: Icon(
                        _getIconForType(notification.type),
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
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                              color:
                                  isUnread ? kPrimaryActionColor : Colors.grey,
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
