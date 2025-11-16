import 'package:flutter/material.dart';
import 'package:foodiebox/screens/admin/attendance_logs_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ⭐️ Consistent Modern Color Palette ⭐️
const Color _kPrimaryActionColor = Color(0xFF1E88E5); // Vibrant Blue
const Color _kAppBackgroundColor =
    Color(0xFFF5F7F9); // Light, neutral background
const Color _kTextColor = Color(0xFF1F2937); // Dark text
const Color _kSecondaryTextColor = Color(0xFF6B7280); // Grey hint text
const Color _kSuccessColor = Color(0xFF4CAF50); // Green for success
const Color _kErrorColor = Color(0xFFE53935); // Red for errors

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  State<GeneralSettingsPage> createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('General Settings',
            style: TextStyle(color: _kTextColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _kTextColor),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            icon: Icons.lock_open_outlined,
            title: 'Change Password',
            subtitle: 'Update your account password securely',
            onTap: _changePasswordDialog,
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payroll / Payment Info',
            subtitle: 'View or edit your bank and salary details',
            onTap: _showPayrollDialog,
          ),
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.history_toggle_off_outlined,
            title: 'Attendance & Logs',
            subtitle: 'View detailed attendance records and activity',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceLogsPage()),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Reusable Settings Tile (Revised Style)
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: _kPrimaryActionColor, size: 28),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kTextColor),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(subtitle,
                    style:
                        TextStyle(fontSize: 13, color: _kSecondaryTextColor)),
              )
            : null,
        trailing:
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 26),
        onTap: onTap,
      ),
    );
  }

  // =================== Change Password Dialog (Fix Applied) ===================
  Future<void> _changePasswordDialog() async {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kTextColor),
                  ),
                  const SizedBox(height: 24),

                  // Text Fields using theme color
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: _kSecondaryTextColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _kPrimaryActionColor, width: 2.0),
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter current password'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon:
                          const Icon(Icons.lock, color: _kSecondaryTextColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _kPrimaryActionColor, width: 2.0),
                      ),
                    ),
                    validator: (val) => val == null || val.length < 6
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon:
                          const Icon(Icons.lock, color: _kSecondaryTextColor),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: _kPrimaryActionColor, width: 2.0),
                      ),
                    ),
                    validator: (val) => val != _newPasswordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 28),

                  // 🚨 FIX: Using Expanded/Flexible within the Row 🚨
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel Button
                      Flexible(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: _kSecondaryTextColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Change Password Button
                      Flexible(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryActionColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          // Logic remains untouched
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final user = _auth.currentUser;
                            if (user == null) return;

                            final cred = EmailAuthProvider.credential(
                              email: user.email!,
                              password: _currentPasswordController.text,
                            );

                            try {
                              await user.reauthenticateWithCredential(cred);
                              await user
                                  .updatePassword(_newPasswordController.text);

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Password updated successfully!'),
                                    backgroundColor: _kSuccessColor),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: _kErrorColor,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'CHANGE PASSWORD',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign
                                .center, // Added alignment for potential wrapping
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =================== Payroll Dialog (Fix Applied) ===================
  Future<void> _showPayrollDialog() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('admins').doc(user.uid).get();
    final data = doc.data()?['paymentInfo'] ?? {};

    final _bankController = TextEditingController(text: data['bankName'] ?? '');
    final _accountController =
        TextEditingController(text: data['accountNumber'] ?? '');
    final _ifscController = TextEditingController(text: data['ifsc'] ?? '');
    final _salaryController =
        TextEditingController(text: data['salary']?.toString() ?? '');

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Payroll / Payment Info',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _kTextColor),
                  ),
                  const SizedBox(height: 24),

                  // Text fields
                  ...[
                    _bankController,
                    _accountController,
                    _ifscController,
                    _salaryController
                  ].asMap().entries.map((entry) {
                    int idx = entry.key;
                    TextEditingController controller = entry.value;
                    String label = [
                      'Bank Name',
                      'Account Number',
                      'IFSC / Routing Code',
                      'Salary'
                    ][idx];
                    TextInputType keyboard = (idx == 1 || idx == 3)
                        ? TextInputType.number
                        : TextInputType.text;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: controller,
                        keyboardType: keyboard,
                        decoration: InputDecoration(
                          labelText: label,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: _kPrimaryActionColor, width: 2.0),
                          ),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter $label' : null,
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 12),

                  // 🚨 FIX: Using Flexible/Expanded within the Row 🚨
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel Button
                      Flexible(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _kSecondaryTextColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Save Button
                      Flexible(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimaryActionColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          // Logic remains untouched
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            try {
                              await _firestore
                                  .collection('admins')
                                  .doc(user.uid)
                                  .update({
                                'paymentInfo': {
                                  'bankName': _bankController.text,
                                  'accountNumber': _accountController.text,
                                  'ifsc': _ifscController.text,
                                  'salary':
                                      int.tryParse(_salaryController.text) ?? 0,
                                }
                              });

                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Payment info updated successfully!'),
                                    backgroundColor: _kSuccessColor),
                              );

                              Navigator.pop(context);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: _kErrorColor),
                              );
                            }
                          },
                          child: const Text('SAVE',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
