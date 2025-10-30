import 'package:flutter/material.dart';

class PaymentGatewaysPage extends StatelessWidget {
  const PaymentGatewaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Gateways')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.credit_card),
            title: Text('Stripe'),
            subtitle: Text('Connected'),
            trailing: Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            leading: Icon(Icons.account_balance),
            title: Text('PayPal'),
            subtitle: Text('Not Connected'),
            trailing: Icon(Icons.warning, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
