import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:foodiebox/enums/checkout_type.dart';
import 'package:foodiebox/screens/users/order_failure_page.dart';
import 'package:foodiebox/screens/users/main_page.dart'; 

class QrPaymentPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final CheckoutType orderType;

  const QrPaymentPage({
    super.key,
    required this.orderData,
    required this.orderType,
  });

  @override
  State<QrPaymentPage> createState() => _QrPaymentPageState();
}

class _QrPaymentPageState extends State<QrPaymentPage> {
  File? _paymentProofImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _paymentProofImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadProof(String orderId, File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_proofs')
          .child('$orderId.jpg');
      
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {

      debugPrint("Error uploading payment proof: $e"); 
      throw Exception('Failed to upload proof.');
    }
  }

  Future<void> _confirmPayment() async {
    if (_paymentProofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your payment proof first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    DocumentReference? orderDocRef;
    
    try {
      orderDocRef = await FirebaseFirestore.instance
          .collection('orders')
          .add({
            ...widget.orderData,
            'paymentProofUrl': null, 
          });
      final orderId = orderDocRef.id;
      final String downloadUrl = await _uploadProof(orderId, _paymentProofImage!);

      await orderDocRef.update({
        'paymentProofUrl': downloadUrl,
      });
      if (mounted) {
          context.read<CartProvider>().clearCart();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment proof submitted! Check your Orders tab for status updates.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blueGrey,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(

            builder: (context) => const MainPage(), 
          ),
          (route) => route.isFirst,
        );

      }

    } catch (e) {
      debugPrint("Failed to place order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: Colors.red,
        ),
      );

      if (orderDocRef != null) {
          orderDocRef.delete().catchError((error) => debugPrint("Error deleting order: $error"));
      }
      if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OrderFailurePage()),
            );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = widget.orderData['total'];

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Complete Payment', style: TextStyle(color: kTextColor)),
        backgroundColor: kYellowMedium,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title and Total amount
            Text(
              'Scan to Pay',
              style: kLabelTextStyle.copyWith(fontSize: 24), 
            ),
            const SizedBox(height: 8),
            Text(
              'Please pay RM${total.toStringAsFixed(2)}',
              style: kLabelTextStyle.copyWith(
                fontSize: 20,
                color: kPrimaryActionColor,
              ),
            ),
            const SizedBox(height: 24),
            // The QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: 'foodiebox-payment-total-${total.toStringAsFixed(2)}', // Example QR data
                version: QrVersions.auto,
                size: 250.0,
                gapless: false,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan with your preferred e-wallet or banking app.',
              style: kHintTextStyle,
              textAlign: TextAlign.center,
            ),
            const Divider(height: 40),

            // Upload Proof Section
            const Text(
              'Upload Payment Proof',
              style: kLabelTextStyle,
            ),
            const SizedBox(height: 16),

            // Image Preview
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
              child: _paymentProofImage == null
                  ? const Center(
                      child: Text('No image selected.', style: kHintTextStyle),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        _paymentProofImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Select Proof from Gallery'),
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryActionColor,
                  side: const BorderSide(color: kPrimaryActionColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Confirm Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: 30),
        decoration: BoxDecoration(
          color: kCardColor,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryActionColor,
            foregroundColor: kTextColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: kTextColor,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'Confirm Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}