import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentGatewaysPage extends StatefulWidget {
  const PaymentGatewaysPage({super.key});

  @override
  State<PaymentGatewaysPage> createState() => _PaymentGatewaysPageState();
}

class _PaymentGatewaysPageState extends State<PaymentGatewaysPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _gateways =
      {}; // e.g., {'Stripe': true, 'PayPal': false}

  @override
  void initState() {
    super.initState();
    _loadGateways();
  }

  Future<void> _loadGateways() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (doc.exists) {
        final gateways = doc.data()?['paymentGateways'] ?? {};
        setState(() {
          _gateways = Map<String, dynamic>.from(
            gateways.map((key, value) => MapEntry(key, value == 'Connected')),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading gateways: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGateway(String name, bool isConnected) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _gateways[name] = isConnected;
    });

    try {
      await _firestore.collection('admins').doc(user.uid).set({
        'paymentGateways': {
          name: isConnected ? 'Connected' : 'Not Connected',
        }
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('$name ${isConnected ? 'Connected' : 'Disconnected'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Payment Gateways',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _gateways.entries.map((entry) {
                final name = entry.key;
                final isConnected = entry.value as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildGatewayTile(
                    name: name,
                    isConnected: isConnected,
                    onToggle: (value) => _updateGateway(name, value),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildGatewayTile({
    required String name,
    required bool isConnected,
    required ValueChanged<bool> onToggle,
  }) {
    // Pastel colors per gateway
    Color bgColor;
    Color iconColor;
    switch (name.toLowerCase()) {
      case 'stripe':
        bgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade700;
        break;
      case 'paypal':
        bgColor = Colors.orange.shade50;
        iconColor = Colors.orange.shade700;
        break;
      case 'razorpay':
        bgColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        break;
      default:
        bgColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade700;
    }

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(Icons.payment, color: iconColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          isConnected ? 'Connected' : 'Not Connected',
          style: TextStyle(color: isConnected ? Colors.green : Colors.red),
        ),
        trailing: Switch(
          value: isConnected,
          activeColor: iconColor,
          onChanged: onToggle,
        ),
      ),
    );
  }
}
