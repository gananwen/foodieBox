import 'package:flutter/material.dart';

class FraudDetectionModal extends StatelessWidget {
  const FraudDetectionModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Fraud Detection Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Auto Detection'),
            value: true,
            onChanged: (_) {},
          ),
          SwitchListTile(
            title: const Text('Alert Admin via Email'),
            value: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
