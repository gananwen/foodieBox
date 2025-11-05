import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromoCardPage extends StatefulWidget {
  const PromoCardPage({super.key});

  @override
  State<PromoCardPage> createState() => _PromoCardPageState();
}

class _PromoCardPageState extends State<PromoCardPage> {
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> vouchers = [
    {
      'title': '15% Additional Groceries Discount',
      'code': 'VLZKOW7',
      'type': 'Grocery',
      'minSpend': 'RM45.00',
      'expiry': '21 Dec 2025',
      'icon': Icons.shopping_basket,
      'iconColor': Colors.orange,
      'tag': 'NEW',
    },
    {
      'title': '30% OFF for your first pick up order',
      'code': 'NEWPICKUP',
      'type': 'Food',
      'minSpend': 'RM25.00',
      'expiry': '26 Feb 2026',
      'icon': Icons.fastfood,
      'iconColor': Colors.redAccent,
      'tag': 'NEW',
    },
    {
      'title': 'Enjoy RM10 off with RM 25 min. food delivery order',
      'code': 'SYOK10',
      'type': 'Food',
      'minSpend': 'RM25.00',
      'expiry': '26 Oct 2024',
      'icon': Icons.lunch_dining,
      'iconColor': Colors.deepOrange,
      'tag': 'ELITE',
    },
    {
      'title': 'Enjoy RM10 off with RM 25 min. pick up order',
      'code': 'SYOK10',
      'type': 'Food',
      'minSpend': 'RM25.00',
      'expiry': '26 Oct 2024',
      'icon': Icons.ramen_dining,
      'iconColor': Colors.pinkAccent,
      'tag': 'GLUT',
    },
  ];

  String getDaysLeft(String expiryDate) {
    final format = RegExp(r'(\d{1,2}) (\w+) (\d{4})');
    final match = format.firstMatch(expiryDate);
    if (match == null) return '';
    final day = int.parse(match.group(1)!);
    final month = match.group(2)!;
    final year = int.parse(match.group(3)!);

    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };

    final expiry = DateTime(year, months[month.substring(0, 3)]!, day);
    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    return daysLeft > 0 ? '$daysLeft days left' : 'Expired';
  }

  Widget buildFilterButton(String label) {
    final isSelected = selectedCategory == label;
    return OutlinedButton(
      onPressed: () => setState(() => selectedCategory = label),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.amber : Colors.white,
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
    );
  }

  Widget buildVoucherCard(Map<String, dynamic> voucher) {
    final daysLeft = getDaysLeft(voucher['expiry']);
    final isExpired = daysLeft == 'Expired';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: voucher['iconColor'].withOpacity(0.2),
                child: Icon(voucher['icon'], color: voucher['iconColor']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  voucher['title'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (voucher['tag'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    voucher['tag'],
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: voucher['code']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied ${voucher['code']}')),
                  );
                },
                child: Text('Code: ${voucher['code']}',
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isExpired ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Use now'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Min. spend ${voucher['minSpend']} • $daysLeft',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVouchers = selectedCategory == 'All'
        ? vouchers
        : vouchers.where((v) => v['type'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vouchers & Offer', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      Text('RM 0.00', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Saved this month', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add a Voucher tapped')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 6),
                        Text('Add a Voucher'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildFilterButton('All'),
                buildFilterButton('Restaurants'),
                buildFilterButton('Shops'),
              ],
            ),
            const SizedBox(height: 20),

            // Voucher Cards
            Expanded(
              child: ListView.builder(
                itemCount: filteredVouchers.length,
                itemBuilder: (context, index) {
                  return buildVoucherCard(filteredVouchers[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
