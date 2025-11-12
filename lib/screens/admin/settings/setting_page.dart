import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class SettingsApp extends StatefulWidget {
  const SettingsApp({super.key});

  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('admins').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        userData = doc.data();
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final displayName = userData?['name'] ?? 'Your Name';
    final email = userData?['email'] ?? _auth.currentUser?.email ?? '';
    final avatarUrl = userData?['avatarUrl'];

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context)
            .colorScheme
            .copyWith(surfaceTint: Colors.transparent), // Remove lilac tint
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
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
          backgroundColor: Colors.white, // Make the AppBar pure white
          surfaceTintColor: Colors.transparent, // Remove M3 tint overlay
          elevation: 0.5, // Optional: keeps a subtle shadow
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
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
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 36, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
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
                            email,
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
      ),
    );
  }

  // ===================== Section Title Helper =====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
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
        trailing:
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 24),
        onTap: onTap,
      ),
    );
  }
}
