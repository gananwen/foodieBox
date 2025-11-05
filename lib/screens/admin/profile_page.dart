import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/admin_login.dart';
import 'admin_home_page.dart';
import 'attendance_logs_page.dart';

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
  // Employee info
  String name = 'Hans Minero';
  String email = 'Minerohans56@gmail.com';
  String phone = '+1 234 567 890';
  String role = 'Admin';
  String status = 'Active';

  File? profileImage;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  // Capture image from camera
  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 500,
      maxHeight: 500,
    );
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  // Open modal for editing profile
  void _openEditProfileModal() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);
    final roleController = TextEditingController(text: role);
    String tempStatus = status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: profileImage != null
                          ? FileImage(profileImage!)
                          : null,
                      child: profileImage == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: PopupMenuButton(
                        onSelected: (String value) {
                          if (value == 'Gallery') {
                            _pickFromGallery();
                          } else if (value == 'Camera') {
                            _pickFromCamera();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'Gallery',
                              child: Text('Choose from Gallery')),
                          const PopupMenuItem(
                              value: 'Camera', child: Text('Take Photo')),
                        ],
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.camera_alt, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField('Name', nameController),
              _buildTextField('Email', emailController,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField('Phone', phoneController,
                  keyboardType: TextInputType.phone),
              _buildTextField('Role', roleController),
              const SizedBox(height: 16),
              const Text('Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: ['Active', 'On Leave', 'Suspended'].map((s) {
                  final isSelected = s == tempStatus;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    selectedColor: statusColors[s],
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
                    onSelected: (_) {
                      setState(() {
                        tempStatus = s;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      name = nameController.text;
                      email = emailController.text;
                      phone = phoneController.text;
                      role = roleController.text;
                      status = tempStatus;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ================= Open Change Password Modal =================
  void _openChangePasswordModal() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                  child: Text('Change Password',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              _buildTextField('Current Password', currentPasswordController,
                  obscureText: true),
              _buildTextField('New Password', newPasswordController,
                  obscureText: true),
              _buildTextField('Confirm New Password', confirmPasswordController,
                  obscureText: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    // TODO: Add password validation & save logic
                    Navigator.pop(context);
                  },
                  child: const Text('Save Password',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ================= Open Payroll / Payment Info Modal =================
  void _openPayrollInfoModal() {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ifscController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                  child: Text('Payroll / Payment Info',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              _buildTextField('Bank Name', bankNameController),
              _buildTextField('Account Number', accountNumberController,
                  keyboardType: TextInputType.number),
              _buildTextField('IFSC / Routing Code', ifscController),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    // TODO: Add save logic
                    Navigator.pop(context);
                  },
                  child: const Text('Save Info',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminHomePage(),
              ),
            );
          },
        ),
        title: const Text('Employee Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // ===================== Employee Card =====================
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                  child: profileImage == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text('Employee ID: #A12345',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text('Role: $role',
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColors[status],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.email, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 6),
                    Text(email,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 6),
                    Text(phone,
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ================= Updated Action Tiles =================
          _buildActionTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: _openEditProfileModal),
          _buildActionTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: _openChangePasswordModal),
          _buildActionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payroll / Payment Info',
              onTap: _openPayrollInfoModal),
          _buildActionTile(
              icon: Icons.history,
              title: 'Attendance & Logs',
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AttendanceLogsPage()),
                  )),

          const SizedBox(height: 32),

          // ================= Logout =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
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
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfilePage(),
  ));
}
