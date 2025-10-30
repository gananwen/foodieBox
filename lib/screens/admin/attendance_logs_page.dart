import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// Dummy attendance data
class AttendanceRecord {
  final DateTime date;
  final String status; // Present, Late, On Leave

  AttendanceRecord(this.date, this.status);
}

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  List<AttendanceRecord> records = [
    AttendanceRecord(DateTime(2025, 10, 1), 'Present'),
    AttendanceRecord(DateTime(2025, 10, 2), 'Late'),
    AttendanceRecord(DateTime(2025, 10, 3), 'On Leave'),
    AttendanceRecord(DateTime(2025, 10, 4), 'Present'),
    AttendanceRecord(DateTime(2025, 10, 5), 'Present'),
  ];

  String filter = 'All';
  DateTime? selectedDay;

  Map<String, Color> statusColors = {
    'Present': Colors.green,
    'Late': Colors.orange,
    'On Leave': Colors.red,
  };

  // Group attendance by date for calendar markers
  Map<DateTime, List<AttendanceRecord>> get attendanceByDate {
    Map<DateTime, List<AttendanceRecord>> map = {};
    for (var record in records) {
      final day =
          DateTime(record.date.year, record.date.month, record.date.day);
      if (!map.containsKey(day)) {
        map[day] = [];
      }
      map[day]!.add(record);
    }
    return map;
  }

  // Returns markers (colored dots) for a day
  List<Widget> _buildMarkers(DateTime day) {
    final dayRecords = attendanceByDate[DateTime(day.year, day.month, day.day)];
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

  @override
  Widget build(BuildContext context) {
    // Filter records by status and date
    List<AttendanceRecord> filteredRecords = records.where((r) {
      bool statusMatch = filter == 'All' || r.status == filter;
      bool dateMatch = selectedDay == null ||
          (r.date.year == selectedDay!.year &&
              r.date.month == selectedDay!.month &&
              r.date.day == selectedDay!.day);
      return statusMatch && dateMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance & Logs'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Calendar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TableCalendar(
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
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                        color: Colors.blue, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(
                        color: Colors.deepPurple, shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
                // Clear Date Filter Button
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
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black),
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
          // Attendance List
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
      ),
    );
  }
}
