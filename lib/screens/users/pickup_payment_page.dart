import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodiebox/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:foodiebox/util/styles.dart';
import 'dart:math'; // To generate the pickup ID
import 'pickup_confirmation_page.dart';
import 'package:foodiebox/enums/checkout_type.dart';
import 'package:foodiebox/models/promotion.dart';
import 'package:foodiebox/models/voucher_model.dart';
import 'package:foodiebox/repositories/voucher_repository.dart';

class PickupPaymentPage extends StatefulWidget {
  final double subtotal;
  final List<CartItem> items;

  const PickupPaymentPage({
    super.key,
    required this.subtotal,
    required this.items,
  });

  @override
  State<PickupPaymentPage> createState() => _PickupPaymentPageState();
}

class _PickupPaymentPageState extends State<PickupPaymentPage> {
  String selectedPayment = 'Credit/Debit Card';
  bool _isLoading = false;
  User? _user;

  late double subtotal;

  final VoucherRepository _voucherRepo = VoucherRepository();

  PromotionModel? automaticPromo;
  double promoDiscount = 0.0;
  bool _isLoadingPromo = true;

  VoucherModel? selectedVoucher;
  double voucherDiscount = 0.0;
  String selectedVoucherCode = '';
  String selectedVoucherLabel = '';
  String voucherError = '';
  List<VoucherEligibility> voucherList = [];
  bool _isLoadingVouchers = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    subtotal = widget.subtotal;
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchAutomaticPromo();
    // Pass the subtotal *after* automatic promo to the voucher fetcher
    await _fetchVouchers(subtotal - promoDiscount);
  }

  Future<void> _fetchAutomaticPromo() async {
    try {
      final now = DateTime.now();
      // --- UPDATED: Check for BlindBox or Grocery ---
      // Note: 'Blind Box' (with space) comes from product.dart
      final productType = widget.items.isNotEmpty
          ? (widget.items.first.product.productType == 'Blind Box'
              ? 'BlindBox'
              : 'Grocery')
          : 'Grocery'; // Default to grocery for pickup
      // --- END UPDATED ---

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

    // --- NEW: Get the single vendor type from cart ---
    // Note: 'Blind Box' (with space) comes from product.dart
    final cartVendorTypes = widget.items.isNotEmpty
        ? [
            (widget.items.first.product.productType == 'Blind Box'
                ? 'BlindBox'
                : 'Grocery')
          ]
        : <String>['Grocery']; // Default to grocery if cart is empty
    // --- END NEW ---

    List<VoucherEligibility> processedList = [];
    for (var voucher in vouchers) {
      // --- UPDATED: Pass the cart vendor type ---
      final message = await _voucherRepo.getEligibilityStatus(
        voucher: voucher,
        subtotal: currentSubtotal,
        currentOrderType: 'pickup',
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
      return b.voucher.minSpend.compareTo(a.voucher.minSpend);
    });

    if (mounted) {
      setState(() {
        voucherList = processedList;
        _isLoadingVouchers = false;
      });
    }
  }

  double getTotal() {
    final subtotalAfterPromo = subtotal - promoDiscount;
    final voucherDiscountOnSubtotal =
        selectedVoucher?.calculateDiscount(subtotalAfterPromo) ?? 0.0;

    if (voucherDiscountOnSubtotal != voucherDiscount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          setState(() => voucherDiscount = voucherDiscountOnSubtotal);
      });
    }
    return subtotal - promoDiscount - voucherDiscount;
  }

  String _generatePickupId() {
    final random = Random();
    String letter = String.fromCharCode(random.nextInt(26) + 65); // A-Z
    String digits = (random.nextInt(900) + 100).toString(); // 100-999
    return '$letter-$digits';
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
              title: const Text('Cash at Counter'),
              onTap: () {
                setState(() => selectedPayment = 'Cash at Counter');
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
      isScrollControlled: true,
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
                    'Choose a Promo Code', // Title from image
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: voucherList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = voucherList[index];
                      final voucher = item.voucher;
                      final isSelected = selectedVoucherCode == voucher.code;
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
                            selectedVoucher = voucher;
                            selectedVoucherCode = voucher.code;
                            selectedVoucherLabel = voucher.title;
                            voucherDiscount =
                                voucher.calculateDiscount(subtotalAfterPromo);
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
  // --- END VOUCHER MODAL ---

  Future<void> _placePickupOrder() async {
    final cart = context.read<CartProvider>();
    if (_user == null) {
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
    if (cart.selectedPickupDay == null || cart.selectedPickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Error: Pickup time not selected. Please go back to the store page.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- NEW: Get the single vendor type from cart ---
    // Note: 'Blind Box' (with space) comes from product.dart
    final cartVendorTypes = widget.items.isNotEmpty
        ? [
            (widget.items.first.product.productType == 'Blind Box'
                ? 'BlindBox'
                : 'Grocery')
          ]
        : <String>['Grocery'];
    // --- END NEW ---

    if (selectedVoucher != null) {
      final subtotalAfterPromo = subtotal - promoDiscount;
      // --- UPDATED: Pass the cart vendor type ---
      final eligibilityMessage = await _voucherRepo.getEligibilityStatus(
        voucher: selectedVoucher!,
        subtotal: subtotalAfterPromo,
        currentOrderType: 'pickup',
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

    String vendorName = 'Unknown Store';
    String vendorId = '';
    String vendorAddress = '';
    String vendorType = 'Grocery';
    if (widget.items.isNotEmpty) {
      vendorId = widget.items.first.vendorId;
      try {
        final vendorDoc = await FirebaseFirestore.instance
            .collection('vendors')
            .doc(vendorId)
            .get();
        if (vendorDoc.exists) {
          vendorName = vendorDoc.data()?['storeName'] ?? 'Unknown Store';
          vendorAddress = vendorDoc.data()?['storeAddress'] ?? 'No address';
          vendorType = vendorDoc.data()?['vendorType'] ?? 'Grocery';
        }
      } catch (e) {
        print("Error fetching vendor data: $e");
      }
    }

    final String pickupId = _generatePickupId();
    final double total = getTotal();
    final double totalDiscount = promoDiscount + voucherDiscount;

    // --- ( ✨ UPDATED ORDER DATA ✨ ) ---
    // Added promoLabel and voucherLabel to save to Firebase
    final orderData = {
      'userId': _user!.uid,
      'orderType': 'Pickup',
      'pickupId': pickupId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorAddress': vendorAddress,
      'vendorType': vendorType,
      'paymentMethod': selectedPayment,
      'subtotal': subtotal,
      'discount': totalDiscount,
      'total': total,
      'vendorIds': [vendorId],
      'promoCode': null, // Deprecated, but keeping for schema
      'promoLabel': automaticPromo?.title, // <-- ( ✨ NEW ✨ )
      'voucherCode': selectedVoucher?.code,
      'voucherLabel': selectedVoucher?.title, // <-- ( ✨ NEW ✨ )
      'status': 'paid_pending_pickup',
      'items': itemsData,
      'timestamp': FieldValue.serverTimestamp(),
      'pickupDay': cart.selectedPickupDay,
      'pickupTime': cart.selectedPickupTime,
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
        cart.clearCart();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PickupConfirmationPage(
              orderId: orderId,
              pickupId: pickupId,
              vendorName: vendorName,
              vendorAddress: vendorAddress,
              total: total,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pickup Order', style: TextStyle(color: kTextColor)),
        backgroundColor: kYellowMedium,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Voucher Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _showVoucherSelector,
              icon: const Icon(Icons.local_offer, size: 18),
              label: Text(
                selectedVoucherCode.isEmpty
                    ? 'Select Voucher'
                    : 'Voucher: $selectedVoucherCode',
                style: const TextStyle(fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                backgroundColor: selectedVoucherCode.isEmpty
                    ? Colors.white
                    : Colors.amber.shade100,
                foregroundColor: Colors.black,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: selectedVoucherCode.isEmpty
                        ? Colors.grey.shade300
                        : Colors.amber,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (selectedVoucherCode.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedVoucherCode = '';
                    selectedVoucherLabel = '';
                    voucherDiscount = 0.0;
                    voucherError = '';
                    selectedVoucher = null;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      if (cart.selectedCheckoutType == CheckoutType.pickup &&
                          cart.selectedPickupDay != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.access_time,
                                  color: kPrimaryActionColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  '${cart.selectedPickupDay}, ${cart.selectedPickupTime}',
                                  style: kLabelTextStyle.copyWith(
                                      color: kPrimaryActionColor)),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const Divider(height: 1),
                  ...widget.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.product.title}',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'RM${(item.product.discountedPrice * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('RM${subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_isLoadingPromo)
                    const Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Checking for promotions...',
                          style: kHintTextStyle),
                    ),
                  if (promoDiscount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
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
                    ),
                  if (voucherDiscount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(selectedVoucherLabel,
                              style:
                                  kHintTextStyle.copyWith(color: Colors.green)),
                          Text('-RM${voucherDiscount.toStringAsFixed(2)}',
                              style:
                                  kHintTextStyle.copyWith(color: Colors.green)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Service Fee', style: kHintTextStyle),
                      Text('RM 0.00', style: kHintTextStyle),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        'RM${getTotal().toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryActionColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placePickupOrder,
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
                    'Pay RM${getTotal().toStringAsFixed(2)} & Get Pickup ID',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
