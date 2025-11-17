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

class _AttendanceLogsPageState extends State<AttendanceLogsPage>
    with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String filter = 'All';
  DateTime? selectedDay;
  bool _calendarExpanded = true;

  final Map<String, Color> statusColors = {
    'Present': Colors.green,
    'Late': Colors.orange,
    'On Leave': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Attendance & Logs'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
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
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: statusColors[record.status],
                  shape: BoxShape.circle,
                ),
              );
            }).toList();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance Calendar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(
                          _calendarExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() {
                            _calendarExpanded = !_calendarExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // CALENDAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _calendarExpanded
                            ? TableCalendar(
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
                                calendarFormat: CalendarFormat.month,
                                daysOfWeekHeight: 20,
                                rowHeight: 32,
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder: (context, day, focusedDay) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          "${day.day}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Positioned(
                                          bottom: 2,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: _buildMarkers(day),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

                if (selectedDay != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: TextButton.icon(
                      onPressed: () => setState(() => selectedDay = null),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Clear selected date',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),

                const SizedBox(height: 16),

                // SUMMARY BADGES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryBadge(
                          'Present', presentCount, statusColors['Present']!),
                      _summaryBadge('Late', lateCount, statusColors['Late']!),
                      _summaryBadge(
                          'On Leave', onLeaveCount, statusColors['On Leave']!),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // FILTER CHIPS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Present', 'Late', 'On Leave'].map((f) {
                        bool isSelected = f == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label:
                                Text(f, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (_) => setState(() => filter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    selectedDay != null
                        ? 'Logs for ${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}'
                        : 'Recent Attendance Logs',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 400,
                  child: filteredRecords.isEmpty
                      ? Center(
                          child: Text(
                            selectedDay != null
                                ? 'No records found for selected date.'
                                : 'No attendance records found.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredRecords.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final record = filteredRecords[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Colors.grey.shade100,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: statusColors[record.status]!
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    record.date.day.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                        color: statusColors[record.status],
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  '${record.date.day}/${record.date.month}/${record.date.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xFF374151)),
                                ),
                                subtitle: Text(
                                  'Time: ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColors[record.status]!
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    record.status,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // SUMMARY BADGES
  Widget _summaryBadge(String label, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ADD ATTENDANCE DIALOG
  void _showAddAttendanceDialog(String uid) {
    DateTime? newDate;
    String newStatus = 'Present';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add Attendance Record',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        newDate == null
                            ? 'Select Date'
                            : '${newDate!.year}-${newDate!.month}-${newDate!.day}',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2025, 1, 1),
                        lastDate: DateTime(2025, 12, 31),
                      );
                      if (picked != null) {
                        setStateDialog(() => newDate = picked);
                      }
                    },
                  ),
                  DropdownButton<String>(
                    value: newStatus,
                    items: ['Present', 'Late', 'On Leave']
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child:
                                Text(s, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => newStatus = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(fontSize: 12))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (newDate == null) return;

                          await _firestore
                              .collection('admins')
                              .doc(uid)
                              .collection('attendanceLogs')
                              .add({
                            'date': Timestamp.fromDate(newDate!),
                            'status': newStatus,
                          });

                          Navigator.pop(context);
                        },
                        child:
                            const Text('Add', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
