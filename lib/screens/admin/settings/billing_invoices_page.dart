import 'package:flutter/material.dart';

class BillingInvoicesPage extends StatelessWidget {
  const BillingInvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = [
      {'id': '#INV-2025-001', 'amount': '\$120.00', 'status': 'Paid'},
      {'id': '#INV-2025-002', 'amount': '\$89.00', 'status': 'Pending'},
    ];

    return Scaffold(
      appBar:
          AppBar(title: const Text('Billing & Invoices'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invoices.length,
        itemBuilder: (context, index) {
          final invoice = invoices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(invoice['id']!),
              subtitle: Text(invoice['amount']!),
              trailing: Text(
                invoice['status']!,
                style: TextStyle(
                  color: invoice['status'] == 'Paid'
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
