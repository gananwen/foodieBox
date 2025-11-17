import 'package:flutter/material.dart';
import '../../util/styles.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // Sample filter states
  final Map<String, bool> categoryFilters = {
    'Eggs': true,
    'Noodles & Pasta': false,
    'Chips & Crisps': false,
    'Fast Food': false,
  };

  final Map<String, bool> brandFilters = {
    'Individual Collection': false,
    'Cocola': true,
    'Ifad': false,
    'Kazi Farmas': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Filters', style: TextStyle(color: kTextColor)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categories', style: kLabelTextStyle),
            const SizedBox(height: 10),
            ...categoryFilters.keys.map((key) => _buildCheckboxTile(
                  label: key,
                  value: categoryFilters[key]!,
                  onChanged: (val) {
                    setState(() => categoryFilters[key] = val);
                  },
                )),
            const SizedBox(height: 20),
            const Text('Brand', style: kLabelTextStyle),
            const SizedBox(height: 10),
            ...brandFilters.keys.map((key) => _buildCheckboxTile(
                  label: key,
                  value: brandFilters[key]!,
                  onChanged: (val) {
                    setState(() => brandFilters[key] = val);
                  },
                )),
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kYellowSoft,
                  foregroundColor: kTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // TODO: Apply filter logic
                  Navigator.pop(context);
                },
                child: const Text('Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value ? kYellowMedium : Colors.grey.shade300, width: 1.2),
      ),
      child: CheckboxListTile(
        title: Text(label, style: TextStyle(color: kTextColor)),
        value: value,
        activeColor: kYellowMedium,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (val) => onChanged(val!),
      ),
    );
  }
}
