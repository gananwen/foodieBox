import 'package:flutter/material.dart';
import '../../util/styles.dart';

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

  // Data
  String _vendorName = '';
  String _address = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Navigation
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

  void _submitRegistration() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vendor $_vendorName registration complete!'),
        backgroundColor: kPrimaryActionColor,
      ),
    );
    Navigator.pop(context);
  }

  // Progress dots
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            color: isActive ? kPrimaryActionColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // Minimal input field
  Widget _buildMinimalField({
    required String label,
    required String hint,
    required FormFieldSetter<String> onSaved,
  }) {
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              )),
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
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                      onSaved: onSaved,
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

  // Upload container for documents
  Widget _buildDocumentUploadContainer({
    required String title,
    required String subtitle,
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
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Simulating upload for: $title')),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: kCardColor,
            ),
            child: const Center(
              child: Text(
                'Upload related documents',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------ PAGES ------------------

  Widget _page1() => Form(
        key: _formKey1,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Logo
              Container(
                width: 140,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54, width: 1),
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/App_icons.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Let's Get Started",
                  style: kLabelTextStyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: kTextColor)),
              const SizedBox(height: 6),
              Text(
                'Create an account to set your business to bloom!',
                style: kHintTextStyle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildMinimalField(
                  label: 'Vendor Name',
                  hint: 'Input',
                  onSaved: (v) => _vendorName = v ?? ''),
              _buildMinimalField(label: 'Logo', hint: 'Input', onSaved: (_) {}),
              _buildMinimalField(
                  label: 'Hours', hint: 'Input', onSaved: (_) {}),
              _buildMinimalField(
                  label: 'Address',
                  hint: 'Input',
                  onSaved: (v) => _address = v ?? ''),
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
              Text(
                'Confirm Your\nBusiness Account',
                textAlign: TextAlign.center,
                style: kLabelTextStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: kTextColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Please input real business email to use in the platform.',
                style: kHintTextStyle.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildMinimalField(
                  label: 'Email',
                  hint: 'Input',
                  onSaved: (v) => _email = v ?? ''),
              _buildMinimalField(
                  label: 'Password',
                  hint: 'Input',
                  onSaved: (v) => _password = v ?? ''),
              _buildMinimalField(
                  label: 'Confirm Password',
                  hint: 'Input',
                  onSaved: (v) => _confirmPassword = v ?? ''),
            ],
          ),
        ),
      );

  Widget _page3() => Form(
        key: _formKey3,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center content horizontally
            children: [
              Text(
                'Upload Your Documents',
                style: kLabelTextStyle.copyWith(fontSize: 20),
                textAlign: TextAlign.center, // Center text inside widget
              ),
              const SizedBox(height: 4),
              Text(
                'Please upload the required documents to verify business. '
                'This ensures platform safety and quality.',
                style: kHintTextStyle,
                textAlign: TextAlign.center, // Center text inside widget
              ),
              const SizedBox(height: 24),
              _buildDocumentUploadContainer(
                title: 'Business License',
                subtitle: '(Required)',
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadContainer(
                title: 'Halal Certification',
                subtitle: '(If applicable)',
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadContainer(
                title: 'Other Certifications',
                subtitle: '(Optional)',
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
                  child: const Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ------------------ BUILD ------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 🔸 Top bar — centered title and progress dots, arrow aligned left
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 70,
                child: Row(
                  children: [
                    // Back arrow
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      onPressed: _goToPreviousPage,
                    ),

                    // Spacer
                    const SizedBox(width: 8),

                    // Title and dots stacked vertically
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Store Setup',
                            style: kLabelTextStyle.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildDots(), // Make sure this reflects current page visually
                        ],
                      ),
                    ),

                    // Invisible spacer to balance layout
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // 🔹 PageView Section
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _page1(),
                  _page2(),
                  _page3(),
                ],
              ),
            ),

            // 🔹 Next Button (hidden on last page)
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
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
