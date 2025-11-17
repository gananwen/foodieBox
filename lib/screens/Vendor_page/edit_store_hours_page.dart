// 路径: lib/pages/vendor_home/edit_store_hours_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vendor.dart';
import '../../repositories/vendor_data_repository.dart';
import '../../util/styles.dart';

class EditStoreHoursPage extends StatefulWidget {
  final VendorModel vendor;
  const EditStoreHoursPage({super.key, required this.vendor});

  @override
  State<EditStoreHoursPage> createState() => _EditStoreHoursPageState();
}

class _EditStoreHoursPageState extends State<EditStoreHoursPage> {
  final VendorDataRepository _repo = VendorDataRepository();
  bool _isLoading = false;

  // 1. We will store the hours in a map for easy editing
  final Map<String, String> _hours = {
    'Monday': 'Closed',
    'Tuesday': 'Closed',
    'Wednesday': 'Closed',
    'Thursday': 'Closed',
    'Friday': 'Closed',
    'Saturday': 'Closed',
    'Sunday': 'Closed',
  };

  // 2. Helper to map full day names to short names (e.g., "Mon")
  final Map<String, String> _dayMap = {
    'Monday': 'Mon',
    'Tuesday': 'Tue',
    'Wednesday': 'Wed',
    'Thursday': 'Thu',
    'Friday': 'Fri',
    'Saturday': 'Sat',
    'Sunday': 'Sun',
  };

  @override
  void initState() {
    super.initState();
    _parseHours();
  }

  // 3. This function reads the List<String> from your vendor model
  //    and converts it into our easy-to-use map.
  void _parseHours() {
    for (String entry in widget.vendor.storeHours) {
      try {
        final parts = entry.split(': ');
        if (parts.length == 2) {
          final shortDay = parts[0]; // e.g., "Mon"
          final time = parts[1]; // e.g., "9:00 AM - 5:00 PM"

          // Find the full day name (e.g., "Monday") that matches the short day
          final fullDay = _dayMap.entries
              .firstWhere((mapEntry) => mapEntry.value == shortDay)
              .key;

          if (fullDay.isNotEmpty) {
            setState(() {
              _hours[fullDay] = time;
            });
          }
        }
      } catch (e) {
        print('Error parsing store hour entry: $entry');
      }
    }
  }

  // 4. This shows the dialog to pick times
  Future<void> _showEditHoursDialog(String day) async {
    TimeOfDay? fromTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? toTime = const TimeOfDay(hour: 17, minute: 0);

    // This nested function shows the time picker
    Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initialTime) {
      return showTimePicker(
        context: context,
        initialTime: initialTime,
      );
    }

    // This shows the main dialog
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text('Set Hours for $day',
              style: const TextStyle(color: kTextColor)),
          content: Text('Set opening and closing times.',
              style: TextStyle(color: kTextColor.withOpacity(0.7))),
          actions: [
            TextButton(
              child: const Text('Set as Closed',
                  style: TextStyle(color: kPrimaryActionColor)),
              onPressed: () {
                setState(() {
                  _hours[day] = 'Closed';
                });
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: kTextColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryAccentColor),
              child:
                  const Text('Set Time', style: TextStyle(color: kTextColor)),
              onPressed: () async {
                // Pick "From" time
                final from = await _pickTime(dialogContext,
                    fromTime ?? const TimeOfDay(hour: 9, minute: 0));
                if (from == null) return; // User cancelled

                // Pick "To" time
                final to = await _pickTime(dialogContext,
                    toTime ?? const TimeOfDay(hour: 17, minute: 0));
                if (to == null) return; // User cancelled

                // Format and save
                final String fromFormatted = from.format(context);
                final String toFormatted = to.format(context);

                setState(() {
                  _hours[day] = '$fromFormatted - $toFormatted';
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 5. This function saves the data back to Firebase
  Future<void> _saveHours() async {
    setState(() => _isLoading = true);

    // Convert our map back into the List<String> format
    // e.g., ["Mon: 9:00 AM - 5:00 PM", "Tue: Closed", ...]
    final List<String> newHoursList = [];
    _hours.forEach((fullDay, time) {
      final String shortDay = _dayMap[fullDay]!; // "Monday" -> "Mon"
      newHoursList.add('$shortDay: $time');
    });

    try {
      // This function must be added to your repository
      await _repo.updateStoreHours(newHoursList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store hours updated!'),
            backgroundColor: kSecondaryAccentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: kPrimaryActionColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Store Hours'),
        backgroundColor: kAppBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Save Button
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kTextColor)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined, color: kTextColor),
              onPressed: _saveHours,
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        itemCount: _hours.length,
        itemBuilder: (context, index) {
          final String day = _hours.keys.elementAt(index);
          final String time = _hours[day]!;
          final bool isClosed = time == 'Closed';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: kCardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: kTextColor.withAlpha(26), width: 1.5),
            ),
            child: ListTile(
              title: Text(
                day,
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                time,
                style: TextStyle(
                  color: isClosed
                      ? kPrimaryActionColor.withAlpha(200)
                      : kTextColor.withAlpha(153),
                  fontWeight: isClosed ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing:
                  const Icon(Icons.edit_outlined, color: kTextColor, size: 20),
              onTap: () => _showEditHoursDialog(day),
            ),
          );
        },
      ),
    );
  }
}
