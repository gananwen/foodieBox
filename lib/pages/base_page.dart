import 'package:flutter/material.dart';
import '../utils/styles.dart';
import 'main_page.dart';
import 'grocery_page.dart';
import 'profile_page.dart';
import 'browse_page.dart';
import 'order_page.dart';
import 'blind_box.dart';

class BasePage extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const BasePage({super.key, required this.currentIndex, required this.child});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  void _onTabTapped(int index) {
    if (index == widget.currentIndex) return;

    Widget target;
    switch (index) {
      case 0:
        target = const MainPage();
        break;
      case 1:
        target = const BlindBox();
        break;
      case 2:
        target = const GroceryPage();
        break;
      case 3:
        target = const BrowsePage();
        break;
      case 4:
        target = const OrdersPage();
        break;
      case 5:
        target = const ProfilePage();
        break;
      default:
        target = const MainPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => target),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: widget.child,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: _onTabTapped,
        backgroundColor: kCardColor,
        selectedItemColor: kTextColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'BlindBox'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Grocery'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
