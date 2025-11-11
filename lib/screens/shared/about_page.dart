import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this package
import '../../util/styles.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _impactCounter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _impactCounter = IntTween(begin: 0, end: 1280).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: kTextColor)),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14, color: kTextColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text('About FoodieBox', style: TextStyle(color: kTextColor)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ListView(
          children: [
            // --- Illustration Header ---
            Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: kYellowHeaderGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.eco, size: 60, color: kPrimaryActionColor),
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 20),

            // --- App Name & Tagline ---
            const Center(
              child: Text('FoodieBox',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kTextColor)),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Smart choices. Sustainable living.',
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
            ),
            const SizedBox(height: 30),

            // --- Sustainability Impact Counter ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kYellowLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedBuilder(
                animation: _impactCounter,
                builder: (context, child) {
                  return Column(
                    children: [
                      const Text('🌍 Sustainability Impact',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kTextColor)),
                      const SizedBox(height: 6),
                      Text('${_impactCounter.value} kg of food saved',
                          style: const TextStyle(
                              fontSize: 20, color: kPrimaryActionColor)),
                    ],
                  );
                },
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 300.ms),

            const SizedBox(height: 30),

            // --- Mission Section ---
            const Text('Our Mission', style: kLabelTextStyle),
            const SizedBox(height: 10),
            const Text(
              'FoodieBox is built for conscious consumers who care about sustainability and smart spending. '
              'We help reduce food waste by offering blindboxes and almost-expiry groceries at discounted prices—making every meal a win for your wallet and the planet.',
              style: TextStyle(fontSize: 14, color: kTextColor, height: 1.5),
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

            const SizedBox(height: 25),

            // --- What We Offer Section ---
            const Text('What We Offer', style: kLabelTextStyle),
            const SizedBox(height: 10),
            _buildBullet('🎁 Surprise blindboxes with curated food items'),
            _buildBullet(
                '🛒 Discounted groceries nearing expiry (still fresh!)'),
            _buildBullet('🌱 A platform that supports zero-waste living'),
            _buildBullet('📦 Fast, reliable delivery across Klang Valley'),

            const SizedBox(height: 25),

            // --- Contact Info ---
            const Text('Contact Us', style: kLabelTextStyle),
            const SizedBox(height: 10),
            const Text(
              'Have questions or feedback? Reach out anytime:',
              style: TextStyle(fontSize: 14, color: kTextColor),
            ),
            const SizedBox(height: 6),
            const Text(
              '📧 support@foodiebox.app\n🌐 www.foodiebox.app',
              style: TextStyle(fontSize: 14, color: kPrimaryActionColor),
            ),

            const SizedBox(height: 30),
            const Center(
              child: Text('App Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
