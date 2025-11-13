import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// ====== STYLE CONSTANTS ======
const kPrimaryActionColor = Color(0xFF4A47A3);
const kCardColor = Color(0xFFF9F9F9);
const kAppBackgroundColor = Color(0xFFF5F5F5);
const kTextColor = Colors.black87;

const kLabelTextStyle = TextStyle(
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const kHintTextStyle = TextStyle(
  fontSize: 13,
  color: Colors.black54,
);

// =============================== MODEL ===============================
class Vendor {
  final String uid;
  final String storeName;
  final String storeAddress;
  final String email;
  final String? storePhone;
  final String? storeHours;
  final String? vendorType;
  final String? businessLicenseUrl;
  final String? halalCertificateUrl;
  final String? businessPhotoUrl;
  final bool isApproved;
  final bool isLocked;
  final double rating;
  final DateTime? createdAt;
  final DateTime? approvedAt;

  Vendor({
    required this.uid,
    required this.storeName,
    required this.storeAddress,
    required this.email,
    this.storePhone,
    this.storeHours,
    this.vendorType,
    this.businessLicenseUrl,
    this.halalCertificateUrl,
    this.businessPhotoUrl,
    this.isApproved = false,
    this.isLocked = false,
    this.rating = 0,
    this.createdAt,
    this.approvedAt,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'storeName': storeName,
        'storeAddress': storeAddress,
        'email': email,
        'storePhone': storePhone,
        'storeHours': storeHours,
        'vendorType': vendorType,
        'businessLicenseUrl': businessLicenseUrl,
        'halalCertificateUrl': halalCertificateUrl,
        'businessPhotoUrl': businessPhotoUrl,
        'isApproved': isApproved,
        'isLocked': isLocked,
        'rating': rating,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'approvedAt': approvedAt,
      };
}

// =============================== PAGE ===============================
class VendorRegisterPage extends StatefulWidget {
  const VendorRegisterPage({super.key});

  @override
  State<VendorRegisterPage> createState() => _VendorRegisterPageState();
}

class _VendorRegisterPageState extends State<VendorRegisterPage> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  late PageController _pageController;
  int _currentPage = 0;

  // Text controllers
  final _vendorNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeHoursController = TextEditingController();
  final _storePhoneController = TextEditingController();

  // Files
  File? _businessLicenseFile;
  File? _halalCertFile;
  File? _businessPhotoFile;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _vendorNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storeHoursController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  // =============================== NAVIGATION ===============================
  void _goToNextPage() {
    final forms = [_formKey1, _formKey2, _formKey3];
    if (forms[_currentPage].currentState?.validate() ?? true) {
      forms[_currentPage].currentState?.save();
      if (_currentPage < 2) {
        setState(() => _currentPage++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // =============================== FILE UPLOAD ===============================
  Future<String> _uploadFile(File? file, String path, String docId) async {
    if (file == null) return '';
    final ref = FirebaseStorage.instance.ref(
        'vendors/$docId/$path-${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // =============================== SUBMIT REGISTRATION ===============================
  Future<void> _submitRegistration() async {
    if (_businessLicenseFile == null || _businessPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload required documents.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading documents...')),
      );

      final vendorRef = FirebaseFirestore.instance.collection('vendors').doc();
      final docId = vendorRef.id;

      // Upload documents
      final licenseUrl =
          await _uploadFile(_businessLicenseFile, 'business_license', docId);
      final halalUrl =
          await _uploadFile(_halalCertFile, 'halal_certificate', docId);
      final photoUrl =
          await _uploadFile(_businessPhotoFile, 'business_photo', docId);

      // Build Vendor object
      final vendor = Vendor(
        uid: docId,
        storeName: _vendorNameController.text.trim(),
        storeAddress: _addressController.text.trim(),
        storePhone: _storePhoneController.text.trim().isEmpty
            ? null
            : _storePhoneController.text.trim(),
        storeHours: _storeHoursController.text.trim(),
        email: _emailController.text.trim(),
        businessLicenseUrl: licenseUrl,
        halalCertificateUrl: halalUrl.isEmpty ? null : halalUrl,
        businessPhotoUrl: photoUrl,
        isApproved: false, // Admin must approve
        isLocked: false,
        rating: 0,
        vendorType: 'Restaurant',
        createdAt: DateTime.now(),
        approvedAt: null,
      );

      // Save to Firestore
      await vendorRef.set(vendor.toMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Registration submitted successfully! Please wait for admin approval.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting registration: $e')));
    }
  }

  // =============================== UI HELPERS ===============================
  Widget _buildDots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final active = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 12 : 8,
            height: active ? 12 : 8,
            decoration: BoxDecoration(
              color: active ? kPrimaryActionColor : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          );
        }),
      );

  Widget _buildMinimalField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      controller: controller,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, size: 20, color: Colors.black54),
                  onPressed: () => controller.clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadContainer({
    required String title,
    required String subtitle,
    required void Function(File file) onFilePicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
            const SizedBox(width: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              onFilePicked(File(picked.path));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Selected: ${picked.name}')),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(8),
              color: kCardColor,
            ),
            child: const Center(
              child: Text('Upload related documents',
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  // =============================== PAGES ===============================
  Widget _page1() => Form(
        key: _formKey1,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 140,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/App_icons.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Let's Get Started",
                  style: kLabelTextStyle.copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              Text('Create an account to set your business to bloom!',
                  style: kHintTextStyle, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _buildMinimalField(
                  label: 'Vendor Name',
                  hint: 'e.g. Pizza Palace',
                  controller: _vendorNameController),
              _buildMinimalField(
                  label: 'Store Hours',
                  hint: 'e.g. 9:00 AM - 6:00 PM',
                  controller: _storeHoursController),
              _buildMinimalField(
                  label: 'Address',
                  hint: 'e.g. 123 Main Street',
                  controller: _addressController),
              _buildMinimalField(
                  label: 'Store Phone (Optional)',
                  hint: 'e.g. +123456789',
                  controller: _storePhoneController),
            ],
          ),
        ),
      );

  Widget _page2() => Form(
        key: _formKey2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text('Confirm Your Business Account',
                  style: kLabelTextStyle.copyWith(fontSize: 20)),
              const SizedBox(height: 6),
              Text('Use a valid business email address.',
                  style: kHintTextStyle),
              const SizedBox(height: 24),
              _buildMinimalField(
                  label: 'Email',
                  hint: 'Business email',
                  controller: _emailController),
              _buildMinimalField(
                  label: 'Password',
                  hint: 'Enter password',
                  controller: _passwordController,
                  obscure: true),
              _buildMinimalField(
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  controller: _confirmPasswordController,
                  obscure: true),
            ],
          ),
        ),
      );

  Widget _page3() => Form(
        key: _formKey3,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Upload Your Documents',
                  style: kLabelTextStyle.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                  'Please upload the required documents to verify your business.',
                  style: kHintTextStyle,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _buildDocumentUploadContainer(
                title: 'Business License',
                subtitle: '(Required)',
                onFilePicked: (file) => _businessLicenseFile = file,
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadContainer(
                title: 'Halal Certification',
                subtitle: '(If applicable)',
                onFilePicked: (file) => _halalCertFile = file,
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadContainer(
                title: 'Business Photo',
                subtitle: '(Required)',
                onFilePicked: (file) => _businessPhotoFile = file,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _submitRegistration,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryActionColor,
                    side:
                        const BorderSide(color: kPrimaryActionColor, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: kCardColor,
                  ),
                  child: const Text("Submit",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );

  // =============================== BUILD ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 70,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: _goToPreviousPage,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Store Setup',
                              style: kLabelTextStyle.copyWith(fontSize: 22)),
                          const SizedBox(height: 4),
                          _buildDots(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [_page1(), _page2(), _page3()],
              ),
            ),
            if (_currentPage < 2)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _goToNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryActionColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
