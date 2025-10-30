import 'package:flutter/material.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool pushEnabled = true;
  bool emailEnabled = false;
  bool smsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildToggle('Push Notifications', pushEnabled,
                (v) => setState(() => pushEnabled = v)),
            _buildToggle('Email Alerts', emailEnabled,
                (v) => setState(() => emailEnabled = v)),
            _buildToggle('SMS Alerts', smsEnabled,
                (v) => setState(() => smsEnabled = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
