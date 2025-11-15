import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// --- NEW: Import the new VoucherModel ---
import 'package:foodiebox/models/voucher_model.dart'; 
import 'package:foodiebox/screens/users/order_confirmation_page.dart';
import 'package:foodiebox/screens/users/order_failure_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/subpages/delivery_address_page.dart';
import 'package:foodiebox/util/styles.dart';

class CheckoutPage extends StatefulWidget {
  final double subtotal;
  final List<CartItem> items;

  const CheckoutPage({
    super.key,
    required this.subtotal,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final List<Map<String, dynamic>> _deliveryOptions = [
    {'label': 'Express', 'time': '20 min', 'price': 4.99},
    {'label': 'Standard', 'time': '40 min', 'price': 2.99},
    {'label': 'Saver', 'time': '60 min', 'price': 0.99},
  ];
  String selectedDelivery = 'Standard';

  bool agreedToTerms = true;
  String selectedPayment = 'Credit/Debit Card';

  String? _selectedAddressString;
  LatLng? _selectedAddressLatLng;
  String? _selectedContactName;
  String? _selectedContactPhone;
  String? _selectedAddressLabel;

  User? _user;

  late double subtotal;
  double discount = 0.0;
  late double deliveryFee;
  double deliveryDiscount = 0.0; 
  bool _isLoading = false;

  // --- Voucher State ---
  String voucherCode = '';
  String voucherLabel = '';
  String voucherError = '';
  VoucherModel? selectedVoucher; 
  List<VoucherModel> availableVouchers = []; 
  bool _isLoadingVouchers = true;
  // --- END Voucher State ---

  @override
  void initState() {
    super.initState();
    subtotal = widget.subtotal;
    _user = FirebaseAuth.instance.currentUser;

    deliveryFee = _deliveryOptions
        .firstWhere((opt) => opt['label'] == selectedDelivery)['price'];

    _loadDefaultAddress();
    _fetchVouchers(); 
  }

  // --- Fetch vouchers from Firebase ---
  Future<void> _fetchVouchers() async {
    if (_user == null) {
      setState(() => _isLoadingVouchers = false);
      return;
    }
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('type', whereIn: ['delivery', 'all'])
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      final vouchers = snapshot.docs
          .map((doc) => VoucherModel.fromMap(doc.data(), doc.id))
          .where((voucher) => voucher.startDate.isBefore(now) && 
                           voucher.claimedRedemptions < voucher.totalRedemptions)
          .toList();

      if (mounted) {
        setState(() {
          availableVouchers = vouchers;
          _isLoadingVouchers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVouchers = false);
      }
      print("Error fetching vouchers: $e");
    }
  }
  // --- END Fetch vouchers ---

  Future<void> _loadDefaultAddress() async {
    if (_user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('addresses')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final defaultAddress = snapshot.docs.first.data();
        _updateSelectedAddress(defaultAddress);
      }
    } catch (e) {
      print("Error loading default address: $e");
    }
  }

  void _updateSelectedAddress(Map<String, dynamic> addressData) {
    setState(() {
      _selectedAddressString = addressData['address'];
      _selectedContactName = addressData['contactName'];
      _selectedContactPhone = addressData['contactPhone'];
      _selectedAddressLabel = addressData['label'] ?? 'Address';
      if (addressData['lat'] != null && addressData['lng'] != null) {
        _selectedAddressLatLng =
            LatLng(addressData['lat'], addressData['lng']);
      }
    });
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryAddressPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _updateSelectedAddress(result);
    }
  }

  Widget buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subtotal: RM${subtotal.toStringAsFixed(2)}'),
          Text('Delivery fee: RM${deliveryFee.toStringAsFixed(2)}'),
          
