import 'package:flutter/material.dart';
import 'package:foodiebox/models/driver_model.dart';
import 'package:foodiebox/screens/users/main_page.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RateDriverPage extends StatefulWidget {
  final String orderId;
  final Driver driver;

  const RateDriverPage({
    super.key,
    required this.orderId,
    required this.driver,
  });

  @override
  State<RateDriverPage> createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  late ConfettiController _confettiController;
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Builds a single star for the rating
  Widget _buildStar(int index) {
    IconData icon = _rating > index ? Icons.star : Icons.star_border;
    Color color = _rating > index ? Colors.amber : Colors.grey;
    return IconButton(
      onPressed: () {
        if (_isSubmitting) return; // Disable if already submitting
        setState(() {
          _rating = index + 1;
        });
      },
      icon: Icon(icon, color: color, size: 40),
    );
  }

  /// Saves data to Firebase and plays animation
  Future<void> _submitRating() async {
    if (_rating == 0) return; // Shouldn't be possible, but good to check

    setState(() {
      _isSubmitting = true;
    });

    // --- MODIFIED: Save to Firebase (UNCOMMENTED) ---
    try {
      // 1. Update the order with the rating and mark as completed
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'rating': _rating,
        'status': 'completed', // Final status (was 'Success' in your prompt)
      });

      // 2. (Optional) Add to a driver's subcollection of ratings
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(widget.driver.id)
          .collection('ratings')
          .add({'rating': _rating, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      // Handle error
      print('Firebase update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save rating: $e')),
        );
      }
      // Don't continue if saving failed
      setState(() {
        _isSubmitting = false;
      });
      return;
    }
    // --- End Firebase Block ---

    // Play confetti if 5 stars
    if (_rating == 5) {
      _confettiController.play();
    }

    // Wait for animation, then navigate
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    // --- MODIFIED ---
    // This now navigates back to the main page as requested, clearing all
    // previous pages from the stack.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Driver Details
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: AssetImage(widget.driver.imageUrl),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(height: 16),
                Text(
                  widget.driver.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.driver.licensePlate,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Rate your driver',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Star Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => _buildStar(index)),
                ),
                const SizedBox(height: 40),

                // Submit Button
                if (_isSubmitting)
                  const CircularProgressIndicator(color: Colors.amber)
                else
                  ElevatedButton(
                    onPressed: _rating == 0 ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child:
                        const Text('Submit Rating', style: TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ),

          // --- Confetti Animation ---
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange
              ],
              emissionFrequency: 0.05,
              numberOfParticles: 20,
            ),
          ),
        ],
      ),
    );
  }
}