import 'package:flutter/material.dart';
import 'package:foodiebox/models/order_model.dart';
import 'package:foodiebox/models/review.dart';
import 'package:foodiebox/repositories/review_repository.dart';
import 'package:foodiebox/util/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateOrderPage extends StatefulWidget {
  final OrderModel order;

  const RateOrderPage({super.key, required this.order});

  @override
  State<RateOrderPage> createState() => _RateOrderPageState();
}

class _RateOrderPageState extends State<RateOrderPage> {
  final ReviewRepository _reviewRepo = ReviewRepository();
  final _reviewTextController = TextEditingController();
  double _rating = 0;
  bool _isLoading = false;

  void _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to leave a review.')),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Assuming only one vendor ID per order for reviews
      final vendorId = widget.order.vendorIds.first; 

      final review = ReviewModel(
        id: '', // Will be set by Firebase
        orderId: widget.order.id,
        vendorId: vendorId,
        userId: user.uid,
        rating: _rating,
        reviewText: _reviewTextController.text.trim(),
        timestamp: DateTime.now(),
      );

      await _reviewRepo.addReviewAndUpdateVendor(review);

      if (mounted) {
        // Show a success dialog
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Thank You!'),
            content: const Text('Your feedback has been submitted successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // Pop the review page itself
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Show the specific error message
          SnackBar(content: Text('Failed to submit review: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leave a Review', style: TextStyle(color: kTextColor)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: kTextColor),
      ),
      // Use a bottom navigation bar for the button
      // This keeps the button visible even when typing
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20).copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5), // changes position of shadow
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryActionColor, // Use your app's theme color
            foregroundColor: kTextColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            shadowColor: kPrimaryActionColor.withOpacity(0.4),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: kTextColor,
                    strokeWidth: 3,
                  ),
                )
              : const Text(
                  'Submit Review',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info
            Text(
              widget.order.vendorName ?? 'Your Order',
              style: kLabelTextStyle.copyWith(fontSize: 22),
            ),
            Text(
              'Order ID: ${widget.order.id.substring(0, 8)}...',
              style: kHintTextStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Star Rating
            Center(
              child: Text(
                'How was your experience?',
                style: kLabelTextStyle.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 48, // Made stars bigger
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 32),

            // Review Text
            const Text(
              'Share your thoughts',
              style: kLabelTextStyle,
            ),
            const SizedBox(height: 4),
            Text(
              'Consider these topics: Taste • Freshness • Portion size',
              style: kHintTextStyle.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reviewTextController,
              maxLines: 7, // Made it taller
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'Your review helps other users find the best food...',
                hintStyle: kHintTextStyle,
                fillColor: kCardColor,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimaryActionColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40), // Added space for the bottom button
          ],
        ),
      ),
    );
  }
}