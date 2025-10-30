import 'package:flutter/material.dart';
import 'package:foodiebox/screens/admin/admin_home_page.dart';
import 'package:foodiebox/screens/admin/profile_page.dart';
import 'general_settings_page.dart';
import 'lalamove_api_settings_page.dart';
import 'payment_gateaways_page.dart';
import 'fraud_detection_modal.dart';
import 'billing_invoices_page.dart';
import 'notifications_settings_page.dart';
import 'data_backup_page.dart';
import 'help_modal.dart';

class SettingsApp extends StatelessWidget {
  const SettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Settings Page',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0.5,
          iconTheme: IconThemeData(color: Color(0xFF1F2937)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          tileColor: Colors.white,
          dense: false,
        ),
        useMaterial3: true,
      ),
      home: const SettingsPage(),
    );
  }
}

// ===================== Settings Page =====================
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ===================== Navigation =====================
  void _navigateTo(String title) {
    switch (title) {
      case 'General':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GeneralSettingsPage()),
        );
        break;

      case 'Lalamove API Settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LalamoveApiSettingsPage()),
        );
        break;

      case 'Payment Gateways':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentGatewaysPage()),
        );
        break;

      case 'Fraud Detection':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const FraudDetectionModal(),
        );
        break;

      case 'Billing & Invoices':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BillingInvoicesPage()),
        );
        break;

      case 'Notifications':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsSettingsPage()),
        );
        break;

      case 'Data & Backup':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DataBackupPage()),
        );
        break;

      case 'Help':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const HelpModal(),
        );
        break;

      case 'About':
        showAboutDialog(
          context: context,
          applicationName: 'FoodieBox Admin',
          applicationVersion: '1.0.0',
          applicationLegalese: '© 2025 FoodieBox Technologies',
        );
        break;
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          },
        ),
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // ===================== Profile Section =====================
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              margin: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.person, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Hans Minero',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.edit,
                                size: 18, color: Colors.grey.shade600),
                          ],
                        ),
                        Text(
                          'Minerohans56@gmail.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===================== Settings Sections =====================
          _buildSectionTitle('General'),
          _buildSettingsTile(context,
              icon: Icons.settings_outlined,
              title: 'General',
              onTap: () => _navigateTo('General')),
          _buildSettingsTile(context,
              icon: Icons.api_outlined,
              title: 'Lalamove API Settings',
              onTap: () => _navigateTo('Lalamove API Settings')),
          _buildSettingsTile(context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payment Gateways',
              onTap: () => _navigateTo('Payment Gateways')),

          _buildSectionTitle('Security & Privacy'),
          _buildSettingsTile(context,
              icon: Icons.shield_outlined,
              title: 'Fraud Detection',
              onTap: () => _navigateTo('Fraud Detection'),
              badgeCount: 2),

          _buildSectionTitle('Billing'),
          _buildSettingsTile(context,
              icon: Icons.receipt_long_outlined,
              title: 'Billing & Invoices',
              onTap: () => _navigateTo('Billing & Invoices')),
          _buildSettingsTile(context,
              icon: Icons.notifications_none_outlined,
              title: 'Notifications',
              onTap: () => _navigateTo('Notifications'),
              badgeCount: 3),
          _buildSettingsTile(context,
              icon: Icons.refresh,
              title: 'Data & Backup',
              onTap: () => _navigateTo('Data & Backup')),

          _buildSectionTitle('Support'),
          _buildSettingsTile(context,
              icon: Icons.help_outline,
              title: 'Help',
              onTap: () => _navigateTo('Help')),
          _buildSettingsTile(context,
              icon: Icons.info_outline,
              title: 'About',
              onTap: () => _navigateTo('About')),
        ],
      ),
    );
  }

  // ===================== Section Title Helper =====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  // ===================== Settings Tile Helper =====================
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.grey.shade700, size: 24),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: Color(0xFF9CA3AF), size: 24),
          onTap: onTap,
          tileColor: Colors.white,
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey.shade200,
          indent: 16,
          endIndent: 0,
        ),
      ],
    );
  }
}

// ===================== Standalone Testing =====================
void main() {
  runApp(const SettingsApp());
}
