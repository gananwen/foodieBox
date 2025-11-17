// 路径: lib/pages/vendor_home/help_page.dart (或你的用户 App 路径)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../util/styles.dart';

// --- ( ✨ 新增导入 ✨ ) ---
import '../../repositories/feedback_repository.dart';
// (确保你的 user.dart 路径正确，如果需要)
// import '../../models/user.dart';

class HelpPage extends StatefulWidget {
  // --- ( ✨ 已修改 ✨ ) ---
  // 页面现在需要知道用户的角色
  final String userRole; // 应该是 'User' 或 'Vendor'

  const HelpPage({super.key, required this.userRole});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  // --- ( ✨ 新增 ✨ ) ---
  final FeedbackRepository _feedbackRepo = FeedbackRepository();
  bool _isSubmittingFeedback = false;

  // --- ( ✨ 已修改：FAQ 逻辑 ✨ ) ---
  late List<Map<String, String>> _allFaqs;
  List<Map<String, String>> _filteredFaqs = []; // 默认在 initState 中填充

  String _searchQuery = '';
  final List<Map<String, String>> messages = []; // (聊天机器人逻辑保持不变)

  @override
  void initState() {
    super.initState();
    _initializeFaqs();
    _updateFilteredFaqs(); // 初始加载所有 FAQs
  }

  // ( ✨ 新增 ✨ ) 根据角色设置 FAQs
  void _initializeFaqs() {
    // 1. 每个人都能看到的通用问题
    final List<Map<String, String>> baseFaqs = [
      {
        'question': 'How do I contact support?',
        'answer':
            'You can use the chat assistant above or send us feedback below. Our team monitors these channels closely.'
      },
    ];

    // 2. 仅用户可见的问题
    final List<Map<String, String>> userFaqs = [
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
    ];

    // 3. 仅供应商可见的问题
    final List<Map<String, String>> vendorFaqs = [
      {
        'question': 'How do I see my earnings?',
        'answer':
            'Your earnings summary is available on the main Dashboard. For detailed reports, visit the Analytics page.'
      },
      {
        'question': 'How do I update my store hours?',
        'answer':
            'Navigate to More > Account Settings > Edit Store Details. You can update your operating hours there.'
      },
      {
        'question': 'What are the photo requirements for products?',
        'answer':
            'Photos should be well-lit, clear, and show the product accurately. Minimum 800x800 pixels is recommended.'
      },
      {
        'question': 'How do promotions work?',
        'answer':
            'You can create % discounts for "Blindbox" or "Grocery" items in the "Promotions" tab. These will be shown to customers.'
      },
    ];

    // 4. 根据角色组合列表
    if (widget.userRole == 'Vendor') {
      _allFaqs = [...baseFaqs, ...vendorFaqs];
    } else {
      // 默认为 'User'
      _allFaqs = [...baseFaqs, ...userFaqs];
    }
  }

  // ( ✨ 新增 ✨ ) 更新过滤后的 FAQ 列表
  void _updateFilteredFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query; // (保持搜索词状态)
      if (query.isEmpty) {
        _filteredFaqs = _allFaqs;
      } else {
        _filteredFaqs = _allFaqs
            .where((faq) =>
                faq['question']!.toLowerCase().contains(query) ||
                faq['answer']!.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // ... (聊天机器人函数 _sendMessage, _generateBotReply 保持不变) ...
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

  // --- ( ✨ 新增函数：提交反馈 ✨ ) ---
  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    setState(() => _isSubmittingFeedback = true);

    try {
      // 使用 repository 提交
      await _feedbackRepo.submitFeedback(
        message: feedback,
        role: widget.userRole, // 传递当前用户的角色
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks for your feedback!'),
            backgroundColor: kSecondaryAccentColor, // (假设你有这个颜色)
          ),
        );
      }
      _feedbackController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback: $e'),
            backgroundColor: kPrimaryActionColor, // (假设你有这个颜色)
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingFeedback = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ( ✨ 已修改 ✨ )
    // 不再在 build 方法中计算
    // final filteredFaqs = ...

    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        // ... (不变) ...
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
          // --- Chatbot Assistant (不变) ---
          const Text('Assistant', style: kLabelTextStyle),
          const SizedBox(height: 10),
          ...messages.map((msg) {
            // ... (不变)
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
            // ... (不变)
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
            // ( ✨ 已修改 ✨ )
            onChanged: (value) => _updateFilteredFaqs(),
            decoration: InputDecoration(
              hintText: 'Type a question...',
              // ... (不变)
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
          // ( ✨ 已修改 ✨ )
          // 使用新的状态变量 _filteredFaqs
          ..._filteredFaqs.map((faq) => ExpansionTile(
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
              // ... (不变)
              filled: true,
              fillColor: kCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kYellowMedium, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // --- ( ✨ 已修改 ✨ ) ---
          ElevatedButton(
            onPressed: _isSubmittingFeedback ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: kYellowSoft,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isSubmittingFeedback
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: kTextColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Submit', style: TextStyle(color: kTextColor)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
