// 路径: lib/screens/users/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import '../auth/user_login.dart';
import '../shared/about_page.dart';
import '../shared/help_page.dart';
import 'subpages/my_details_page.dart';
import 'subpages/delivery_address_page.dart';
import '../shared/notifications_page.dart';
import 'subpages/promo_card_page.dart';
import 'subpages/orders_history_page.dart';
import '../vendor_page/vendor_regieteration_page.dart'; //

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        // ... (不变) ...
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Yellow Header with Profile Info (不变) ---
            Stack(
              children: [
                ClipPath(
                  clipper: _HeaderClipper(),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: kProfileHeaderGradient,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ... (StreamBuilder 逻辑不变) ...
                      if (!snapshot.hasData || snapshot.data?.data() == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Your Name';
                      final email = data['email'] ?? 'your@email.com';
                      final imageUrl = data['profilePic'];

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : null,
                            child: imageUrl == null
                                ? const Icon(Icons.person,
                                    color: Colors.white, size: 40)
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kTextColor,
                              )),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const MyDetailsPage()),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(email,
                                    style: const TextStyle(
                                        fontSize: 13, color: kTextColor)),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit,
                                    size: 14, color: kTextColor),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- Menu Items ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  // ... (所有其他 ProfileItem 不变) ...
                  _ProfileItem(
                    icon: Icons.receipt_long,
                    label: 'Order History',
                    targetPage: OrderHistoryPage(),
                  ),
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                      icon: Icons.person_outline,
                      label: 'My Details',
                      targetPage: MyDetailsPage()),
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                      icon: Icons.location_on_outlined,
                      label: 'Delivery Address',
                      targetPage: DeliveryAddressPage()),
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                      icon: Icons.card_giftcard,
                      label: 'Promo Card',
                      targetPage: PromoCardPage()),
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                      targetPage: NotificationsPage(userRole: 'User')),
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                    icon: Icons.help_outline,
                    label: 'Help',
                    targetPage: HelpPage(userRole: 'User'),
                  ),
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                      icon: Icons.info_outline,
                      label: 'About',
                      targetPage: AboutPage()),

                  // --- ( ✨ 2. 在这里添加新的列表项 ✨ ) ---
                  Divider(height: 1, thickness: 1),
                  _ProfileItem(
                    icon: Icons.store_mall_directory_outlined, // 商业图标
                    label: 'FoodieBox for Business',
                    targetPage: VendorRegistrationPage(), //
                  ),
                  // --- ( ✨ 结束 ✨ ) ---
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- ( ✨ 3. 移除了 _buildBusinessButton() ✨ ) ---
            // (之前在这里有一个单独的按钮)

            // --- Log Out Button (不变) ---
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: kTextColor),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kTextColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kYellowSoft,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- ( ✨ 4. 移除了 _buildBusinessButton 辅助函数 ✨ ) ---
}

// --- _ProfileItem (不变) ---
class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget targetPage;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.targetPage,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kTextColor),
      title: Text(label, style: const TextStyle(color: kTextColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
    );
  }
}

// --- _HeaderClipper (不变) ---
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
