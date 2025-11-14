import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodiebox/models/driver_model.dart';
import 'package:foodiebox/screens/users/main_page.dart'; // To go home

class RateDriverPage extends StatefulWidget {
  final String orderId;
  final DriverModel driver;

  const RateDriverPage({
    super.key,
    required this.orderId,
    required this.driver,
  });

  @override
  State<RateDriverPage> createState() => _RateDriverPageState();
}

class _RateDriverPageState extends State<RateDriverPage> {
  int _rating = 0; // 0 = not rated, 1-5
  final List<String> _feedbackOptions = [
    'Pick Up',
    'Timing',
    'Politeness',
    'Driving',
    'Payment',
    'Others',
  ];
  final Set<String> _selectedFeedback = {};
  final _commentController = TextEditingController();
  bool _isLoading = false;

  void _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Show rating info for demo (doesn't upload if you want)
      print('OrderId: ${widget.orderId}');
      print('DriverId: ${widget.driver.id}');
      print('Rating: $_rating');
      print('Feedback: ${_selectedFeedback.join(', ')}');
      print('Comment: ${_commentController.text}');

      // Navigate back to main page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 0:
        return 'Rate your driver';
      case 1:
        return 'Terrible';
      case 2:
        return 'Bad';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent!';
      default:
        return 'Rate your driver';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Last Order', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Driver Info
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.driver.imageUrl.isNotEmpty
                  ? NetworkImage(widget.driver.imageUrl)
                  : null,
              child: widget.driver.imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.driver.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'GO-RIDE',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),

            // Star Rating
            Text(
              _getRatingText(_rating),
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color:
                      _rating > 0 && _rating < 3 ? Colors.red : Colors.black),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // Feedback Tags
            const Text(
              'What we can do better?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _feedbackOptions.map((tag) {
                final isSelected = _selectedFeedback.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFeedback.add(tag);
                      } else {
                        _selectedFeedback.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.amber.shade200,
                  checkmarkColor: Colors.black,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.black87),
                  backgroundColor: Colors.grey.shade100,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Add Comment
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add Comment',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : const Text(
                        'SUBMIT',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
