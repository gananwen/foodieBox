import 'package:flutter/material.dart';
import '../../util/styles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, String>> notifications = [
    {
      'category': 'Vendor',
      'title': 'New Vendor Registered',
      'subtitle': 'Vendor "Sweet Treats" joined the platform.',
      'time': '2m ago',
    },
    {
      'category': 'Order',
      'title': 'Order #1024 Completed',
      'subtitle': 'Customer has confirmed delivery.',
      'time': '15m ago',
    },
    {
      'category': 'System',
      'title': 'Server Maintenance Scheduled',
      'subtitle': 'Scheduled for 12:00 AM - 3:00 AM.',
      'time': '30m ago',
    },
    {
      'category': 'Complaint',
      'title': 'Complaint Received',
      'subtitle': 'Issue reported for Order #1009.',
      'time': '1h ago',
    },
  ];

  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 'All'
        ? notifications
        : notifications
            .where((n) => n['category'] == selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        title: const Text(
          "Notifications",
          style: TextStyle(
              color: kTextColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: kTextColor),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                notifications.clear();
              });
            },
            child: const Text(
              "Mark all as read",
              style: TextStyle(color: kPrimaryActionColor),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // --- Category Filter Chips ---
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Order'),
                _buildFilterChip('Vendor'),
                _buildFilterChip('System'),
                _buildFilterChip('Complaint'),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text("No new notifications.",
                        style: TextStyle(color: Colors.black54)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: kCardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(2, 3),
                            )
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.notifications,
                              color: kPrimaryActionColor),
                          title: Text(item['title']!,
                              style: kLabelTextStyle.copyWith(fontSize: 16)),
                          subtitle: Text(item['subtitle']!,
                              style: const TextStyle(color: Colors.black54)),
                          trailing: Text(item['time']!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : kTextColor,
        ),
        selected: isSelected,
        selectedColor: kPrimaryActionColor,
        backgroundColor: Colors.grey[200],
        onSelected: (_) {
          setState(() {
            selectedCategory = label;
          });
        },
      ),
    );
  }
}
