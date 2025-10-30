import 'package:flutter/material.dart';

class HelpModal extends StatelessWidget {
  const HelpModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help & Support',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text(
              'If you need assistance, please contact our support team.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('support@foodiebox.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('+1 (800) 123-4567'),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
