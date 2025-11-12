import 'package:flutter/material.dart';
import '../../widgets/base_page.dart';
import '../../util/styles.dart'; // Your custom styles

class StoreDetailPage extends StatefulWidget {
  final Map<String, dynamic> store;

  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  String selectedDay = 'Tomorrow';
  String selectedTime = '10:00 AM – 11:00 AM';

  final List<String> todaySlots = [
    '10:00 AM – 11:00 AM',
    '11:00 AM – 12:00 PM',
    '12:00 PM – 1:00 PM',
    '1:00 PM – 2:00 PM',
  ];

  final List<String> tomorrowSlots = [
    '10:00 AM – 11:00 AM',
    '11:00 AM – 12:00 PM',
    '12:00 PM – 1:00 PM',
    '1:00 PM – 2:00 PM',
    '2:00 PM – 3:00 PM',
    '3:00 PM – 4:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

    return BasePage(
      currentIndex: 2,
      child: Container(
        color: kCardColor,
        padding: const EdgeInsets.only(bottom: 80),
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Grocery Info ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      store['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store['name'], style: kLabelTextStyle),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(store['location'], style: const TextStyle(fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text('${store['rating']}'),
                            const SizedBox(width: 8),
                            Text(store['distance'], style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kSecondaryAccentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Free delivery',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Nearest Delivery Time ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _showDeliveryTimeSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: kYellowLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.black54),
                      const SizedBox(width: 8),
                      Text('$selectedDay, $selectedTime', style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeliveryTimeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        String localDay = selectedDay;
        String localTime = selectedTime;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final slots = localDay == 'Today' ? todaySlots : tomorrowSlots;

            return FractionallySizedBox(
              heightFactor: 0.5,
              child: Container(
                color: kCardColor,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Title + Calendar Icon ---
                    Row(
                      children: [
                        const Text('Choose a Time', style: kLabelTextStyle),
                        const Spacer(),
                        Image.asset('assets/images/calendar.png', width: 24),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Day Tabs ---
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => localDay = 'Today'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: kAppBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('Today',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: localDay == 'Today' ? kTextColor : Colors.grey,
                                    )),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => localDay = 'Tomorrow'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: kAppBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text('Tomorrow',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: localDay == 'Tomorrow' ? kTextColor : Colors.grey,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Time Slots ---
                    Expanded(
                      child: ListView(
                        children: slots.map((slot) {
                          final isSelected = localTime == slot;
                          return ListTile(
                            title: Text(slot),
                            trailing: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? kYellowGold : Colors.grey,
                            ),
                            onTap: () => setModalState(() => localTime = slot),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- Confirm Button ---
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedDay = localDay;
                          selectedTime = localTime;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kYellowMedium,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Center(
                        child: Text('Confirm', style: TextStyle(color: kTextColor)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
