import 'package:flutter/material.dart';
import '../../util/styles.dart';

import 'edit_profile_page.dart';
import 'edit_store_details_page.dart';
// --- 1. 导入 Repository ---
import '../../repositories/vendor_data_repository.dart';

class AccountSettingsPage extends StatefulWidget {
  final VendorDataBundle bundle; // <-- 2. 接收数据
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

  @override
  Widget build(BuildContext context) {
    // --- 4. (新增) 从 widget 中获取真实数据 ---
    final user = widget.bundle.user;
    final vendor = widget.bundle.vendor;

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
          // --- 5. (已修改) 个人账户部分 ---
          _buildSectionHeader('ACCOUNT INFORMATION'),
          _buildInfoTile(
            'Full Name',
            "${user.firstName} ${user.lastName}", // 真实数据
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      // --- 传递数据 ---
                      builder: (context) =>
                          EditProfilePage(bundle: widget.bundle)));
            },
          ),
          _buildInfoTile(
            'Email',
            user.email, // 真实数据
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      // --- 传递数据 ---
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
                      // --- 传递数据 ---
                      builder: (context) =>
                          EditProfilePage(bundle: widget.bundle)));
            },
          ),

          // --- 6. (已修改) 店铺设置部分 ---
          _buildSectionHeader('STORE INFORMATION'),
          _buildInfoTile(
            'Store Details', // <-- (修改) 移除 Hours
            '${vendor.storeName}\n${vendor.storeAddress}',
            () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      // --- 传递数据 ---
                      builder: (context) =>
                          EditStoreDetailsPage(bundle: widget.bundle)));
            },
          ),
          _buildInfoTile(
            'Payment Methods',
            'Bank Transfer, E-Wallets',
            () {
              // TODO: 跳转到 Payment Methods 页面
            },
          ),
          _buildInfoTile(
            'Data & Backup',
            'Manage your data',
            () {
              // TODO: 跳转到 Data & Backup 页面
            },
          ),
        ],
      ),
    );
  }
}
