// 路径: lib/pages/vendor_home/account_settings_page.dart
import 'package:flutter/material.dart';
import '../../util/styles.dart';

import 'edit_profile_page.dart';
import 'edit_store_details_page.dart';
import 'edit_store_hours_page.dart';
import 'delete_account_page.dart';

import '../../repositories/vendor_data_repository.dart';

class AccountSettingsPage extends StatefulWidget {
  final VendorDataBundle bundle;
  const AccountSettingsPage({super.key, required this.bundle});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  // --- (辅助) 构建分区标题 ---
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: kTextColor.withAlpha(179), // 70%
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- (辅助) 构建可点击的设置项 ---
  Widget _buildInfoTile(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: kTextColor.withAlpha(26), width: 1.5),
      ),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(
                color: kTextColor, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: kTextColor.withAlpha(153))), // 60%
        trailing: const Icon(Icons.chevron_right, color: kTextColor, size: 20),
        onTap: onTap,
      ),
    );
  }

  // --- (辅助) 危险操作的 Tile ---
  Widget _buildDangerTile(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border:
            Border.all(color: kPrimaryActionColor.withAlpha(70), width: 1.5),
      ),
      child: ListTile(
        title: Text(title,
            style: const TextStyle(
                color: kPrimaryActionColor, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: kPrimaryActionColor.withAlpha(180))),
        trailing: const Icon(Icons.chevron_right,
            color: kPrimaryActionColor, size: 20),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.bundle.user;
    final vendor = widget.bundle.vendor;

    // 为营业时间创建一个可读的字符串
    final String storeHoursSubtitle = vendor.storeHours.isEmpty
        ? 'Tap to set your store hours'
        : vendor.storeHours.join('\n'); // (e.g., "Mon: 9-5", "Tue: 9-5")

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Account & Store'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          // --- 个人账户部分 ---
          _buildSectionHeader('ACCOUNT INFORMATION'),
          _buildInfoTile(
            'Full Name',
            "${user.firstName} ${user.lastName}",
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(bundle: widget.bundle)));
            },
          ),
          _buildInfoTile(
            'Email',
            user.email,
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(bundle: widget.bundle)));
            },
          ),
          _buildInfoTile(
            'Password',
            '********',
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditProfilePage(bundle: widget.bundle)));
            },
          ),

          // --- 店铺设置部分 ---
          _buildSectionHeader('STORE INFORMATION'),
          _buildInfoTile(
            'Store Details',
            '${vendor.storeName}\n${vendor.storeAddress}',
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditStoreDetailsPage(bundle: widget.bundle)));
            },
          ),
          _buildInfoTile(
            'Store Hours',
            storeHoursSubtitle,
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      // (传递 vendor 数据，因为它包含了 storeHours)
                      builder: (context) =>
                          EditStoreHoursPage(vendor: widget.bundle.vendor)));
            },
          ),

          // --- 危险区域 ---
          _buildSectionHeader('DANGER ZONE'),
          _buildDangerTile(
            'Delete Account',
            'Permanently delete your vendor account',
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DeleteAccountPage()));
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
