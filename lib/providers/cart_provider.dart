import 'package:flutter/foundation.dart';
import 'package:foodiebox/models/product.dart';
import 'package:foodiebox/models/vendor.dart';

// 1. Define what a Cart Item looks like
class CartItem {
  final Product product;
  int quantity;
  final String vendorId;
  final String vendorName;
  final String vendorImage;

  CartItem({
    required this.product,
    required this.quantity,
    required this.vendorId,
    required this.vendorName,
    required this.vendorImage,
  });

  // Helper to calculate total price for this item
  double get totalPrice => product.discountedPrice * quantity;
}

// 2. Create the Cart Provider
// This class will manage the state of the shopping cart
class CartProvider with ChangeNotifier {
  // A map to store cart items, using the product ID as the key
  final Map<String, CartItem> _items = {};

  // Public getter to access the cart items
  Map<String, CartItem> get items {
    return {..._items};
  }

  // Helper to get the raw list of items
  List<CartItem> get itemsList {
    return _items.values.toList();
  }

  // Get the total number of *unique* items in the cart
  int get itemCount {
    return _items.length;
  }

  // Calculate the subtotal of all items in the cart
  double get subtotal {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  // Helper to group items by vendor for the UI
  Map<String, List<CartItem>> get itemsByVendor {
    final Map<String, List<CartItem>> groupedItems = {};
    for (var item in _items.values) {
      if (!groupedItems.containsKey(item.vendorId)) {
        // If this is the first item from this vendor, create a new list
        groupedItems[item.vendorId] = [];
      }
      // Add the item to its vendor's list
      groupedItems[item.vendorId]!.add(item);
    }
    return groupedItems;
  }

  // Add an item to the cart
  void addItem(Product product, VendorModel vendor, int quantity) {
    if (_items.containsKey(product.id)) {
      // If the item is already in the cart, just update the quantity
      _items.update(
        product.id!,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + quantity, // Add to existing quantity
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName,
          vendorImage: existingItem.vendorImage,
        ),
      );
    } else {
      // If it's a new item, add it to the map
      _items.putIfAbsent(
        product.id!,
        () => CartItem(
          product: product,
          quantity: quantity,
          vendorId: vendor.uid,
          vendorName: vendor.storeName,
          vendorImage: vendor.businessPhotoUrl,
        ),
      );
    }
    // Notify all listeners (like the UI) that the cart has changed
    notifyListeners();
  }

  // Update the quantity of a specific item
  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity <= 0) {
      // If the new quantity is zero or less, remove the item
      _items.remove(productId);
    } else {
      // Otherwise, update the quantity
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: newQuantity,
          vendorId: existingItem.vendorId,
          vendorName: existingItem.vendorName,
          vendorImage: existingItem.vendorImage,
        ),
      );
    }
    notifyListeners();
  }

  // Remove an item completely from the cart
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Clear all items from the cart (e.g., after a successful order)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}