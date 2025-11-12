import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../util/styles.dart';

// --- 1. 更改导入 ---
// import '../../screens/auth_wrapper.dart'; // <-- 移除这个
import '../auth/vendor_login.dart'; // <-- 添加这个 (请确认路径是否正确)

import 'account_settings_page.dart';
import '../shared/notifications_page.dart';
import '../shared/help_page.dart';
import '../shared/about_page.dart';

// --- "More" 页面 (Figure 26 的新样式) ---
class MorePage extends StatelessWidget {
  final VoidCallback onBackToDashboard;
  const MorePage({super.key, required this.onBackToDashboard});

  // --- (辅助) 构建顶部的个人资料卡片 ---
  Widget _buildProfileHeader() {
    const String vendorName = "Afsar Hossen";
    const String vendorId = "VendorID: 1234";

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: kCardColor, // 白色背景
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(26), width: 1.5),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: kSecondaryAccentColor, // 浅绿色
            child: Icon(Icons.person, size: 40, color: kTextColor),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    vendorName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_outlined,
                      size: 18, color: kTextColor.withAlpha(179)),
                ],
              ),
              Text(
                vendorId,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextColor.withAlpha(153),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- (辅助) 构建列表项 ---
  Widget _buildListTile(
      BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: kTextColor.withAlpha(204)),
      title:
          Text(title, style: const TextStyle(color: kTextColor, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: kTextColor, size: 20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }

  // --- 2. (辅助) 登出函数 (已修改) ---
  void _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        // --- 立即导航到 Vendor 登录页 ---
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
        title: const Text('Settings'), // 标题改为 "Settings"
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: onBackToDashboard,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. 顶部的个人资料卡片 (Figure 26 样式)
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // 2. 菜单列表
          _buildListTile(
            context,
            Icons.person_outline, // 账户图标
            'Account & Store Settings', // 合并的功能
            const AccountSettingsPage(), // 链接到占位符
          ),
          const Divider(height: 1),
          // --- 2. 修复链接 (NotificationPage -> NotificationsPage) ---
          _buildListTile(
            context,
            Icons.notifications_none_outlined, // 通知图标
            'Notifications',
            const NotificationsPage(), // 链接到你队友的 NotificationsPage
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            Icons.help_outline, // 帮助图标
            'Help & Support',
            const HelpPage(), // 链接到你队友的 HelpPage
          ),
          const Divider(height: 1),
          _buildListTile(
            context,
            Icons.info_outline, // "About" 图标
            'About FoodieBox',
            const AboutPage(), // 链接到你队友的 AboutPage
          ),
          const Divider(height: 1),
          const SizedBox(height: 40),

          // 3. 登出按钮
          Container(
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12.0),
              border:
                  Border.all(color: kPrimaryActionColor.withAlpha(100)), // 红色边框
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.logout, color: kPrimaryActionColor), // 高亮色
              title: const Text(
                'Log Out',
                style: TextStyle(
                    color: kPrimaryActionColor, fontWeight: FontWeight.bold),
              ),
              onTap: () => _logOut(context), // 调用登出函数
            ),
          ),
        ],
      ),
    );
  }
}
