import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VoucherFormScreen extends StatefulWidget {
  final Map<String, dynamic>? voucher;
  final VoidCallback? onSaved;

  const VoucherFormScreen({Key? key, this.voucher, this.onSaved})
      : super(key: key);

  @override
  State<VoucherFormScreen> createState() => _VoucherFormScreenState();
}

class _VoucherFormScreenState extends State<VoucherFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descController;
  late TextEditingController _discountValueController;
  late TextEditingController _minSpendController;

  bool _active = false;
  bool _firstTimeOnly = false;
  bool _weekendOnly = false;

  String _discountType = 'percentage';
  String _applicableOrderType = 'All';
  String _applicableVendorType = 'all';

  DateTime? _startDate;
  DateTime? _endDate;

  final _discountTypes = ['percentage', 'fixed'];
  final _vendorTypes = ['all', 'pickup', 'delivery'];
  final _orderTypes = ['BlindBox', 'Grocery', 'All'];

  @override
  void initState() {
    super.initState();
    final v = widget.voucher;

    _nameController = TextEditingController(text: v?['name']);
    _codeController = TextEditingController(text: v?['code']);
    _descController = TextEditingController(text: v?['description']);
    _discountValueController =
        TextEditingController(text: v?['discountValue']?.toString() ?? '');
    _minSpendController =
        TextEditingController(text: v?['minSpend']?.toString() ?? '');

    _active = v?['active'] ?? false;
    _firstTimeOnly = v?['firstTimeOnly'] ?? false;
    _weekendOnly = v?['weekendOnly'] ?? false;

    _discountType = v?['discountType'] ?? 'percentage';

    // Correctly assign
    _applicableOrderType = v?['applicableOrderType'] ?? 'All';
    _applicableVendorType = v?['applicableVendorType'] ?? 'all';

    // Map old Firestore legacy values if needed
    if (_applicableOrderType.toLowerCase() == 'blindbox') {
      _applicableOrderType = 'BlindBox';
    } else if (_applicableOrderType.toLowerCase() == 'grocery') {
      _applicableOrderType = 'Grocery';
    } else {
      _applicableOrderType = 'All';
    }

    if (!_vendorTypes.contains(_applicableVendorType.toLowerCase())) {
      _applicableVendorType = 'all';
    }

    _startDate = (v?['startDate'] as Timestamp?)?.toDate();
    _endDate = (v?['endDate'] as Timestamp?)?.toDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _discountValueController.dispose();
    _minSpendController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  Future<void> _saveVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'description': _descController.text.trim(),
      'discountType': _discountType,
      'discountValue': double.tryParse(_discountValueController.text) ?? 0,
      'minSpend': double.tryParse(_minSpendController.text) ?? 0,
      'applicableOrderType': _applicableOrderType,
      'applicableVendorType': _applicableVendorType,
      'firstTimeOnly': _firstTimeOnly,
      'weekendOnly': _weekendOnly,
      'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
      'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
      'active': _active,
      'createdAt': widget.voucher?['createdAt'] ?? FieldValue.serverTimestamp(),
    };

    try {
      final collection = FirebaseFirestore.instance.collection('vouchers');
      if (widget.voucher != null) {
        await collection.doc(widget.voucher!['id']).update(data);
      } else {
        await collection.add(data);
      }
      widget.onSaved?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(widget.voucher != null ? 'Edit Voucher' : 'Add Voucher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(_nameController, 'Name', validator: true),
              _buildGap(),
              _buildInput(_codeController, 'Code', validator: true),
              _buildGap(),
              _buildInput(_descController, 'Description', maxLines: 2),
              _buildGap(),
              _buildDropdown(
                label: 'Discount Type',
                value: _discountType,
                items: _discountTypes,
                onChanged: (v) => setState(() => _discountType = v!),
              ),
              _buildGap(),
              _buildInput(_discountValueController, 'Discount Value',
                  number: true),
              _buildGap(),
              _buildInput(_minSpendController, 'Minimum Spend', number: true),
              _buildGap(),
              _buildDropdown(
                label: 'Applicable Order Type',
                value: _applicableOrderType,
                items: _orderTypes,
                onChanged: (v) => setState(() => _applicableOrderType = v!),
              ),
              _buildGap(),
              _buildDropdown(
                label: 'Applicable Vendor Type',
                value: _applicableVendorType,
                items: _vendorTypes,
                onChanged: (v) => setState(() => _applicableVendorType = v!),
              ),
              _buildGap(),
              _buildSwitch('First Time Only', _firstTimeOnly,
                  (v) => setState(() => _firstTimeOnly = v)),
              _buildSwitch('Weekend Only', _weekendOnly,
                  (v) => setState(() => _weekendOnly = v)),
              _buildSwitch(
                  'Active', _active, (v) => setState(() => _active = v)),
              _buildGap(),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      'Start Date',
                      _startDate != null
                          ? dateFormat.format(_startDate!)
                          : 'Select date',
                      () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      'End Date',
                      _endDate != null
                          ? dateFormat.format(_endDate!)
                          : 'Select date',
                      () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveVoucher,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color.fromARGB(255, 10, 150, 220),
                  ),
                  child: Text(
                    widget.voucher != null
                        ? 'Update Voucher'
                        : 'Create Voucher',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String label,
      {bool validator = false, bool number = false, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(value),
      ),
    );
  }

  SizedBox _buildGap() => const SizedBox(height: 16);
}
