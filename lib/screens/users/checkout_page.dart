import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodiebox/screens/users/order_confirmation_page.dart';
import 'package:foodiebox/screens/users/order_failure_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import '../users/subpages/delivery_address_page.dart';
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
  String selectedDelivery = 'Standard';
  bool agreedToTerms = true;
  String selectedPayment = 'Credit/Debit Card';

  // --- MODIFIED: Address State ---
  // We will store the selected address details here
  // They are nullable because no address is selected initially
  String? _selectedAddressString;
  LatLng? _selectedAddressLatLng;
  String? _selectedContactName;
  String? _selectedContactPhone;
  String? _selectedAddressLabel;

  // We need the current user to fetch addresses
  User? _user;
  // --- END MODIFICATION ---

  late double subtotal;
  double discount = 0.0;
  double deliveryFee = 5.00;
  double deliveryDiscount = 3.00;
  String promoCode = '';
  String promoLabel = '';
  String promoError = '';

  final List<Map<String, dynamic>> availablePromos = [
    // ... your promo list remains unchanged ...
        {
      'title': '14% Additional Groceries Discount',
      'code': 'VLZKOW7',
      'minSpend': 45.00,
      'discountAmount': 10.00,
    },
    {
      'title': '30% OFF for your first pick up order',
      'code': 'NEWPICKUP',
      'minSpend': 25.00,
      'discountAmount': 7.50,
    },
    {
      'title': 'Enjoy RM10 off with RM 25 min. food delivery order',
      'code': 'SYOK10',
      'minSpend': 25.00,
      'discountAmount': 10.00,
    },
  ];

  @override
  void initState() {
    super.initState();
    subtotal = widget.subtotal;
    // --- NEW: Get user and load their default address ---
    _user = FirebaseAuth.instance.currentUser;
    _loadDefaultAddress();
    // --- END NEW ---
  }

  // --- NEW METHOD: Load the user's most recent address ---
  Future<void> _loadDefaultAddress() async {
    if (_user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('addresses')
          .orderBy('timestamp', descending: true) // Get the latest one
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final defaultAddress = snapshot.docs.first.data();
        // Use our new helper to set the state
        _updateSelectedAddress(defaultAddress);
      }
    } catch (e) {
      // Handle error, e.g., show a snackbar
      print("Error loading default address: $e");
    }
  }

  // --- NEW HELPER METHOD: Update state with selected address ---
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

  // --- NEW METHOD: Navigate to address selection page ---
  Future<void> _selectAddress() async {
    // Navigate to the DeliveryAddressPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryAddressPage()),
    );

    // This page will pop back with the selected address data
    if (result != null && result is Map<String, dynamic>) {
      // Update the checkout page's state with the selected address
      _updateSelectedAddress(result);
    }
  }

  // --- (buildOrderSummary, _loadLastPromo, _selectPaymentMethod, _showPromoSelector, buildDeliveryOption methods remain unchanged) ---
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
          Text('Total discount: -RM${discount.toStringAsFixed(2)}'),
          Text('Delivery fee: RM${deliveryFee.toStringAsFixed(2)}'),
          Text(
            'Delivery fee discount: -RM${deliveryDiscount.toStringAsFixed(2)}',
          ),
          if (promoCode.isNotEmpty)
            Text(
              discount > 0
                  ? "Promo Applied: $promoLabel"
                  : "Promo '$promoCode' cannot be used (min RM${_getPromoMinSpend(promoCode).toStringAsFixed(2)})",
              style: TextStyle(color: discount > 0 ? Colors.green : Colors.red),
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

  double _getPromoMinSpend(String code) {
    final promo = availablePromos.firstWhere(
      (p) => p['code'] == code,
      orElse: () => {},
    );
    return promo['minSpend'] ?? 0.0;
  }

  // --- _loadLastPromo ---
  Future<void> _loadLastPromo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null && data['lastPromo'] != null) {
      final promo = data['lastPromo'];
      final code = promo['code'];
      final label = promo['label'];
      final savedDiscount = promo['discount'];

      final promoDetails = availablePromos.firstWhere(
        (p) => p['code'] == code,
        orElse: () => {},
      );
      final meetsMinSpend = subtotal >= (promoDetails['minSpend'] ?? 0.0);

      setState(() {
        promoCode = code;
        promoLabel = label;
        discount = meetsMinSpend ? savedDiscount : 0.0;
        promoError = meetsMinSpend
            ? ''
            : 'Promo requires RM${promoDetails['minSpend']} minimum spend';
      });
    }
  }

  // --- _selectPaymentMethod ---
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

  // --- _showPromoSelector ---
  void _showPromoSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Promo Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: availablePromos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final promo = availablePromos[index];
                    final meetsMinSpend = subtotal >= promo['minSpend'];
                    final isSelected = promoCode == promo['code'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          promoCode = promo['code'];
                          promoLabel = promo['title'];
                          if (meetsMinSpend) {
                            discount = promo['discountAmount'];
                            promoError = '';
                          } else {
                            discount = 0.0;
                            promoError =
                                'Promo requires RM${promo['minSpend']} minimum spend';
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 1.0,
                          end: isSelected ? 1.03 : 1.0,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [
                                          Colors.amber.shade100,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isSelected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? Colors.amber.withOpacity(0.4)
                                        : Colors.grey.shade100,
                                    blurRadius: isSelected ? 12 : 6,
                                    spreadRadius: isSelected ? 2 : 1,
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
                                          promo['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Tooltip(
                                        message:
                                            'Min spend RM${promo['minSpend']}\nCode: ${promo['code']}',
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
                                          Text(
                                            'Code: ${promo['code']}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          if (meetsMinSpend)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 6),
                                              child: Icon(
                                                Icons.local_offer,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        meetsMinSpend
                                            ? 'Eligible'
                                            : 'Min RM${promo['minSpend']}',
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

  // --- buildDeliveryOption ---
  Widget buildDeliveryOption(String label, String time, double price) {
    final isSelected = selectedDelivery == label;
    return GestureDetector(
      onTap: () => setState(() => selectedDelivery = label),
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

  // --- NEW WIDGET: Replaces the old hardcoded address section ---
  Widget _buildAddressSection() {
    // Case 1: No address has been selected or loaded yet
    if (_selectedAddressString == null) {
      return InkWell(
        onTap: _selectAddress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kYellowLight, // Use your style
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimaryActionColor, width: 1.5), // Use your style
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Delivery Address',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor), // Use your style
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: kTextColor), // Use your style
            ],
          ),
        ),
      );
    }

    // Case 2: An address is selected
    IconData iconData = Icons.location_on;
    if (_selectedAddressLabel == 'Home') {
      iconData = Icons.home;
    } else if (_selectedAddressLabel == 'Office') {
      iconData = Icons.work;
    }

    return InkWell(
      onTap: _selectAddress, // Tap to change address
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade200, blurRadius: 4)
          ],
          border: Border.all(color: Colors.grey.shade300)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: kPrimaryActionColor, size: 28), // Use your style
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedAddressLabel - $_selectedContactName',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            const Icon(Icons.edit_location_alt_outlined, size: 20, color: Colors.grey),
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
            // --- MODIFIED: Delivery Address ---
            const Text('Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Use our new dynamic widget
            _buildAddressSection(),
            const SizedBox(height: 20),
            // --- END MODIFICATION ---

            // --- Delivery Option ---
            const Text('Delivery Option',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildDeliveryOption('Express', '20 min', 4.99),
            buildDeliveryOption('Standard', '40 min', 2.99),
            buildDeliveryOption('Saver', '60 min', 0.99),
            const SizedBox(height: 20),

            // --- Payment Method ---
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
                   border: Border.all(color: Colors.grey.shade300)
                ),
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

            // --- Promo Code ---
            const Text('Promo Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 1.0,
                end: promoCode.isEmpty ? 1.05 : 1.0,
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: ElevatedButton.icon(
                    onPressed: _showPromoSelector,
                    icon: const Icon(Icons.local_offer, size: 18),
                    label: Text(
                      promoCode.isEmpty ? 'Select Promo' : 'Promo: $promoCode',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      backgroundColor: promoCode.isEmpty
                          ? Colors.white
                          : Colors.amber.shade100,
                      foregroundColor: Colors.black,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: promoCode.isEmpty
                              ? Colors.grey.shade300
                              : Colors.amber,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (promoCode.isNotEmpty && promoError.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Suggested from last order',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            if (promoCode.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Promo'),
                      content: const Text(
                        'Are you sure you want to remove the applied promo code?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              promoCode = '';
                              promoLabel = '';
                              discount = 0.0;
                              promoError = '';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                label: const Text(
                  'Clear Promo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (promoError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  promoError,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),

            // --- Order Summary ---
            const Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Use the reusable buildOrderSummary method
            buildOrderSummary(),
            const SizedBox(height: 20),

            // --- Terms and Conditions ---
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

            // --- Place Order Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: agreedToTerms ? _placeOrder : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryActionColor, // Use your style
                  foregroundColor: kTextColor, // Use your style
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    // --- MODIFIED: Check for address first ---
    if (_selectedAddressString == null || _selectedAddressLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address.')),
      );
      return;
    }
    // --- END MODIFICATION ---

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      return;
    }

    // ... (Promo validation logic remains unchanged) ...
    if (promoCode.isNotEmpty && discount == 0.0) {
      final minSpend = _getPromoMinSpend(promoCode).toStringAsFixed(2);

      final shouldClear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Promo Not Applicable'),
          content: Text(
            'The promo code "$promoCode" requires a minimum spend of RM$minSpend. Please clear the promo to continue with your order.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false), // Cancel order attempt
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Signal to clear promo
              },
              child: const Text(
                'Clear Promo',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (shouldClear == true) {
        setState(() {
          promoCode = '';
          promoLabel = '';
          promoError = '';
        });
        return _placeOrder();
      }
      return;
    }

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

    // --- MODIFIED: Use dynamic address data in the order ---
    final orderData = {
      'userId': user.uid,
      'address': _selectedAddressString, // Use state variable
      'lat': _selectedAddressLatLng!.latitude, // Use state variable
      'lng': _selectedAddressLatLng!.longitude, // Use state variable
      'contactName': _selectedContactName, // Add contact name
      'contactPhone': _selectedContactPhone, // Add contact phone
      'deliveryOption': selectedDelivery,
      'paymentMethod': selectedPayment,
      'subtotal': subtotal,
      'discount': discount,
      'deliveryFee': deliveryFee,
      'deliveryDiscount': deliveryDiscount,
      'total': getTotal(),
      'promoCode': promoCode,
      'promoLabel': promoLabel,
      'status': 'received',
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
    };
    // --- END MODIFICATION ---

    try {
      final docRef =
          await FirebaseFirestore.instance.collection('orders').add(orderData);
      final orderId = docRef.id;

      if (promoCode.isNotEmpty) {
        // ... (Promo usage update logic remains unchanged) ...
        final promoRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('promoUsage')
            .doc(promoCode);

        await promoRef.set({
          'label': promoLabel,
          'lastUsed': FieldValue.serverTimestamp(),
          'count': FieldValue.increment(1),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastPromo': {
            'code': promoCode,
            'label': promoLabel,
            'discount': discount,
          },
        }, SetOptions(merge: true));
      }

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
              address: _selectedAddressString!, // Pass the selected address
              location: _selectedAddressLatLng!, // Pass the selected lat/lng
              total: getTotal(),
              promoLabel: promoLabel,
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
    }
  }
}