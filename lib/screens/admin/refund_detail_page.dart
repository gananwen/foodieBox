import 'package:flutter/material.dart';
import '../../util/styles.dart'; // Shared styles

const Map<String, dynamic> mockCaseData = {
  'id': '#0023',
  'name': 'Afsar Hossen',
  'vendor': 'Jaya Grocer',
  'date': '14/06/2025',
  'reason': 'Wrong order received',
  'status': 'Pending',
};

class RefundDetailPage extends StatelessWidget {
  final Map<String, dynamic> refundData;

  const RefundDetailPage({super.key, required this.refundData});

  // --- Read-only Field Widget
  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  kHintTextStyle.copyWith(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: kLabelTextStyle.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  // --- Status Badge Widget (Under Text)
  Widget _buildStatusField(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
        break;
      case 'Rejected':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        break;
      case 'Approved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.black54;
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status',
              style:
                  kHintTextStyle.copyWith(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: textColor.withOpacity(0.5)),
            ),
            child: Text(status,
                style: kHintTextStyle.copyWith(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = refundData.isEmpty ? mockCaseData : refundData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Management',
            style: TextStyle(color: kTextColor, fontSize: 18)),
        centerTitle: true,
      ),

      // --- Main Layout
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text('Case lists',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  // --- Unified Box for all Info Fields (same width & alignment)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReadOnlyField(
                            label: 'OrderID',
                            value: data['id']?.toString() ?? '#0000'),
                        const Divider(height: 1, color: Colors.black12),
                        _buildReadOnlyField(
                            label: 'Vendor',
                            value: data['vendor'] ?? 'Vendor Name'),
                        const Divider(height: 1, color: Colors.black12),
                        _buildReadOnlyField(
                            label: 'Customer',
                            value: data['name'] ?? 'Customer Name'),
                        const Divider(height: 1, color: Colors.black12),
                        _buildReadOnlyField(
                            label: 'Reason for Dispute',
                            value: data['reason'] ?? 'Wrong order received'),
                        const Divider(height: 1, color: Colors.black12),
                        _buildStatusField(data['status'] ?? 'Pending'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- Resolution Title
                  const Text('Resolution',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  // --- Text Field for Resolution Notes
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white,
                    ),
                    child: TextField(
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Explain the reason for your decision...',
                        hintStyle: kHintTextStyle,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Decline',
                        style: kLabelTextStyle.copyWith(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: Text('Approve',
                        style: kLabelTextStyle.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Testing Main ---
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RefundDetailPage(refundData: mockCaseData),
  ));
}
