// voucher_form_screen.dart
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

  bool _active = true;
  bool _firstTimeOnly = false;
  bool _weekendOnly = false;
  bool _freeDelivery = false;
  String _discountType = 'percentage';
  String _applicableOrderType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final _discountTypes = ['percentage', 'fixed'];
  final _orderTypes = ['all', 'pickup', 'food_delivery'];

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
    _active = v?['active'] ?? true;
    _firstTimeOnly = v?['firstTimeOnly'] ?? false;
    _weekendOnly = v?['weekendOnly'] ?? false;
    _freeDelivery = v?['freeDelivery'] ?? false;
    _discountType = v?['discountType'] ?? 'percentage';
    _applicableOrderType = v?['applicableOrderType'] ?? 'all';
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
    final initial =
        isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
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
      'firstTimeOnly': _firstTimeOnly,
      'weekendOnly': _weekendOnly,
      'freeDelivery': _freeDelivery,
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
      appBar: AppBar(
        title: Text(widget.voucher != null ? 'Edit Voucher' : 'Add Voucher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'Discount Type'),
                items: _discountTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _discountType = v!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _discountValueController,
                decoration: const InputDecoration(labelText: 'Discount Value'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _minSpendController,
                decoration: const InputDecoration(labelText: 'Minimum Spend'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _applicableOrderType,
                decoration:
                    const InputDecoration(labelText: 'Applicable Order Type'),
                items: _orderTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _applicableOrderType = v!),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                  title: const Text('First Time Only'),
                  value: _firstTimeOnly,
                  onChanged: (v) => setState(() => _firstTimeOnly = v)),
              SwitchListTile(
                  title: const Text('Weekend Only'),
                  value: _weekendOnly,
                  onChanged: (v) => setState(() => _weekendOnly = v)),
              SwitchListTile(
                  title: const Text('Free Delivery'),
                  value: _freeDelivery,
                  onChanged: (v) => setState(() => _freeDelivery = v)),
              SwitchListTile(
                  title: const Text('Active'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, true),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Start Date'),
                        child: Text(_startDate != null
                            ? dateFormat.format(_startDate!)
                            : 'Select date'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, false),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'End Date'),
                        child: Text(_endDate != null
                            ? dateFormat.format(_endDate!)
                            : 'Select date'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveVoucher,
                child: Text(widget.voucher != null ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
