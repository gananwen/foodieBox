import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceRecord {
  final DateTime date;
  final String status;
  AttendanceRecord(this.date, this.status);
}

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String filter = 'All';
  DateTime? selectedDay;

  final Map<String, Color> statusColors = {
    'Present': Colors.green.shade400,
    'Late': Colors.orange.shade400,
    'On Leave': Colors.red.shade400,
  };

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance & Logs'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Attendance',
            onPressed: () => _showAddAttendanceDialog(user.uid),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('admins')
            .doc(user.uid)
            .collection('attendanceLogs')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return AttendanceRecord(
              (data['date'] as Timestamp).toDate(),
              data['status'] ?? 'Present',
            );
          }).toList();

          final Map<DateTime, List<AttendanceRecord>> attendanceByDate = {};
          for (var record in records) {
            final day =
                DateTime(record.date.year, record.date.month, record.date.day);
            attendanceByDate.putIfAbsent(day, () => []).add(record);
          }

          List<AttendanceRecord> filteredRecords = records.where((r) {
            bool statusMatch = filter == 'All' || r.status == filter;
            bool dateMatch = selectedDay == null ||
                (r.date.year == selectedDay!.year &&
                    r.date.month == selectedDay!.month &&
                    r.date.day == selectedDay!.day);
            return statusMatch && dateMatch;
          }).toList();

          // Summary counts
          int presentCount = records.where((r) => r.status == 'Present').length;
          int lateCount = records.where((r) => r.status == 'Late').length;
          int onLeaveCount =
              records.where((r) => r.status == 'On Leave').length;

          List<Widget> _buildMarkers(DateTime day) {
            final dayRecords =
                attendanceByDate[DateTime(day.year, day.month, day.day)];
            if (dayRecords == null) return [];
            return dayRecords.map((record) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColors[record.status],
                  shape: BoxShape.circle,
                ),
              );
            }).toList();
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TableCalendar(
                  firstDay: DateTime(2025, 1, 1),
                  lastDay: DateTime(2025, 12, 31),
                  focusedDay: selectedDay ?? DateTime.now(),
                  selectedDayPredicate: (day) =>
                      selectedDay != null &&
                      day.year == selectedDay!.year &&
                      day.month == selectedDay!.month &&
                      day.day == selectedDay!.day,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      if (selectedDay != null &&
                          selected.year == selectedDay!.year &&
                          selected.month == selectedDay!.month &&
                          selected.day == selectedDay!.day) {
                        selectedDay = null;
                      } else {
                        selectedDay = selected;
                      }
                    });
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      final markers = _buildMarkers(day);
                      if (markers.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: markers,
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                        color: Colors.blue.shade200, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple.shade300,
                        shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              if (selectedDay != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      selectedDay = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Show All Dates'),
                ),
              const SizedBox(height: 16),
              // Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryBadge(
                        'Present', presentCount, Colors.green.shade400),
                    _summaryBadge('Late', lateCount, Colors.orange.shade400),
                    _summaryBadge(
                        'On Leave', onLeaveCount, Colors.red.shade400),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['All', 'Present', 'Late', 'On Leave'].map((f) {
                    bool isSelected = f == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: isSelected,
                        selectedColor: Colors.blue.shade600,
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500),
                        onSelected: (_) {
                          setState(() {
                            filter = f;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredRecords.isEmpty
                    ? const Center(child: Text('No records found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.grey.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColors[record.status],
                                child: Text(
                                  record.status[0],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                  '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColors[record.status],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.status,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // ================= ADD ATTENDANCE =================
  void _showAddAttendanceDialog(String uid) {
    DateTime? newDate;
    String newStatus = 'Present';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Attendance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Picker
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(newDate != null
                      ? '${newDate!.year}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}'
                      : 'Select Date'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime(2025, 12, 31),
                    );
                    if (picked != null) setStateDialog(() => newDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                // Status Dropdown
                DropdownButton<String>(
                  value: newStatus,
                  items: ['Present', 'Late', 'On Leave']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => newStatus = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newDate == null) return;

                  try {
                    await _firestore
                        .collection('admins')
                        .doc(uid)
                        .collection('attendanceLogs')
                        .add({
                      'date': Timestamp.fromDate(newDate!),
                      'status': newStatus,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Attendance added successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add attendance: $e')),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }
}
