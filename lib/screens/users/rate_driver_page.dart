import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/driver_model.dart';

class DriverRatePage extends StatefulWidget {
  final DriverModel driver;
  const DriverRatePage({super.key, required this.driver});

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
      appBar: AppBar(title: Text('Rate ${widget.driver.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(widget.driver.imageUrl, height: 150),
            const SizedBox(height: 16),
            Text(widget.driver.name, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) => _userRating = rating,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : submitRating,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
