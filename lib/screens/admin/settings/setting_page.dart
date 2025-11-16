import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/screens/admin/admin_home_page.dart';
import 'package:foodiebox/screens/admin/profile_page.dart';
import 'general_settings_page.dart';
import 'admin_action_history_page.dart';
import 'data_backup_page.dart'; // Assuming this imports FirestoreBackupSimulator
import 'help_modal.dart';

// ⭐️ Defined Internal Styles for Modern Look ⭐️
const Color _kPrimaryActionColor = Color(0xFF1E88E5); // Vibrant Blue
const Color _kAppBackgroundColor =
    Color(0xFFF5F7F9); // Light, neutral background
const Color _kTextColor = Color(0xFF1F2937); // Dark text
const Color _kSecondaryTextColor = Color(0xFF6B7280); // Grey hint text
// ⭐️ END OF INTERNAL STYLES ⭐️

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
      case 'Admin Action History':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminActionHistoryPage()),
        );
        break;
      case 'Data & Backup':
        // Assuming FirestoreBackupSimulator is imported via data_backup_page.dart
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FirestoreBackupSimulator()),
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
          applicationLegalese:
              '© 2025 FoodieBox Technologies. All rights reserved.',
          applicationIcon: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // Ensure this asset path is correct
              child: Image.asset(
                'assets/images/App_icons.png',
                height: 48,
                width: 48,
              ),
            ),
          ),
          children: [
            const SizedBox(height: 12),
            const Text(
              'FoodieBox Admin helps you efficiently manage restaurants, orders, and delivery integrations in one secure dashboard.',
              style: TextStyle(
                fontSize: 15,
                color: _kTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "View Licenses" below to see open-source attributions.',
              style: TextStyle(
                fontSize: 13,
                color: _kSecondaryTextColor,
              ),
            ),
          ],
        );
        break;
    }
  }

  // ===================== Section Title Helper =====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24, 0, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(), // Uppercase for a modern look
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _kSecondaryTextColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ===================== Settings Tile Helper (Revised) =====================
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(
          bottom: 1), // Minimal vertical spacing between tiles
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: Icon(icon,
            color: _kPrimaryActionColor, size: 24), // Icon uses Blue accent
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _kTextColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 24),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // ===================== Separator Helper =====================
  // This will be used to divide the tiles within a section
  Widget _buildTileSeparator() {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = userData?['name'] ?? 'Your Name';
    final email = userData?['email'] ?? _auth.currentUser?.email ?? '';
    final avatarUrl = userData?['avatarUrl'];
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjusted responsive padding for cleaner look on large screens
    final horizontalPadding = screenWidth < 600 ? 0.0 : screenWidth * 0.15;

    return Scaffold(
      backgroundColor: _kAppBackgroundColor, // Light neutral background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _kTextColor, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomePage()),
            );
          },
        ),
        title: const Text('Settings',
            style: TextStyle(color: _kTextColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1, // Slight shadow
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: horizontalPadding,
          ),
          child: Column(
            children: [
              // ===================== Profile Section (Card) =====================
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
                    borderRadius:
                        BorderRadius.circular(16), // Larger rounded corner
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20.0),
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _kPrimaryActionColor
                            .withOpacity(0.1), // Blue tinted background
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Icon(Icons.person,
                                size: 40,
                                color: _kPrimaryActionColor) // Blue icon
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14,
                                color: _kSecondaryTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: _kPrimaryActionColor,
                          size: 28), // Blue chevron
                    ],
                  ),
                ),
              ),

              // ===================== Settings Sections (List Grouped) =====================

              // --- Group: General ---
              _buildSectionTitle('General'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(context,
                        icon: Icons.settings_outlined,
                        title: 'General',
                        onTap: () => _navigateTo('General')),
                    _buildTileSeparator(),
                    _buildSettingsTile(context,
                        icon: Icons.history_rounded,
                        title: 'Admin Action History',
                        onTap: () => _navigateTo('Admin Action History'),
                        badgeCount: 0),
                    _buildTileSeparator(),
                    _buildSettingsTile(context,
                        icon: Icons.cloud_sync_outlined,
                        title: 'Data & Backup',
                        onTap: () => _navigateTo('Data & Backup')),
                  ],
                ),
              ),

              // --- Group: Support ---
              _buildSectionTitle('Support'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(context,
                        icon: Icons
                            .support_agent_outlined, // Changed icon for help
                        title: 'Help',
                        onTap: () => _navigateTo('Help')),
                    _buildTileSeparator(),
                    _buildSettingsTile(context,
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () => _navigateTo('About')),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // --- Logout Button ---
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    await _auth.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AdminHomePage()), // Navigate to home or login after logout
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Log Out',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300)),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
