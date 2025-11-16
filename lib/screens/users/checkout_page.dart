import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodiebox/models/voucher_model.dart';
import 'package:foodiebox/screens/users/order_confirmation_page.dart';
import 'package:foodiebox/screens/users/order_failure_page.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:foodiebox/screens/users/subpages/delivery_address_page.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:foodiebox/repositories/voucher_repository.dart';
import 'package:foodiebox/models/promotion.dart';

class CheckoutPage extends StatefulWidget {
  final double subtotal;
  final List<CartItem> items;

  const CheckoutPage({
    super.key,
    required this.subtotal,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPage();
}

class _CheckoutPage extends State<CheckoutPage> {
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
  late double deliveryFee;
  bool _isLoading = false;

  final VoucherRepository _voucherRepo = VoucherRepository();

  PromotionModel? automaticPromo;
  double promoDiscount = 0.0;
  bool _isLoadingPromo = true;

  String voucherCode = '';
  String voucherLabel = '';
  String voucherError = '';
  VoucherModel? selectedVoucher;
  List<VoucherEligibility> voucherList = [];
  bool _isLoadingVouchers = true;
  double voucherDiscount = 0.0;

  @override
  void initState() {
    super.initState();
    subtotal = widget.subtotal;
    _user = FirebaseAuth.instance.currentUser;
    deliveryFee = _deliveryOptions
        .firstWhere((opt) => opt['label'] == selectedDelivery)['price'];
    _loadDefaultAddress();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchAutomaticPromo();
    // Pass the subtotal *after* automatic promo to the voucher fetcher
    await _fetchVouchers(subtotal - promoDiscount);
  }

  Future<void> _fetchAutomaticPromo() async {
    // --- UPDATED: Check for BlindBox or Grocery ---
    // Note: 'Blind Box' (with space) comes from product.dart
    List<String> cartVendorTypes = widget.items
        .map((item) =>
            item.product.productType == 'Blind Box' ? 'BlindBox' : 'Grocery')
        .toSet()
        .toList();

    // Prioritize BlindBox promo if it exists in a mixed cart
    String productType =
        cartVendorTypes.contains('BlindBox') ? 'Blindbox' : 'Grocery';
    // --- END UPDATED ---

    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('productType', isEqualTo: productType)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      final promos = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.data(), doc.id))
          .where((promo) =>
              promo.startDate.isBefore(now) &&
              (promo.totalRedemptions == 0 ||
                  promo.claimedRedemptions < promo.totalRedemptions))
          .toList();

      if (mounted && promos.isNotEmpty) {
        setState(() {
          automaticPromo = promos.first;
          promoDiscount =
              subtotal * (automaticPromo!.discountPercentage / 100.0);
          _isLoadingPromo = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingPromo = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPromo = false);
      print("Error fetching automatic promo: $e");
    }
  }

  Future<void> _fetchVouchers(double currentSubtotal) async {
    if (_user == null) {
      setState(() => _isLoadingVouchers = false);
      return;
    }
    setState(() => _isLoadingVouchers = true);

    final vouchers = await _voucherRepo.fetchAllActiveVouchers();

    // --- NEW: Get all vendor types from cart ---
    // Note: 'Blind Box' (with space) comes from product.dart
    final cartVendorTypes = widget.items
        .map((item) =>
            item.product.productType == 'Blind Box' ? 'BlindBox' : 'Grocery')
        .toSet()
        .toList();
    // --- END NEW ---

    List<VoucherEligibility> processedList = [];
    for (var voucher in vouchers) {
      // --- UPDATED: Pass all cart vendor types ---
      final message = await _voucherRepo.getEligibilityStatus(
        voucher: voucher,
        subtotal: currentSubtotal,
        currentOrderType: 'delivery',
        cartVendorTypes: cartVendorTypes,
      );
      // --- END UPDATED ---
      processedList.add(VoucherEligibility(
        voucher: voucher,
        eligibilityMessage: message,
        isEligible: message == "Eligible",
      ));
    }

    // Sort the list: Eligible first, then Not Eligible
    processedList.sort((a, b) {
      if (a.isEligible && !b.isEligible) return -1;
      if (!a.isEligible && b.isEligible) return 1;
      // If both are same eligibility, sort by minSpend (higher spend req first)
      return b.voucher.minSpend.compareTo(a.voucher.minSpend);
    });

    if (mounted) {
      setState(() {
        voucherList = processedList;
        _isLoadingVouchers = false;
      });
    }
  }

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
        _updateSelectedAddress(snapshot.docs.first.data());
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
        _selectedAddressLatLng = LatLng(addressData['lat'], addressData['lng']);
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

  double getTotal() {
    final subtotalAfterPromo = subtotal - promoDiscount;
    final voucherDiscountOnSubtotal =
        selectedVoucher?.calculateDiscount(subtotalAfterPromo) ?? 0.0;

    final finalDeliveryFee =
        (selectedVoucher?.freeDelivery ?? false) ? 0.0 : deliveryFee;

    if (voucherDiscountOnSubtotal != voucherDiscount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          setState(() => voucherDiscount = voucherDiscountOnSubtotal);
      });
    }
    return subtotalAfterPromo - voucherDiscountOnSubtotal + finalDeliveryFee;
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

