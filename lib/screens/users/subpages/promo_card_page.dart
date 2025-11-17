import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodiebox/models/voucher_model.dart';
import 'package:foodiebox/repositories/voucher_repository.dart';
import 'package:foodiebox/util/styles.dart'; 
import 'dart:async'; // Required for Future

// Helper class to map voucher data for eligibility checks (copied from repository file)
class VoucherEligibility {
  final VoucherModel voucher;
  final String eligibilityMessage;
  final bool isEligible;

  VoucherEligibility({
    required this.voucher,
    required this.eligibilityMessage,
    required this.isEligible,
  });
}

class PromoCardPage extends StatefulWidget {
  const PromoCardPage({super.key});

  @override
  State<PromoCardPage> createState() => _PromoCardPageState();
}

class _PromoCardPageState extends State<PromoCardPage> {
  final VoucherRepository _voucherRepo = VoucherRepository();
  // FIX: Changed type to Future<List<VoucherEligibility>>
  Future<List<VoucherEligibility>>? _eligibilityFuture; 
  String selectedCategory = 'All'; // Filter state

  @override
  void initState() {
    super.initState();
    // FIX: Assign the result of the asynchronous data loading function to the Future variable
    _eligibilityFuture = _loadVouchersAndCheckEligibility();
  }
  
  // NEW FUNCTION: Handles the asynchronous data fetching and eligibility checks
  Future<List<VoucherEligibility>> _loadVouchersAndCheckEligibility() async {
    final vouchers = await _voucherRepo.fetchAllActiveVouchers();
      
    // NOTE: Hardcoded mock values (subtotal, cart types) for generic page view.
    const List<String> mockCartVendorTypes = ['Grocery']; 
    final user = FirebaseAuth.instance.currentUser;
    
    // Safety check for user, although FutureBuilder handles null user data state
    if (user == null) return [];

    List<VoucherEligibility> processedList = [];
    for (var voucher in vouchers) {
      final message = await _voucherRepo.getEligibilityStatus(
        voucher: voucher,
        subtotal: 50.0, // Mock subtotal for filtering
        currentOrderType: 'delivery', // Mock order type
        cartVendorTypes: mockCartVendorTypes,
      );
      processedList.add(VoucherEligibility(
        voucher: voucher,
        eligibilityMessage: message,
        isEligible: message == "Eligible",
      ));
    }
    
    // Sort by eligibility first
    processedList.sort((a, b) {
        if (a.isEligible && !b.isEligible) return -1;
        if (!a.isEligible && b.isEligible) return 1;
        return b.voucher.minSpend.compareTo(a.voucher.minSpend);
    });
    
    return processedList;
  }
  
  String getDaysLeft(DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return 'Expired';
    if (daysLeft == 0) return 'Expires Today';
    return '$daysLeft days left';
  }

  // --- Filter Logic (Updated to use your defined categories) ---
  List<VoucherEligibility> _getFilteredVouchers(List<VoucherEligibility> allVouchers) {
    if (selectedCategory == 'All') {
      return allVouchers;
    }
    
    return allVouchers.where((item) {
      final type = item.voucher.applicableVendorType;
      
      // Filter based on selected UI category
      if (selectedCategory == 'Grocery' && type.toLowerCase() == 'grocery') return true;
      if (selectedCategory == 'BlindBox' && type.toLowerCase() == 'blindbox') return true;
      
      // Removed 'Food' filter based on user request.
      return false;
    }).toList();
  }
  // --- END Filter Logic ---

  // --- MODIFIED: Filter Button Widget (Yellow/Amber Style) ---
  Widget buildFilterButton(String label) {
    final isSelected = selectedCategory == label;
    return OutlinedButton(
      onPressed: () => setState(() => selectedCategory = label),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? kYellowMedium : Colors.white,
        side: BorderSide(color: isSelected ? kYellowMedium : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? kTextColor : Colors.black87)),
    );
  }
  // --- END MODIFIED ---

  Widget buildVoucherCard(VoucherEligibility item) {
    final voucher = item.voucher;
    final isEligible = item.isEligible;
    final String minSpendLabel = voucher.minSpend > 0 
        ? 'Min. spend RM${voucher.minSpend.toStringAsFixed(2)}' 
        : 'No min. spend';

    // Set styling based on eligibility
    final Color cardColor = isEligible ? Colors.green.shade50 : Colors.grey.shade50;
    final Color statusColor = isEligible ? Colors.green.shade700 : Colors.red.shade700;
    
    return Opacity(
      opacity: isEligible ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isEligible ? statusColor.withOpacity(0.5) : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(Icons.local_offer, color: statusColor), // Generic offer icon
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    voucher.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.info_outline, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 10),
            
            // Code and Use Button Row
            Row(
              children: [
                TextButton(
                  onPressed: isEligible ? () {
                    Clipboard.setData(ClipboardData(text: voucher.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied code: ${voucher.code}')),
                    );
                  } : null,
                  child: Text('Code: ${voucher.code}',
                      style: TextStyle(fontWeight: FontWeight.w600, color: statusColor)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: isEligible ? () {
                    // Action: Use the voucher (e.g., navigate to checkout and apply code)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Voucher ${voucher.code} applied!')),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEligible ?kYellowMedium : Colors.grey.shade300,
                    foregroundColor: isEligible ? kTextColor : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  // --- MODIFIED: Use now button color ---
                  child: Text(item.eligibilityMessage == 'Expired' ? 'Expired' : 'Use now',
                      style: TextStyle(color: isEligible ? kTextColor : Colors.grey.shade600)),
                  // --- END MODIFIED ---
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Eligibility Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minSpendLabel',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (!isEligible)
                   Text(
                      item.eligibilityMessage, 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                   )
                else 
                   Text(
                      getDaysLeft(voucher.endDate), 
                      style: TextStyle(fontSize: 12, color: statusColor),
                   ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method (FutureBuilder) ---
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view vouchers.")),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Vouchers & Offer', style: TextStyle(color: kTextColor)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<VoucherEligibility>>(
        future: _eligibilityFuture, // Use the Future variable
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryActionColor));
          }
          if (snapshot.hasError) {
             print("Error loading voucher data: ${snapshot.error}");
             return Center(child: Text('Error loading vouchers: ${snapshot.error}'));
          }
          
          final allVouchers = snapshot.data ?? [];
          final filteredVouchers = _getFilteredVouchers(allVouchers);

          // Top Summary Row - Calculate dynamic available vouchers count
          final int availableCount = allVouchers.where((v) => v.isEligible).length;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top Summary Row (LIVE DATA)
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
                        children: [
                          Text('${availableCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const Text('Vouchers Available', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Action: Add Voucher
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Add a Voucher functionality is TBD')),
                        );
                      },
                      // --- MODIFIED: Add Voucher Button Styling (Yellow/Amber) ---
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:kYellowMedium.withOpacity(0.8), // Stronger yellow fill
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color:kYellowMedium),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add, size: 18, color: kTextColor),
                            SizedBox(width: 6),
                            Text('Add a Voucher', style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // --- END MODIFIED ---
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Buttons 
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildFilterButton('All'),
                    // Removed 'Food' filter
                    buildFilterButton('Grocery'),
                    buildFilterButton('BlindBox'),
                  ],
                ),
                const SizedBox(height: 20),

                // Voucher Cards
                Expanded(
                  child: filteredVouchers.isEmpty
                      ? const Center(child: Text('No vouchers found matching filter.'))
                      : ListView.builder(
                          itemCount: filteredVouchers.length,
                          itemBuilder: (context, index) {
                            return buildVoucherCard(filteredVouchers[index]);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}