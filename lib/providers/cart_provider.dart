import 'package:flutter/foundation.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/models/vendor.dart';
import 'package:foodiebox/enums/checkout_type.dart';

// A helper class to store cart item details
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
}

class CartProvider with ChangeNotifier {
  // Internal storage for cart items, mapping ProductID to CartItem
  final Map<String, CartItem> _items = {};

  // State for checkout process
  CheckoutType _selectedCheckoutType = CheckoutType.delivery;
  String? _selectedPickupDay;
  String? _selectedPickupTime;

  // --- Getters for Cart Information ---

  // Returns all items in the cart as a Map
  Map<String, CartItem> get items {
    return {..._items};
  }

  // Returns all items as a List
  List<CartItem> get itemsList {
    return _items.values.toList();
  }

  // Returns the total number of items (not unique products) in the cart
  int get itemCount {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // Calculates the subtotal of the cart
  double get subtotal {
    return _items.values.fold(
        0.0, (sum, item) => sum + (item.product.discountedPrice * item.quantity));
  }

  // Groups items by vendor ID, as used in cart_page.dart
  Map<String, List<CartItem>> get itemsByVendor {
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in _items.values) {
      if (!groupedItems.containsKey(item.vendorId)) {
        groupedItems[item.vendorId] = [];
      }
      groupedItems[item.vendorId]!.add(item);
    }
    return groupedItems;
  }

  // --- ( ✨ FIX ✨ ) ---
  // This is the function that had the original error.
  // It now correctly returns 0 if the item is not in the cart.
  int getQuantityInCart(String productId) {
    if (_items.containsKey(productId)) {
      return _items[productId]!.quantity;
    }
    return 0; // Return 0 if not found
  }
  // --- ( ✨ END FIX ✨ ) ---

  // --- Getters for Checkout State ---

  CheckoutType get selectedCheckoutType => _selectedCheckoutType;
  String? get selectedPickupDay => _selectedPickupDay;
  String? get selectedPickupTime => _selectedPickupTime;

  // --- Cart Management Functions ---

  // Adds a product to the cart
  void addItem(Product product, VendorModel vendor, int quantity) {
    if (product.id == null) return; // Cannot add product without ID

    // Check if user is trying to add from a different vendor
    if (_items.isNotEmpty && _items.values.first.vendorId != vendor.uid) {
      // If so, clear the cart first
      _items.clear();
      print('Cart cleared to add items from a new vendor.');
    }

    if (_items.containsKey(product.id)) {
      // If item is already in cart, update its quantity
      _items.update(
        product.id!,
        (existingItem) => CartItem(
          product: existingItem.product,
          vendorId: existingItem.vendorId, // <--- FIX: Corrected typo
          vendorName: existingItem.vendorName,
          vendorImage: existingItem.vendorImage,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // If not in cart, add as a new item
      _items.putIfAbsent(
        product.id!,
        () => CartItem(
          product: product,
          vendorId: vendor.uid,
          vendorName: vendor.storeName,
          vendorImage: vendor.businessPhotoUrl, // Assuming this is the right field
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  // Updates the quantity of a specific item
  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity <= 0) {
      // If quantity is 0 or less, remove the item
      _items.remove(productId);
    } else {
      // Otherwise, update the quantity
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName, // <--- FIX: Corrected typo
          vendorImage: existingItem.vendorImage,
          quantity: newQuantity,
        ),
      );
    }
    notifyListeners();
  }

  // Removes an item completely from the cart
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Clears the entire cart
  void clearCart() {
    _items.clear();
    notifyListeners(); // This is correct!
  }

  // --- Checkout State Functions ---

  // Sets the checkout option and pickup time
  void setCheckoutOption(CheckoutType option, {String? day, String? time}) {
    _selectedCheckoutType = option;
    if (option == CheckoutType.pickup) {
      _selectedPickupDay = day;
      _selectedPickupTime = time;
    } else {
      // Clear pickup time if switching to delivery
      _selectedPickupDay = null;
      _selectedPickupTime = null;
    }
    notifyListeners();
  }

  // --- Validation Function ---

  // Validates stock for all items in the cart
  // Used in cart_page.dart before checkout
  String? validateStock() {
    for (final item in _items.values) {
      if (item.quantity > item.product.quantity) {
        return "Not enough stock for ${item.product.title}. Only ${item.product.quantity} left. Please reduce the quantity in your cart.";
      }
    }
    return null; // All good
  }
}