  // --- VOUCHER MODAL - STYLED TO MATCH IMAGE & SORTED ---
  void _showVoucherSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows modal to be taller
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.grey[100], // Background like image
      builder: (context) {
        if (_isLoadingVouchers) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (voucherList.isEmpty) {
          return const SizedBox(
              height: 200,
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No vouchers available right now."),
              )));
        }

        final subtotalAfterPromo = subtotal - promoDiscount;

        // Use ConstrainedBox to set max height
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important for ConstrainedBox
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Choose a Promo Code', // Title from image
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- List of Vouchers ---
                Expanded(
                  child: ListView.separated(
                    itemCount: voucherList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = voucherList[index];
                      final voucher = item.voucher;
                      final isSelected = voucherCode == voucher.code;
                      final isEligible = item.isEligible;
                      final eligibilityMessage = item.eligibilityMessage;

                      return GestureDetector(
                        onTap: () {
                          // Allow tapping ineligible to show reason
                          if (!isEligible) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(eligibilityMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          // Apply voucher if eligible
                          setState(() {
                            voucherCode = voucher.code;
                            voucherLabel = voucher.title;
                            selectedVoucher = voucher;
                            voucherDiscount =
                                voucher.calculateDiscount(subtotalAfterPromo);
                            voucherError = '';
                          });
                          Navigator.pop(context);
                        },
                        // --- UPDATED: Opacity for ineligible ---
                        child: Opacity(
                          opacity: isEligible ? 1.0 : 0.6,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? kPrimaryActionColor // Highlight if selected
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- Title and Info Icon ---
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        voucher.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.info_outline,
                                        color: Colors.grey[400]),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // --- Code and Eligibility ---
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.label,
                                            color: Colors.green[600], size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Code: ${voucher.code}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      eligibilityMessage, // Show "Eligible" or the reason
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isEligible
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // --- END UPDATED ---
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- END VOUCHER MODAL ---

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
    if (_selectedAddressLabel == 'Home')
      iconData = Icons.home;
    else if (_selectedAddressLabel == 'Office') iconData = Icons.work;

    return InkWell(
      onTap: _selectAddress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
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
            ..._deliveryOptions.map(_buildDeliveryOptionWidget).toList(),
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
            const Text('Voucher Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showVoucherSelector,
              icon: const Icon(Icons.local_offer, size: 18),
              label: Text(
                voucherCode.isEmpty
                    ? 'Select Voucher'
                    : 'Voucher: $voucherCode',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                backgroundColor:
                    voucherCode.isEmpty ? Colors.white : Colors.amber.shade100,
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
                  setState(() {
                    voucherCode = '';
                    voucherLabel = '';
                    selectedVoucher = null;
                    voucherDiscount = 0.0;
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
            const Text('Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 4)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: kLabelTextStyle),
                      Text('RM${subtotal.toStringAsFixed(2)}',
                          style: kLabelTextStyle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingPromo)
                    const Text('Checking for promotions...',
                        style: kHintTextStyle),
                  if (promoDiscount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(automaticPromo?.title ?? 'Promotion',
                            style:
                                kHintTextStyle.copyWith(color: Colors.green)),
                        Text('-RM${promoDiscount.toStringAsFixed(2)}',
                            style:
                                kHintTextStyle.copyWith(color: Colors.green)),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery fee', style: kHintTextStyle),
                      Text('RM${deliveryFee.toStringAsFixed(2)}',
                          style: (selectedVoucher?.freeDelivery ?? false)
                              ? kHintTextStyle.copyWith(
                                  decoration: TextDecoration.lineThrough)
                              : kHintTextStyle),
                    ],
                  ),
                  if (voucherDiscount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(voucherLabel,
                              style:
                                  kHintTextStyle.copyWith(color: Colors.green)),
                          Text('-RM${voucherDiscount.toStringAsFixed(2)}',
                              style:
                                  kHintTextStyle.copyWith(color: Colors.green)),
                        ],
                      ),
                    ),
                  if (selectedVoucher?.freeDelivery ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(voucherLabel,
                              style:
                                  kHintTextStyle.copyWith(color: Colors.green)),
                          Text('Free Delivery',
                              style:
                                  kHintTextStyle.copyWith(color: Colors.green)),
                        ],
                      ),
                    ),
                  if (voucherError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        voucherError,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: kLabelTextStyle),
                      Text(
                        'RM${getTotal().toStringAsFixed(2)}',
                        style: kLabelTextStyle.copyWith(
                            fontSize: 18, color: kPrimaryActionColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    if (_selectedAddressString == null || _selectedAddressLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address.')),
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

    // --- NEW: Get all vendor types from cart ---
    final cartVendorTypes = widget.items
        .map((item) =>
            item.product.productType == 'Blind Box' ? 'BlindBox' : 'Grocery')
        .toSet()
        .toList();
    // --- END NEW ---

    if (selectedVoucher != null) {
      final subtotalAfterPromo = subtotal - promoDiscount;
      // --- UPDATED: Pass all cart vendor types ---
      final eligibilityMessage = await _voucherRepo.getEligibilityStatus(
        voucher: selectedVoucher!,
        subtotal: subtotalAfterPromo,
        currentOrderType: 'delivery',
        cartVendorTypes: cartVendorTypes,
      );
      // --- END UPDATED ---
      if (eligibilityMessage != "Eligible") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('The selected voucher is no longer eligible.'),
              backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }
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

    final allVendorIds =
        widget.items.map((item) => item.vendorId).toSet().toList();

    String vendorName = 'Multiple Stores';
    String vendorType = 'Mixed';

    if (allVendorIds.length == 1) {
      try {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(allVendorIds.first)
            .get();
        if (vendorDoc.exists) {
          vendorName = vendorDoc.data()?['storeName'] ?? 'Unknown Store';
          vendorType = vendorDoc.data()?['vendorType'] ?? 'Grocery';
        }
      } catch (e) {
        print("Error fetching vendor data: $e");
      }
    }

    final finalTotal = getTotal();
    final finalDeliveryFee =
        (selectedVoucher?.freeDelivery ?? false) ? 0.0 : deliveryFee;

    // --- ( ✨ UPDATED ORDER DATA ✨ ) ---
    // Added promoLabel and voucherLabel to save to Firebase
    final orderData = {
      'userId': _user!.uid,
      'orderType': 'Delivery',
      'address': _selectedAddressString,
      'lat': _selectedAddressLatLng!.latitude,
      'lng': _selectedAddressLatLng!.longitude,
      'contactName': _selectedContactName,
      'contactPhone': _selectedContactPhone,
      'deliveryOption': selectedDelivery,
      'paymentMethod': selectedPayment,
      'subtotal': subtotal,
      'discount': promoDiscount + voucherDiscount,
      'deliveryFee': finalDeliveryFee,
      'total': finalTotal,
      'promoCode': null, // Deprecated, but keeping for schema
      'promoLabel': automaticPromo?.title, // <-- ( ✨ NEW ✨ )
      'voucherCode': selectedVoucher?.code,
      'voucherLabel': selectedVoucher?.title, // <-- ( ✨ NEW ✨ )
      'vendorIds': allVendorIds,
      'status': 'Received',
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      'vendorName': vendorName,
      'vendorType': vendorType,
      'hasBeenReviewed': false, // <-- ( ✨ ADD THIS LINE ✨ )
    };
    // --- ( ✨ END UPDATED ORDER DATA ✨ ) ---

    try {
      final docRef =
          await FirebaseFirestore.instance.collection('orders').add(orderData);
      final orderId = docRef.id;

      if (selectedVoucher != null) {
        await _voucherRepo.incrementVoucherRedemption(selectedVoucher!.id);
      }
      if (automaticPromo != null) {
        await FirebaseFirestore.instance
            .collection('promotions')
            .doc(automaticPromo!.id)
            .update({
          'claimedRedemptions': FieldValue.increment(1),
        });
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
              address: _selectedAddressString!,
              location: _selectedAddressLatLng!,
              total: finalTotal,
              promoLabel: voucherLabel, // Pass the correct label
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
