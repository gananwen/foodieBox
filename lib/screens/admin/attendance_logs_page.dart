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
  bool _calendarExpanded = true;

  final Map<String, Color> statusColors = {
    'Present': Colors.green.shade600,
    'Late': Colors.orange.shade600,
    'On Leave': Colors.red.shade600,
  };

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white, // Main Scaffold background set to white
      appBar: AppBar(
        title: const Text('Attendance & Logs'),
        centerTitle: true,
        backgroundColor: Colors.white, // AppBar background white
        elevation: 1, // Subtle shadow for the AppBar
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

          // Summary counts (logic unchanged)
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
                margin: const EdgeInsets.symmetric(horizontal: 1.0),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Calendar Section Header ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Attendance Calendar',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)),
                    ),
                    IconButton(
                      icon: Icon(
                        _calendarExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.blue.shade600,
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

              // --- Collapsible Calendar ---
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // INCREASED HEIGHT HERE for better visibility
                height: _calendarExpanded ? 420 : 0,
                curve: Curves.easeInOut,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation:
                          6, // More prominent elevation for the calendar card
                      shadowColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Inner padding for calendar
                        child: TableCalendar(
                          firstDay: DateTime(2025, 1, 1),
                          lastDay: DateTime(2025, 12, 31),
                          focusedDay: selectedDay ?? DateTime.now(),
                          currentDay: DateTime.now(), // Highlight current day
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
                                selectedDay =
                                    null; // Deselect if already selected
                              } else {
                                selectedDay = selected;
                              }
                            });
                          },
                          calendarFormat: _calendarExpanded
                              ? CalendarFormat.month
                              : CalendarFormat
                                  .week, // Adjust format based on expansion
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.week: 'Week',
                          },
                          // UI Styling
                          calendarBuilders: CalendarBuilders(
                            // Default builder to ensure day number is visible
                            defaultBuilder: (context, day, focusedDay) {
                              return Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              );
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors
                                      .blue.shade100, // Lighter blue for today
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.blue
                                      .shade600, // Vibrant blue for selected
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                            markerBuilder: (context, day, events) {
                              final markers = _buildMarkers(day);
                              if (markers.isEmpty)
                                return const SizedBox.shrink();
                              return Positioned(
                                bottom: 4, // Adjusted position
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: markers,
                                ),
                              );
                            },
                          ),
                          calendarStyle: CalendarStyle(
                            // This handles the weekend text styling properly
                            weekendTextStyle:
                                TextStyle(color: Colors.red.shade400),
                            outsideDaysVisible: false,
                            cellPadding: const EdgeInsets.all(
                                4.0), // Padding inside cells
                            todayDecoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                shape: BoxShape.circle),
                            selectedDecoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle),
                            selectedTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            // Hide default markers since we have custom ones
                            markerDecoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1F2937)),
                            leftChevronIcon: Icon(Icons.chevron_left_rounded,
                                color: Colors.blue.shade600, size: 28),
                            rightChevronIcon: Icon(Icons.chevron_right_rounded,
                                color: Colors.blue.shade600, size: 28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (selectedDay != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700),
                    onPressed: () {
                      setState(() {
                        selectedDay = null;
                      });
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Clear selected date'),
                  ),
                ),

              const SizedBox(height: 16),

              // --- Summary Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

              const SizedBox(height: 24), // Increased space

              // --- Filter Chips Section ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Filter by Status',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937))),
              ),
              const SizedBox(height: 8),

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
                        backgroundColor: Colors
                            .grey.shade100, // Lighter unselected background
                        labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade800,
                            fontWeight: FontWeight.w500),
                        onSelected: (_) {
                          setState(() {
                            filter = f;
                          });
                        },
                        // Styling for the chip's shape
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: isSelected
                                    ? Colors.blue.shade600
                                    : Colors.grey.shade300)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24), // Increased space

              // --- Attendance List Title ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  selectedDay != null
                      ? 'Logs for ${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}'
                      : 'Recent Attendance Logs',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937)),
                ),
              ),
              const SizedBox(height: 12),

              // --- Attendance List ---
              Expanded(
                child: filteredRecords.isEmpty
                    ? Center(
                        child: Text(
                            selectedDay != null
                                ? 'No records found for ${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')}'
                                : 'No attendance records found for this filter.',
                            style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            elevation: 2, // Subtle elevation
                            shadowColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 10),
                            color: const Color.fromARGB(255, 247, 246, 246),
                            child: ListTile(
                              // Date icon improved
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: statusColors[record.status]!
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  record.date.day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                      color: statusColors[record.status],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                  '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151))),
                              subtitle: Text(
                                'Time: ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 13),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColors[record.status]!
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  record.status,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
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

  // Helper widget for summary badges (updated styling)
  Widget _summaryBadge(String label, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 3, // More distinct elevation
        shadowColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin:
            const EdgeInsets.symmetric(horizontal: 6), // Add horizontal margin
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // UI for _showAddAttendanceDialog
  // =========================================================================
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
            elevation: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Attendance Record',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 20),
                  // Date Selection Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                            color: newDate == null
                                ? Colors.red.shade300
                                : Colors.blue.shade600),
                        foregroundColor: newDate == null
                            ? Colors.red.shade600
                            : Colors.blue.shade800,
                      ),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(newDate != null
                          ? '${newDate!.year}-${newDate!.month.toString().padLeft(2, '0')}-${newDate!.day.toString().padLeft(2, '0')}'
                          : 'Select Date *'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2025, 1, 1),
                          lastDate: DateTime(2025, 12, 31),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors
                                      .blue.shade600, // Header background color
                                  onPrimary: Colors.white, // Header text color
                                  onSurface: Colors.black, // Body text color
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null)
                          setStateDialog(() => newDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: newStatus,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: ['Present', 'Late', 'On Leave']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status,
                                      style: TextStyle(
                                          color: statusColors[status])),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setStateDialog(() => newStatus = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (newDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a date.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

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
                                  content:
                                      Text('Attendance added successfully!'),
                                  backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to add attendance: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: const Text('Add',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
