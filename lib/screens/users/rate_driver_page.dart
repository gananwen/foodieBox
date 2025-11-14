import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/driver_model.dart';

class RateDriverPage extends StatefulWidget {
  final String orderId;
  final DriverModel driver;

  const RateDriverPage({
    super.key,
    required this.orderId,
    required this.driver,
  });

  @override
  State<DriverRatePage> createState() => _DriverRatePageState();
}

class _DriverRatePageState extends State<DriverRatePage> {
  double _userRating = 5.0;
  bool _isSubmitting = false;

  Future<void> submitRating() async {
    setState(() => _isSubmitting = true);
    final docRef =
        FirebaseFirestore.instance.collection('drivers').doc(widget.driver.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data()!;
      final oldRating = (data['rating'] as num).toDouble();
      final oldCount = (data['ratingsCount'] as num).toInt();

      final newCount = oldCount + 1;
      final newRating = ((oldRating * oldCount) + _userRating) / newCount;

      transaction.update(docRef, {
        'rating': newRating,
        'ratingsCount': newCount,
      });
    });

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating submitted!')),
    );
    Navigator.pop(context);
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
                    child: const Text('Submit Rating',
                        style: TextStyle(fontSize: 16)),
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
