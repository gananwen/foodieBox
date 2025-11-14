// 路径: lib/pages/vendor_home/more_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../util/styles.dart';
import '../auth/vendor_login.dart';
import 'account_settings_page.dart';
import '../shared/notifications_page.dart';
import '../shared/help_page.dart'; // <-- 确保导入了 help_page.dart
import '../shared/about_page.dart';
import '../shared/notifications_page.dart';
// --- 1. 导入 Repository ---
import '../../repositories/vendor_data_repository.dart';

class MorePage extends StatelessWidget {
  final VoidCallback onBackToDashboard;
  final VendorDataBundle bundle; // <-- 2. 接收数据
  final VoidCallback onProfileUpdated; // <-- (新增) 刷新回调

  const MorePage({
    super.key,
    required this.onBackToDashboard,
    required this.bundle,
    required this.onProfileUpdated, // <-- (新增)
  });

  // --- 3. (已修改) 辅助: 构建顶部的个人资料卡片 ---
  Widget _buildProfileHeader() {
    final user = bundle.user;
    final vendor = bundle.vendor;
    final String vendorName = "${user.firstName} ${user.lastName}";
    final String vendorId = vendor.uid;
    final String photoUrl = vendor.businessPhotoUrl;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(26), width: 1.5),
      ),
      child: Row(
        children: [
          // --- (已修改) 使用真实图片 ---
          CircleAvatar(
            radius: 30,
            backgroundColor: kSecondaryAccentColor,
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.store, size: 40, color: kTextColor)
                : null,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- (已修改) 使用真实姓名 ---
                Text(
                  vendorName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // --- (已修改) 使用真实 ID ---
                Text(
                  'VendorID: ${vendorId.substring(0, 6)}...',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextColor.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- (辅助) 构建列表项 ---
  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title,
    // (修改) 让 page 变成一个构建器，这样我们可以传递回调
    Widget Function() pageBuilder,
  ) {
    return ListTile(
      leading: Icon(icon, color: kTextColor.withAlpha(204)),
      title:
          Text(title, style: const TextStyle(color: kTextColor, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: kTextColor, size: 20),
      onTap: () async {
        // 导航到页面
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pageBuilder()),
        );
        // --- (新增) 当从设置页面返回时，调用刷新 ---
        onProfileUpdated();
      },
    );
  }

  // --- (辅助) 登出函数 ---
  void _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const VendorLoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: onBackToDashboard,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // 5. (已修改) 导航到 AccountSettingsPage 时传递 'bundle'
          _buildListTile(
            context,
            Icons.person_outline,
            'Account & Store Settings',
            () => AccountSettingsPage(bundle: bundle), // <-- 传递数据
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            Icons.notifications_none_outlined,
            'Notifications',
            () => NotificationsPage(userRole: bundle.user.role), // <-- 传入角色
          ),
          const Divider(height: 1),

          // --- ( ✨ 关键修改在这里 ✨ ) ---
          _buildListTile(
            context,
            Icons.help_outline,
            'Help & Support',
            // 之前是: () => const HelpPage(),
            // 现在是:
            () => HelpPage(userRole: bundle.user.role), // <-- 像这样传入角色
          ),
          // --- ( ✨ 结束修改 ✨ ) ---

          const Divider(height: 1),
          _buildListTile(
            context,
            Icons.info_outline,
            'About FoodieBox',
            () => const AboutPage(),
          ),
          const Divider(height: 1),
          const SizedBox(height: 40),

          // ... (你现有的 "Log Out" 按钮保持不变) ...
          Container(
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: kPrimaryActionColor.withAlpha(100)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: kPrimaryActionColor),
              title: const Text(
                'Log Out',
                style: TextStyle(
                    color: kPrimaryActionColor, fontWeight: FontWeight.bold),
              ),
              onTap: () => _logOut(context),
            ),
          ),
        ],
      ),
    );
  }
}
