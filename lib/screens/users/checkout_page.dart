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
import 'package:foodiebox/enums/checkout_type.dart';
import 'qr_payment_page.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api/api_config.dart';

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
    {'label': 'Express', 'time': '20 min', 'multiplier': 1.2},
    {'label': 'Standard', 'time': '40 min', 'multiplier': 1.0},
    {'label': 'Saver', 'time': '60 min', 'multiplier': 0.8},
  ];
  String selectedDelivery = 'Standard';

  bool agreedToTerms = true;
  String? _selectedAddressString;
  LatLng? _selectedAddressLatLng;
  String? _selectedContactName;
  String? _selectedContactPhone;
  String? _selectedAddressLabel;

  User? _user;

  late double subtotal;
  double deliveryFee = 0.0;
  double _finalDeliveryPrice = 0.0;
  bool _isLoading = false;
  bool _isCalculatingFees = false;

  final VoucherRepository _voucherRepo = VoucherRepository();

  PromotionModel? automaticPromo;
  double promoDiscount = 0.0;
  bool _isLoadingPromo = true;

  String voucherCode = '';
  String voucherLabel = '';
  VoucherModel? selectedVoucher;
  List<VoucherEligibility> voucherList = [];
  bool _isLoadingVouchers = true;
  double voucherDiscount = 0.0;
  String voucherError = '';

  // Vendor info
  LatLng? _vendorLocation;
  String _distanceKm = '';
  String? _vendorAddressString; // <-- Added field

  @override
  void initState() {
    super.initState();
    subtotal = widget.subtotal;
    _user = FirebaseAuth.instance.currentUser;
    _loadDefaultAddress();
    _fetchData();
  }

  @override
  void didUpdateWidget(covariant CheckoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (widget.items.isNotEmpty) {
      await _fetchVendorLocation(widget.items.first.vendorId);
    }
    await _fetchAutomaticPromo();
    await _fetchVouchers(subtotal - promoDiscount);

    if (_selectedAddressString != null && _vendorAddressString != null) {
      await _calculateDeliveryFee();
    } else {
      setState(() {
        deliveryFee = 15.00;
        _finalDeliveryPrice = 15.00;
      });
    }
  }

  // --- Fetch Vendor Address from Firestore ---
  Future<void> _fetchVendorLocation(String vendorId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final address = data['storeAddress'] as String?;
        if (address != null && address.isNotEmpty) {
          _vendorAddressString = address;
        } else {
          print("Vendor document missing storeAddress field.");
        }
      }
    } catch (e) {
      print("Error fetching vendor address: $e");
    }
  }

  // --- Calculate Delivery Fee using address strings ---
  Future<void> _calculateDeliveryFee() async {
    if (_selectedAddressString == null || _vendorAddressString == null) return;

    setState(() => _isCalculatingFees = true);

    final origin = Uri.encodeComponent(_vendorAddressString!);
    final destination = Uri.encodeComponent(_selectedAddressString!);

    final apiKey = ApiConfig.googleMapsApiKey;

    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$origin&destinations=$destination&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK' &&
          data['rows'] != null &&
          data['rows'].isNotEmpty) {
        final element = data['rows'][0]['elements'][0];

        if (element['status'] == 'OK') {
          final distanceMeters = element['distance']['value'] as int;
          final distanceKm = distanceMeters / 1000.0;

          final baseFee = _determineFeeByDistance(distanceKm);

          setState(() {
            deliveryFee = baseFee;
            _distanceKm = distanceKm.toStringAsFixed(1);

            final selectedMultiplier = _deliveryOptions
                .firstWhere((opt) => opt['label'] == selectedDelivery)['multiplier'] as double;

            _finalDeliveryPrice = baseFee * selectedMultiplier;
          });
        } else {
          setState(() {
            deliveryFee = 10.0;
            _finalDeliveryPrice = 10.0;
            _distanceKm = 'N/A';
          });
          print('Distance Matrix element error: ${element['status']}');
        }
      } else {
        setState(() {
          deliveryFee = 10.0;
          _finalDeliveryPrice = 10.0;
          _distanceKm = 'N/A';
        });
        print('Distance Matrix API error: ${data['status']}');
      }
    } catch (e) {
      print("Error calling Distance Matrix API: $e");
      setState(() {
        deliveryFee = 10.0;
        _finalDeliveryPrice = 10.0;
        _distanceKm = 'N/A';
      });
    } finally {
      setState(() => _isCalculatingFees = false);
    }
  }

  double _determineFeeByDistance(double distanceKm) {
    if (distanceKm <= 3.0) {
      return 3.50;
    } else if (distanceKm <= 7.0) {
      return 5.50;
    } else if (distanceKm <= 12.0) {
      return 8.00;
    } else {
      return 12.00;
    }
  }

  // --- END NEW LOGIC ---

  Future<void> _fetchAutomaticPromo() {
    if (widget.items.isEmpty) {
      setState(() => _isLoadingPromo = false);
      return Future.value(); 
    }
    final String vendorId = widget.items.first.vendorId;
    final String productType = widget.items.first.product.productType == 'Blindbox'
        ? 'Blindbox'
        : 'Grocery';

    try {
      final now = DateTime.now();
      
      FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId) 
          .collection('promotions') 
          .where('endDate', isGreaterThanOrEqualTo: now) 
          .get()
          .then((snapshot) {
            
      final promos = snapshot.docs
          .map((doc) => PromotionModel.fromMap(doc.data(), doc.id))
          .where((promo) =>
              promo.startDate.isBefore(now) &&
              (promo.totalRedemptions == 0 || promo.claimedRedemptions < promo.totalRedemptions))
          .toList();

      final validPromos = promos.where((promo) =>
              promo.productType == productType && 
              promo.startDate.isBefore(now) &&
              (promo.totalRedemptions == 0 || promo.claimedRedemptions < promo.totalRedemptions) &&
              subtotal >= promo.minSpend 
          ).toList();

      if (mounted && validPromos.isNotEmpty) {
        validPromos.sort((a, b) {
          int minSpendComp = b.minSpend.compareTo(a.minSpend);
          if (minSpendComp != 0) return minSpendComp;
          return b.discountPercentage.compareTo(a.discountPercentage);
        });

        setState(() {
          automaticPromo = validPromos.first; 
          promoDiscount =
              subtotal * (automaticPromo!.discountPercentage / 100.0);
          _isLoadingPromo = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingPromo = false);
      }
    });
    } catch (e) {
      if (mounted) setState(() => _isLoadingPromo = false);
      print("Error fetching automatic promo: $e");
    }
    return Future.value();
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
        .map((item) => item.product.productType == 'Blind Box' ? 'BlindBox' : 'Grocery')
        .toSet()
        .toList();

    List<VoucherEligibility> processedList = [];
    for (var voucher in vouchers) {
      final message = await _voucherRepo.getEligibilityStatus(
        voucher: voucher,
        subtotal: currentSubtotal,
        currentOrderType: 'delivery',
        cartVendorTypes: cartVendorTypes,
      );
      processedList.add(VoucherEligibility(
        voucher: voucher,
        eligibilityMessage: message,
        isEligible: message == "Eligible",
      ));
    }

    processedList.sort((a, b) {
      if (a.isEligible && !b.isEligible) return -1;
      if (!a.isEligible && b.isEligible) return 1;
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      final data = doc.data();

      if (data != null && data['selectedAddress'] != null) {
        _updateSelectedAddress(data['selectedAddress'] as Map<String, dynamic>);
      }
      
      // We rely on _fetchData (called in initState) to trigger the initial fee calculation
      // after this function completes and sets _selectedAddressLatLng.

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
    
    // Recalculate fees immediately after address selection/update
    if (_selectedAddressLatLng != null && _vendorLocation != null) {
      _calculateDeliveryFee();
    }
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeliveryAddressPage()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      _updateSelectedAddress(result);
      
      // If the new address is selected, save it as default in Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'selectedAddress': result,
          });
      }
    }
  }

  double getTotal() {
    final subtotalAfterPromo = subtotal - promoDiscount;
    final voucherDiscountOnSubtotal =
        selectedVoucher?.calculateDiscount(subtotalAfterPromo) ?? 0.0;

    final finalDeliveryFee =
        (selectedVoucher?.freeDelivery ?? false) ? 0.0 : _finalDeliveryPrice; // USE _finalDeliveryPrice

    // Corrected: Update state variable here (must be done in a post frame callback if outside setState)
    if (voucherDiscountOnSubtotal != voucherDiscount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          setState(() => voucherDiscount = voucherDiscountOnSubtotal);
      });
    }
    return subtotalAfterPromo - voucherDiscountOnSubtotal + finalDeliveryFee;
  }
  
  // --- VOUCHER MODAL (UNCHANGED) ---
  void _showVoucherSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.grey[100], 
      builder: (context) {
        if (_isLoadingVouchers) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        // ... (Voucher modal UI remains the same)
        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Choose a Promo Code', 
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
                          if (!isEligible) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(eligibilityMessage),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            voucherCode = voucher.code;
                            voucherLabel = voucher.title;
                            selectedVoucher = voucher;
                            voucherDiscount =
                                voucher.calculateDiscount(subtotal - promoDiscount);
                            voucherError = '';
                          });
                          Navigator.pop(context);
                        },
                        child: Opacity(
                          opacity: isEligible ? 1.0 : 0.6,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? kPrimaryActionColor 
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                      eligibilityMessage, 
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

  Widget _buildDeliveryOptionWidget(Map<String, dynamic> option) {
    final String label = option['label'];
    final String time = option['time'];
    final double baseFee = deliveryFee; // Use the calculated base fee
    final double multiplier = option['multiplier']; // Get multiplier
    final isSelected = selectedDelivery == label;
    
    // Calculate final price based on base fee
    double finalPrice = baseFee * multiplier; 
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDelivery = label;
          // CRITICAL FIX: Set the final delivery price state variable
          _finalDeliveryPrice = finalPrice; 
          
          // Re-trigger total calculation
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {})); 
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
          // ALIGNMENT FIX: Center content vertically
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // ALIGNMENT FIX: Center the column contents vertically
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(time, style: kHintTextStyle.copyWith(fontSize: 12)),
              ],
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isCalculatingFees 
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: kTextColor))
                  : Text(
                      'RM${finalPrice.toStringAsFixed(2)}',
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
            color: kYellowMedium.withOpacity(0.3),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            
            // --- Distance Display ---
            if (_distanceKm.isNotEmpty && _distanceKm != 'N/A')
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Distance to Vendor: $_distanceKm km',
                  style: kHintTextStyle.copyWith(color: Colors.blueGrey),
                ),
              ),
            // --- End Distance Display ---
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
            // Show all options, using the base calculated fee
            ..._deliveryOptions.map(_buildDeliveryOptionWidget).toList(), 
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
                    // Recalculate fees if necessary (though the base fee shouldn't change)
                    _calculateDeliveryFee(); 
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
                      _isCalculatingFees 
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text('RM${_finalDeliveryPrice.toStringAsFixed(2)}', // USE _finalDeliveryPrice
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
                // --- MODIFIED: Call _proceedToPayment ---
                onPressed: agreedToTerms && !_isLoading && !_isCalculatingFees ? _proceedToPayment : null,
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
                    : Text(
                        _isCalculatingFees ? 'Calculating Fees...' : 'Proceed to Payment',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIED: _proceedToPayment function (Packages data and navigates to QR Page) ---
  Future<void> _proceedToPayment() async {
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

    // --- Validate Vouchers (Voucher validation logic remains here) ---
    final cartVendorTypes = widget.items
        .map((item) => item.product.productType == 'Blind Box' ? 'BlindBox' : 'Grocery')
        .toSet()
        .toList();

    if (selectedVoucher != null) {
      final subtotalAfterPromo = subtotal - promoDiscount;
      final eligibilityMessage = await _voucherRepo.getEligibilityStatus(
        voucher: selectedVoucher!,
        subtotal: subtotalAfterPromo,
        currentOrderType: 'delivery',
        cartVendorTypes: cartVendorTypes,
      );
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
    
    // --- Prepare Order Data ---
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
        (selectedVoucher?.freeDelivery ?? false) ? 0.0 : _finalDeliveryPrice; 
    final totalDiscount = promoDiscount + voucherDiscount;


    final orderData = {
      'userId': _user!.uid,
      'orderType': 'Delivery',
      'address': _selectedAddressString,
      'lat': _selectedAddressLatLng!.latitude,
      'lng': _selectedAddressLatLng!.longitude,
      'contactName': _selectedContactName,
      'contactPhone': _selectedContactPhone,
      'deliveryOption': selectedDelivery,
      'paymentMethod': 'QR Pay',
      'subtotal': subtotal,
      'discount': totalDiscount,
      'deliveryFee': finalDeliveryFee,
      'total': finalTotal,
      'promoCode': null,
      'promoLabel': automaticPromo?.title, 
      'voucherCode': selectedVoucher?.code,
      'voucherLabel': selectedVoucher?.title, 
      'vendorIds': allVendorIds,
      'status': 'Awaiting Payment Proof', 
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      'vendorName': vendorName,
      'vendorType': vendorType,
      'hasBeenReviewed': false,
    };
    
    // --- Navigate to QR Payment Page ---
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QrPaymentPage(
            orderData: orderData,
            orderType: CheckoutType.delivery,
          ),
        ),
      );
    }

    setState(() => _isLoading = false);
  }
}