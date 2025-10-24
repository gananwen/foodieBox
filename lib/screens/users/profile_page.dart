import 'package:flutter/material.dart';
import '../../util/styles.dart';
import '../../widgets/base_page.dart';
import '../auth/user_login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BasePage(
      currentIndex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Yellow Header with Profile Info ---
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Afsar Hossen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'lmshuvo97@gmail.com',
                          style: TextStyle(fontSize: 13, color: kTextColor),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: kTextColor),
                      ],
                    ),
                  ],
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
                _ProfileItem(icon: Icons.receipt_long, label: 'Orders'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.person_outline, label: 'My Details'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.location_on_outlined, label: 'Delivery Address'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.credit_card, label: 'Payment Methods'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.card_giftcard, label: 'Promo Card'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.notifications_none, label: 'Notifications'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.help_outline, label: 'Help'),
                Divider(height: 1, thickness: 1),
                _ProfileItem(icon: Icons.info_outline, label: 'About'),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- Log Out Button ---
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
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
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kTextColor),
      title: Text(label, style: const TextStyle(color: kTextColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Add navigation or action logic here
      },
    );
  }
}

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
