import 'dart:async';
import 'package:flutter/material.dart';

class FirestoreBackupSimulator extends StatefulWidget {
  const FirestoreBackupSimulator({super.key});

  @override
  State<FirestoreBackupSimulator> createState() =>
      _FirestoreBackupSimulatorState();
}

class _FirestoreBackupSimulatorState extends State<FirestoreBackupSimulator> {
  double _progress = 0;
  bool _isBackingUp = false;
  bool _backupCompleted = false;
  List<String> _backupLog = [];

  // ⭐️ Defined Internal Styles for Modern Look ⭐️
  static const Color _kPrimaryColor = Color(0xFF42A5F5); // Bright Blue
  static const Color _kAccentColor = Color.fromARGB(255, 114, 158, 199);
  static const Color _kAppBackgroundColor =
      Color(0xFFF0F4F8); // Very light gray/off-white
  static const Color _kCardColor = Colors.white;
  // ⭐️ END OF INTERNAL STYLES ⭐️

  // Fake Firestore collections for simulation
  final List<Map<String, dynamic>> _collections = [
    {'name': 'users', 'count': 125},
    {'name': 'vendors', 'count': 42},
    {'name': 'reviews', 'count': 350},
    {'name': 'orders', 'count': 200},
    {'name': 'promotions', 'count': 18},
    {'name': 'feedback', 'count': 65},
    {'name': 'notifications', 'count': 90},
  ];

  void _startBackupSimulation() {
    setState(() {
      _isBackingUp = true;
      _backupCompleted = false;
      _progress = 0;
      _backupLog.clear();
      _backupLog.add('STARTING: Initializing Cloud Storage connection...');
    });

    int collectionIndex = 0;
    // Shorter interval for faster simulation feel
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isBackingUp) {
        // Safety check if user cancels or navigates away
        timer.cancel();
        return;
      }

      if (collectionIndex < _collections.length) {
        final col = _collections[collectionIndex];
        _backupLog.insert(0,
            '✅ Backing up "${col['name']}" (${col['count']} records)'); // Insert at front for LIFO log
        _progress = (collectionIndex + 1) / _collections.length;
        collectionIndex++;
        setState(() {});
      } else {
        timer.cancel();
        _backupLog.insert(0, 'COMPLETE: Backup successful.');
        _backupLog.insert(0, '--- Summary ---');
        setState(() {
          _isBackingUp = false;
          _backupCompleted = true;
          _progress = 1;
        });
      }
    });
  }

  /// 🔹 Widget to show status and collections list
  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Database Collections Status',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kAppBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _collections.map((col) {
              final isBackedUp = _backupLog.any(
                  (log) => log.contains(col['name']) && log.startsWith('✅'));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Icon(
                      isBackedUp
                          ? Icons.check_circle
                          : Icons.data_usage_outlined,
                      color: isBackedUp
                          ? Colors.green.shade600
                          : Colors.grey.shade500,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      col['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isBackedUp
                              ? Colors.black87
                              : Colors.grey.shade600),
                    ),
                    const Spacer(),
                    Text(
                      '${col['count']} records',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 🔹 Widget to display the log output
  Widget _buildLogOutput() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark terminal background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ListView.builder(
        reverse:
            true, // Show newest log entry at the bottom/top of the visible area
        itemCount: _backupLog.length,
        itemBuilder: (context, index) {
          final log = _backupLog[index];
          Color logColor = Colors.white70;
          if (log.startsWith('✅')) {
            logColor = Colors.greenAccent;
          } else if (log.startsWith('COMPLETE')) {
            logColor = _kPrimaryColor;
          } else if (log.startsWith('STARTING')) {
            logColor = Colors.yellow;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              log,
              style: TextStyle(
                  fontSize: 13, fontFamily: 'monospace', color: logColor),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Cloud Data Backup',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _kAccentColor, // Deep Purple
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Status Overview Card
            Card(
              color: _kCardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)), // More rounded
              elevation: 6, // Increased elevation for depth
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Progress/Status Display ---
                    if (_isBackingUp)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔄 Backup In Progress...',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kAccentColor),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10, // Thicker bar
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation(
                                _kPrimaryColor), // Bright Blue
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Progress:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600)),
                              Text('${(_progress * 100).toInt()}% completed',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),

                    // --- Initial/Ready State ---
                    if (!_isBackingUp && !_backupCompleted)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ready to Start Backup',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'Securely backup ${_collections.length} critical data collections.',
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.cloud_upload_outlined,
                                  color: Colors.white),
                              label: const Text(
                                'START FULL BACKUP',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimaryColor, // Bright Blue
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              onPressed: _startBackupSimulation,
                            ),
                          ),
                        ],
                      ),

                    // --- Completed State ---
                    if (_backupCompleted)
                      Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green.shade600, size: 64),
                          const SizedBox(height: 16),
                          const Text('Backup Completed Successfully!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              label: const Text(
                                'RUN BACKUP AGAIN',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kAccentColor, // Deep Purple
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              onPressed: _startBackupSimulation,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Collections Status Section
            _buildStatusSection(),

            const SizedBox(height: 20),

            // 3. Log Output Section
            const Text(
              'Live Backup Log',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildLogOutput(),
          ],
        ),
      ),
    );
  }
}