          if (discount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Voucher (${selectedVoucher?.code ?? ''}): -RM${discount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
            ),
          
          if (deliveryDiscount > 0) 
             Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Delivery fee discount: -RM${deliveryDiscount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
            ),

          if (voucherError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                voucherError,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Divider(),
          Text(
            'Total: RM${getTotal().toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  double getTotal() {
    return subtotal - discount + deliveryFee - deliveryDiscount;
  }

  double _getVoucherMinSpend(String code) {
    try {
      final voucher = availableVouchers.firstWhere((v) => v.code == code);
      return voucher.minSpend;
    } catch (e) {
      return 0.0;
    }
  }

  void _selectPaymentMethod() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Credit/Debit Card'),
              onTap: () {
                setState(() => selectedPayment = 'Credit/Debit Card');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Cash on Delivery'),
              onTap: () {
                setState(() => selectedPayment = 'Cash on Delivery');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('E-Wallet'),
              onTap: () {
                setState(() => selectedPayment = 'E-Wallet');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // --- Show Voucher Selector Modal ---
  void _showVoucherSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (_isLoadingVouchers) {
          return const Center(child: CircularProgressIndicator());
        }
        if (availableVouchers.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No vouchers available right now."),
          ));
        }

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Voucher Code', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: availableVouchers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final voucher = availableVouchers[index];
                    final meetsMinSpend = subtotal >= voucher.minSpend;
                    final isSelected = voucherCode == voucher.code;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (meetsMinSpend) {
                            voucherCode = voucher.code;
                            voucherLabel = voucher.title;
                            selectedVoucher = voucher;
                            discount = voucher.calculateDiscount(subtotal);
                            voucherError = '';
                          } else {
                            voucherCode = voucher.code;
                            voucherLabel = voucher.title;
                            selectedVoucher = voucher;
                            discount = 0.0;
                            voucherError =
                                'Voucher requires RM${voucher.minSpend.toStringAsFixed(2)} minimum spend';
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    voucher.title, 
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'Expires: ${voucher.endDate.toLocal().toString().split(' ')[0]}\n'
                                           'Min. Spend: RM${voucher.minSpend.toStringAsFixed(2)}\n'
                                           'Type: ${voucher.type}',
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.label, color: Colors.green.shade700, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Code: ${voucher.code}', 
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  meetsMinSpend
                                      ? 'Eligible'
                                      : 'Min RM${voucher.minSpend.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: meetsMinSpend
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryOptionWidget(Map<String, dynamic> option) {
    final String label = option['label'];
    final String time = option['time'];
    final double price = option['price'];

    final isSelected = selectedDelivery == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDelivery = label;
          deliveryFee = price;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.black12,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label <$time', style: const TextStyle(fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'RM${price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_selectedAddressString == null) {
      return InkWell(
        onTap: _selectAddress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kYellowLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryActionColor, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Delivery Address',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: kTextColor),
            ],
          ),
        ),
      );
    }

    IconData iconData = Icons.location_on;
    if (_selectedAddressLabel == 'Home') {
      iconData = Icons.home;
    } else if (_selectedAddressLabel == 'Office') {
      iconData = Icons.work;
    }

    return InkWell(
      onTap: _selectAddress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 4)
            ],
            border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: kPrimaryActionColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedAddressLabel - $_selectedContactName',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedAddressString ?? 'No address',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedContactPhone ?? 'No phone',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_location_alt_outlined,
                size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildAddressSection(),
            const SizedBox(height: 20),

            const Text('Delivery Option',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ..._deliveryOptions.map((option) {
              return _buildDeliveryOptionWidget(option);
            }).toList(),

            const SizedBox(height: 20),

            const Text('Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _selectPaymentMethod,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade200, blurRadius: 4),
                    ],
                    border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedPayment, style: const TextStyle(fontSize: 16)),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- UPDATED: Voucher Code Section ---
            const Text('Voucher Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showVoucherSelector, 
              icon: const Icon(Icons.local_offer, size: 18),
              label: Text(
                voucherCode.isEmpty ? 'Select Voucher' : 'Voucher: $voucherCode',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                backgroundColor: voucherCode.isEmpty
                    ? Colors.white
                    : Colors.amber.shade100,
                foregroundColor: Colors.black,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: voucherCode.isEmpty
                        ? Colors.grey.shade300
                        : Colors.amber,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            
            if (voucherCode.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // Clear voucher
                  setState(() {
                    voucherCode = '';
                    voucherLabel = '';
                    selectedVoucher = null;
                    discount = 0.0;
                    voucherError = '';
                  });
                },
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: const Text(
                  'Clear Voucher',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (voucherError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  voucherError,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            // --- END UPDATED SECTION ---

            const Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildOrderSummary(),
            const SizedBox(height: 20),

            Row(
              children: [
                Checkbox(
                  value: agreedToTerms,
                  onChanged: (value) =>
                      setState(() => agreedToTerms = value ?? true),
                ),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'By placing an order you agree to our ',
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: agreedToTerms && !_isLoading ? _placeOrder : null,
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
                        'Place Order',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    // ... existing checks ...
    if (_selectedAddressString == null || _selectedAddressLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      return;
    }

    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- UPDATED: Voucher Validation ---
    if (voucherCode.isNotEmpty && discount == 0.0) {
      // This means a voucher is selected but min spend not met
      final minSpend = _getVoucherMinSpend(voucherCode).toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher requires RM$minSpend minimum spend.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }
    // --- END UPDATED ---

    final itemsData = widget.items.map((item) {
      return {
        'name': item.product.title,
        'price': item.product.discountedPrice,
        'quantity': item.quantity,
        'productId': item.product.id,
        'vendorId': item.vendorId,
        'imageUrl': item.product.imageUrl,
      };
    }).toList();

    // --- NEW: Get all unique vendor IDs from the cart ---
    final allVendorIds = widget.items.map((item) => item.vendorId).toSet().toList();
    // --- END NEW ---

    String vendorName = 'Unknown Store';
    String vendorType = 'Grocery';
    // Get vendor details (we use the first vendor for the main summary fields)
    try {
      final firstVendorId = widget.items.first.vendorId;
      final vendorDoc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(firstVendorId)
          .get();

      if (vendorDoc.exists) {
        vendorName = vendorDoc.data()?['storeName'] ?? 'Unknown Store';
        vendorType = vendorDoc.data()?['vendorType'] ?? 'Grocery';
      }
    } catch (e) {
      print("Error fetching vendor data: $e");
    }

    // --- FINAL Order data preparation ---
    final orderData = {
      'userId': user.uid,
      'orderType': 'Delivery', 
      'address': _selectedAddressString,
      'lat': _selectedAddressLatLng!.latitude,
      'lng': _selectedAddressLatLng!.longitude,
      'contactName': _selectedContactName,
      'contactPhone': _selectedContactPhone,
      'deliveryOption': selectedDelivery,
      'paymentMethod': selectedPayment,
      'subtotal': subtotal,
      'discount': discount, 
      'deliveryFee': deliveryFee,
      'deliveryDiscount': deliveryDiscount,
      'total': getTotal(),
      'promoCode': null, 
      'promoLabel': null, 
      'voucherCode': voucherCode, 
      'voucherLabel': voucherLabel, 
      'vendorIds': allVendorIds, // <-- ADDED
      'status': 'received',
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      'vendorName': vendorName,
      'vendorType': vendorType,
    };
    // --- END FINAL Order data ---

    try {
      final docRef =
          await FirebaseFirestore.instance.collection('orders').add(orderData);
      final orderId = docRef.id;

      // --- Increment VOUCHER redemption count ---
      if (selectedVoucher != null) {
        await FirebaseFirestore.instance
            .collection('vouchers') 
            .doc(selectedVoucher!.id)
            .update({
          'claimedRedemptions': FieldValue.increment(1),
        });
      }
      // --- END Increment ---
      
      if (mounted) {
        context.read<CartProvider>().clearCart();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(
              address: _selectedAddressString!,
              location: _selectedAddressLatLng!,
              total: getTotal(),
              promoLabel: voucherLabel, 
              orderId: orderId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));

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
}