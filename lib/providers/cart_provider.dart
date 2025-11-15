import 'package:flutter/material.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/models/vendor.dart';
// --- FIX: Import the new enum file ---
import 'package:foodiebox/enums/checkout_type.dart';

class CartItem {
  final Product product;
  final String vendorId;
  final String vendorName;
  final String vendorImage;
  int quantity;

  CartItem({
    required this.product,
    required this.vendorId,
    required this.vendorName,
    required this.vendorImage,
    required this.quantity,
  });

  // Helper to calculate total price for this item
  double get totalPrice => product.discountedPrice * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  // --- NEW STATE for Checkout Flow ---
  CheckoutType _selectedCheckoutType = CheckoutType.delivery;
  String? _selectedPickupDay;
  String? _selectedPickupTime;

  // --- Public Getters ---
  Map<String, CartItem> get items => {..._items};
  List<CartItem> get itemsList => _items.values.toList();
  int get itemCount => _items.length;

  CheckoutType get selectedCheckoutType => _selectedCheckoutType;
  String? get selectedPickupDay => _selectedPickupDay;
  String? get selectedPickupTime => _selectedPickupTime;
  // --- END NEW STATE ---

  double get subtotal {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  Map<String, List<CartItem>> get itemsByVendor {
    final Map<String, List<CartItem>> grouped = {};
    for (var item in _items.values) {
      if (!grouped.containsKey(item.vendorId)) {
        grouped[item.vendorId] = [];
      }
      grouped[item.vendorId]!.add(item);
    }
    return grouped;
  }

  // --- NEW METHOD to set checkout options ---
  void setCheckoutOption(CheckoutType type, {String? day, String? time}) {
    _selectedCheckoutType = type;
    if (type == CheckoutType.pickup) {
      // Only set day and time if they are provided
      if(day != null) _selectedPickupDay = day;
      if(time != null) _selectedPickupTime = time;
    } else {
      // Clear pickup time if switching to delivery
      _selectedPickupDay = null;
      _selectedPickupTime = null;
    }
    notifyListeners();
  }
  // --- END NEW METHOD ---

  void addItem(Product product, VendorModel vendor, int quantity) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id!,
        (existingItem) => CartItem(
          product: existingItem.product,
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName,
          vendorImage: existingItem.vendorImage,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id!,
        () => CartItem(
          product: product,
          vendorId: vendor.uid,
          vendorName: vendor.storeName,
          vendorImage: vendor.businessPhotoUrl,
          quantity: quantity,
        ),
      );
    }

    // --- NEW LOGIC: Enforce single vendor for pickup ---
    _validatePickupState();
    // --- END NEW LOGIC ---

    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      _items.remove(productId);
    } else {
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName,
          vendorImage: existingItem.vendorImage,
          quantity: newQuantity,
        ),
      );
    }
    
    // --- NEW LOGIC: Re-validate pickup state ---
    _validatePickupState();
    // --- END NEW LOGIC ---

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _validatePickupState(); // Re-check if pickup is now possible
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    // --- NEW: Reset checkout state ---
    _selectedCheckoutType = CheckoutType.delivery;
    _selectedPickupDay = null;
    _selectedPickupTime = null;
    // --- END NEW ---
    notifyListeners();
  }

  // --- NEW HELPER METHOD ---
  void _validatePickupState() {
    final vendorIds = _items.values.map((item) => item.vendorId).toSet();
    // If user has items from more than one store, force delivery
    if (vendorIds.length > 1 && _selectedCheckoutType == CheckoutType.pickup) {
      _selectedCheckoutType = CheckoutType.delivery;
      _selectedPickupDay = null;
      _selectedPickupTime = null;
    }
  }
  // --- END NEW HELPER ---
}