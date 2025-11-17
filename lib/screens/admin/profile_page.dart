import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/admin_login.dart';
import 'admin_home_page.dart';
import 'attendance_logs_page.dart';

// ⭐️ Consistent Modern Color Palette ⭐️
const Color _kPrimaryActionColor = Color(0xFF1E88E5); // Vibrant Blue
const Color _kAppBackgroundColor =
    Color(0xFFF5F7F9); // Light, neutral background
const Color _kTextColor = Color(0xFF1F2937); // Dark text
const Color _kSecondaryTextColor = Color(0xFF6B7280); // Grey hint text
const Color _kSuccessColor = Color(0xFF4CAF50); // Green for success
const Color _kErrorColor = Color(0xFFE53935); // Red for errors

// Status colors mapping
Map<String, Color> statusColors = {
  'Active': Colors.green,
  'On Leave': Colors.orange,
  'Suspended': Colors.red,
};

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  File? profileImage;

  // Employee info
  String name = '';
  String email = '';
  String phone = '';
  String role = '';
  String status = '';

  bool _isLoading = true;
  bool _isEditing = false; // Edit mode flag

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? '';
          email = data['email'] ?? user.email ?? '';
          phone = data['phone'] ?? '';
          role = data['role'] ?? 'Admin';
          status = data['status'] ?? 'Active';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  // =================== Image Picker ===================
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => profileImage = File(image.path));
  }

  // =================== Save Profile ===================
  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('admins').doc(user.uid).update({
        'name': name,
        'phone': phone,
        // You can add profile image upload to Firebase Storage here
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  // =================== Build UI ===================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        // === CHANGE 1: Header Color Updated ===
        backgroundColor: const Color.fromARGB(255, 114, 158, 199),
        foregroundColor: Colors.white, // Ensure icons/text are visible
        // ======================================
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomePage()),
          ),
        ),
        title: const Text('Admin Profile'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(),
                const SizedBox(height: 32),
                _buildActionTile(
                    icon: Icons.edit,
                    title: _isEditing ? 'Cancel Edit' : 'Edit Profile',
                    onTap: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    }),
                _buildActionTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: _changePasswordDialog,
                ),
                _buildActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payroll / Payment Info',
                  onTap: _showPayrollDialog,
                ),
                _buildActionTile(
                    icon: Icons.history,
                    title: 'Attendance & Logs',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AttendanceLogsPage()))),
                const SizedBox(height: 32),
                _logoutButton(),
              ],
            ),
    );
  }

  // =================== Profile Card ===================
  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickFromGallery : null,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  profileImage != null ? FileImage(profileImage!) : null,
              child: profileImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _isEditing
              ? TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (val) => name = val,
                )
              : Text(name.isNotEmpty ? name : 'No name',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937))),
          const SizedBox(height: 4),
          Text('Email: ${email.isNotEmpty ? email : "N/A"}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text('Role: ${role.isNotEmpty ? role : "N/A"}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColors[status] ?? Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status.isNotEmpty ? status : 'Unknown',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _isEditing
              ? TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  onChanged: (val) => phone = val,
                  keyboardType: TextInputType.phone,
                )
              : (phone.isNotEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(phone,
                            style: const TextStyle(color: Colors.black87)),
                      ],
                    )
                  : Container()),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
            ),
        ],
      ),
    );
  }

// =================== Change Password Dialog ===================
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

  // =================== Payment Info Dialog ===================
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
        // FIX: Changed TextController to TextEditingController
        TextEditingController(text: data['salary']?.toString() ?? '');

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(20),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bankController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter bank name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Enter account number'
                        : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ifscController,
                    decoration: InputDecoration(
                      labelText: 'IFSC / Routing Code',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter IFSC code' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salaryController,
                    decoration: InputDecoration(
                      labelText: 'Salary',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Enter salary' : null,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Payment info updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
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

  // =================== Action Tile ===================
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey.shade700, size: 24),
          title: Text(title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937))),
          trailing: const Icon(Icons.chevron_right,
              color: Color(0xFF9CA3AF), size: 24),
          onTap: onTap,
          tileColor: Colors.white,
        ),
        Divider(
            height: 1, thickness: 1, color: Colors.grey.shade200, indent: 16),
      ],
    );
  }

  // =================== Logout Button ===================
  Widget _logoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.logout),
      label: const Text('Logout',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onPressed: () async {
        await _auth.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        );
      },
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfilePage(),
  ));
}
