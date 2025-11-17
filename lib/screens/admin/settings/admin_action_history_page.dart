import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AdminActionHistoryPage extends StatefulWidget {
  const AdminActionHistoryPage({super.key});

  @override
  State<AdminActionHistoryPage> createState() => _AdminActionHistoryPageState();
}

class _AdminActionHistoryPageState extends State<AdminActionHistoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // --- UI Addition: Color Mapping for Actions ---
  final Map<String, Color> actionColors = {
    'Approved': Colors.green.shade600,
    'Rejected': Colors.red.shade600,
    'Deleted': Colors.red.shade900,
    'Warning': Colors.orange.shade600,
    'Action': Colors.blue.shade600, // Default color
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Firestore query for review logs only (where reviewId exists)
  Query _buildQuery() {
    return FirebaseFirestore.instance
        .collection('moderationLogs')
        .where('reviewId', isNotEqualTo: null); // only review actions
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    // Logic is kept the same
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy')
        .format(dt); // Slightly adjusted format for display
  }

  bool _matchesSearch(Map<String, dynamic> log) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery;
    final action = (log['action'] ?? '').toString().toLowerCase();
    final reason = (log['reason'] ?? '').toString().toLowerCase();
    final admin = (log['adminId'] ?? '').toString().toLowerCase();
    final reviewId = (log['reviewId'] ?? '').toString().toLowerCase();
    return action.contains(q) ||
        reason.contains(q) ||
        admin.contains(q) ||
        reviewId.contains(q);
  }

  Future<void> _copyToClipboard(String text, BuildContext ctx) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();

    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1, // Subtle shadow
        shadowColor: Colors.grey.shade200,
        centerTitle: true,
        title: const Text(
          'Review Action History',
          style:
              TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar + refresh (Modernized Container)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48, // Taller for modern look
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // Softer corners
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade100,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey.shade500),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search action, reason, admin or ID...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: const TextStyle(color: Color(0xFF1F2937)),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
                            child:
                                Icon(Icons.clear, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Refresh Button (Modernized)
                InkWell(
                  onTap: () => setState(() {}),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.refresh,
                        size: 22, color: Colors.blue.shade600),
                  ),
                ),
              ],
            ),
          ),

          // List area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final logs = docs
                    .map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return {
                        'id': d.id,
                        'adminId': data['adminId'],
                        'action': data['action'],
                        'reason': data['reason'],
                        'reviewId': data['reviewId'],
                        'timestamp': data['timestamp'],
                      };
                    })
                    .where((l) => _matchesSearch(l))
                    .toList();

                // Logic kept: Sort locally by timestamp descending
                logs.sort((a, b) {
                  final tsA = a['timestamp'] as Timestamp?;
                  final tsB = b['timestamp'] as Timestamp?;
                  if (tsA == null && tsB == null) return 0;
                  if (tsA == null) return 1;
                  if (tsB == null) return -1;
                  return tsB.compareTo(tsA);
                });

                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reviews,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No review actions found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.blue.shade600,
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final ts = log['timestamp'] as Timestamp?;
                      final action = log['action'] ?? 'Action';
                      final admin = log['adminId'] ?? '-';
                      final reviewId = log['reviewId'] ?? '-';

                      // Get color based on action type
                      final actionColor =
                          actionColors[action] ?? actionColors['Action']!;

                      return Card(
                        // **MODIFIED:** Increased elevation for a better "pop" effect
                        elevation: 8,
                        // **MODIFIED:** Darker shadow color to make the lift more noticeable
                        shadowColor: Colors.grey.shade400.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            // **MODIFIED:** Added a subtle border for definition
                            side: BorderSide(
                                color: Colors.grey.shade200, width: 1)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showLogDetails(context, log),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Action Title with Color Dot
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: actionColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(action,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: actionColor)),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Admin and Timestamp Row
                                Row(
                                  children: [
                                    Icon(Icons.account_circle,
                                        size: 16, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    // Admin ID
                                    Expanded(
                                      child: Text(
                                        admin,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),

                                    // Timestamp
                                    Icon(Icons.schedule,
                                        size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(_formatDate(ts),
                                        style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontSize: 12)),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // Review ID Row
                                Row(
                                  children: [
                                    Icon(Icons.vpn_key_rounded,
                                        size: 16, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Review ID: ',
                                      style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontSize: 12),
                                    ),
                                    Expanded(
                                      child: Text(reviewId,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Details Dialog (Modernized) ---
  void _showLogDetails(BuildContext ctx, Map<String, dynamic> log) {
    final ts = log['timestamp'] as Timestamp?;
    final dt = ts?.toDate();
    final action = log['action'] ?? 'Action';
    final actionColor = actionColors[action] ?? actionColors['Action']!;

    // Helper function for formatted row display (UI only)
    Widget _dialogDetailRow(String label, String value,
        {bool isCopyable = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade600),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      value,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1F2937)),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (isCopyable && value != '-')
                  IconButton(
                    icon:
                        Icon(Icons.copy, size: 18, color: Colors.blue.shade600),
                    onPressed: () => _copyToClipboard(value, ctx),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 12, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(action,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: actionColor)),
            // Replaced the default close icon with a modern IconButton
            IconButton(
              icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Using the helper for cleaner layout
            _dialogDetailRow('Admin ID', log['adminId'] ?? '-'),
            _dialogDetailRow('Review ID', log['reviewId'] ?? '-',
                isCopyable: true),
            _dialogDetailRow(
                'Timestamp',
                dt != null
                    ? DateFormat('yyyy-MM-dd HH:mm:ss').format(dt)
                    : '-'),
            // Note: The original logic had a separate button for copying reason,
            // which I've integrated into the row's copyable function for better UX.
            _dialogDetailRow('Reason', log['reason'] ?? 'No reason provided.',
                isCopyable: true),
          ],
        ),
        actions: [
          // Close button (Styled as primary button)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
