import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../util/styles.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  String _searchQuery = '';
  final List<Map<String, String>> messages = [];

  final List<Map<String, String>> faqs = [
    {
      'question': 'What is a FoodieBox blindbox?',
      'answer':
          'A surprise box of curated food items—great value, always fresh, and sometimes near expiry.'
    },
    {
      'question': 'How do I track my order?',
      'answer':
          'Go to the Orders tab in your profile. You’ll see live updates and estimated delivery time.'
    },
    {
      'question': 'Can I return items?',
      'answer':
          'Due to the nature of blindboxes and expiry-sensitive items, returns are not supported.'
    },
    {
      'question': 'How does FoodieBox help reduce waste?',
      'answer':
          'We partner with suppliers to rescue surplus and near-expiry groceries, giving them a second chance.'
    },
    {
      'question': 'How do I apply a promo code?',
      'answer':
          'You can enter promo codes at checkout before confirming your order.'
    },
  ];

  void _sendMessage(String text) {
    setState(() {
      messages.add({'from': 'user', 'text': text});
      messages.add({'from': 'bot', 'text': _generateBotReply(text)});
      _messageController.clear();
    });
  }

  String _generateBotReply(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('track') || lower.contains('order')) {
      return 'You can track your order in the Orders tab. It shows live updates.';
    } else if (lower.contains('promo')) {
      return 'Promo codes can be applied at checkout before confirming your order.';
    } else if (lower.contains('return')) {
      return 'Due to expiry-sensitive items, returns are not supported.';
    } else if (lower.contains('sustain')) {
      return 'We reduce food waste by rescuing surplus and near-expiry groceries.';
    } else {
      return 'Thanks for your question! Our team will get back to you soon.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = faqs
        .where((faq) =>
            faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
            const Text('Help & Support', style: TextStyle(color: kTextColor)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // --- Chatbot Assistant ---
          const Text('Assistant', style: kLabelTextStyle),
          const SizedBox(height: 10),
          ...messages.map((msg) {
            final isUser = msg['from'] == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: isUser ? kYellowMedium : kCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg['text']!,
                  style: const TextStyle(color: kTextColor, fontSize: 14),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms);
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your question...',
                    filled: true,
                    fillColor: kCardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: kYellowMedium, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.send, color: kPrimaryActionColor),
                onPressed: () {
                  if (_messageController.text.trim().isNotEmpty) {
                    _sendMessage(_messageController.text.trim());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // --- Searchable FAQ ---
          const Text('Search FAQs', style: kLabelTextStyle),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Type a question...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: kCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kYellowMedium, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kYellowMedium, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...filteredFaqs.map((faq) => ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                childrenPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                title: Text(faq['question']!,
                    style: const TextStyle(color: kTextColor)),
                children: [
                  Text(faq['answer']!,
                      style: const TextStyle(color: Colors.black87)),
                ],
              ).animate().fadeIn(duration: 300.ms)),

          const SizedBox(height: 30),

          // --- Feedback Form ---
          const Text('Send Feedback', style: kLabelTextStyle),
          const SizedBox(height: 10),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us what you think...',
              filled: true,
              fillColor: kCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kYellowMedium, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final feedback = _feedbackController.text.trim();
              if (feedback.isNotEmpty) {
                // TODO: Send to backend or store locally
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your feedback!')),
                );
                _feedbackController.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kYellowSoft,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Submit', style: TextStyle(color: kTextColor)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
