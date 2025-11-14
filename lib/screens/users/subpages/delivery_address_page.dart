import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../users/map_page.dart';
import 'package:foodiebox/util/styles.dart';

class DeliveryAddressPage extends StatefulWidget {
  const DeliveryAddressPage({super.key});

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  // Controllers for all user inputs
  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();

  final List<String> _labels = ['Home', 'Office', 'Other'];
  String _selectedLabel = 'Home';
  String? editingId;
  double? lat;
  double? lng;

  GoogleMapController? _mapController;

  // State for conceptual autocomplete results (would be filled by an API)
  List<String> _autocompleteSuggestions = [];

  // Default camera position
  static const LatLng _initialCameraPosition = LatLng(3.1390, 101.6869);

  @override
  void initState() {
    super.initState();
    // Listen to changes for potential autocomplete trigger
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // --- Autocomplete/Suggestion Stub ---
  void _onAddressChanged() {
    // ... (this logic remains the same) ...
    final input = _addressController.text;
    if (input.length > 2) {
      setState(() {
        _autocompleteSuggestions = [
          '${input}th Street, New York',
          '${input}0 Jalan Raja, Kuala Lumpur',
          '${input} A venue, Singapore',
        ]
            .where((s) => s.toLowerCase().startsWith(input.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        _autocompleteSuggestions = [];
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    // ... (this logic remains the same) ...
    _addressController.text = suggestion;
    setState(() {
      _autocompleteSuggestions = []; // Hide suggestions
    });
    _geocodeAddress();
  }

  // --- Geocoding (Manual Input) ---
  Future<void> _geocodeAddress() async {
    // ... (this logic remains the same) ...
        final address = _addressController.text.trim();
    if (address.isEmpty) return;

    // Clear suggestions before geocoding
    setState(() => _autocompleteSuggestions = []);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding address on map...')),
      );

      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final newLat = locations.first.latitude;
        final newLng = locations.first.longitude;

        setState(() {
          lat = newLat;
          lng = newLng;
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(newLat, newLng), 16),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location found! Map updated.')),
        );
      } else {
        setState(() {
          lat = null;
          lng = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Address not found. Please check spelling or use the map picker.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error geocoding address: ${e.toString()}')),
      );
    }
  }

  // --- Map Picker (Visual Selection) ---
  Future<void> _openMapPicker() async {
    // ... (this logic remains the same) ...
        final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPage()),
    );

    if (result != null && result is Map<String, dynamic>) {
      // 1. Fill the address field with the chosen location from the map.
      _addressController.text = result['address'];

      // 2. Store coordinates
      lat = (result['lat'] as num?)?.toDouble();
      lng = (result['lng'] as num?)?.toDouble();

      setState(() {
        _autocompleteSuggestions = []; // Clear suggestions after map pick
      });

      // 3. Update map preview
      if (_mapController != null && lat != null && lng != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat!, lng!), 16),
        );
      }
    }
  }

  // --- Save/Edit/Delete/Reset methods (Unchanged from previous revision) ---
  Future<void> _saveAddress() async {
    // ... (this logic remains the same) ...
        final userId = FirebaseAuth.instance.currentUser!.uid;
    final address = _addressController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final details = _detailsController.text.trim();

    if (address.isEmpty ||
        lat == null ||
        lng == null ||
        name.isEmpty ||
        phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please ensure location is set and contact info is complete.')),
      );
      return;
    }

    final data = {
      'label': _selectedLabel,
      'contactName': name,
      'contactPhone': phone,
      'address': address,
      'details': details,
      'lat': lat,
      'lng': lng,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (editingId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .doc(editingId)
            .update(data);
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .add(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(editingId != null ? 'Address updated' : 'Address added')),
      );

      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  void _startEditing(String docId, Map<String, dynamic> data) {
    // ... (this logic remains the same) ...
        setState(() {
      editingId = docId;
      _addressController.text = data['address'] ?? '';
      _nameController.text = data['contactName'] ?? '';
      _phoneController.text = data['contactPhone'] ?? '';
      _detailsController.text = data['details'] ?? '';
      _selectedLabel = data['label'] ?? 'Home';

      lat = (data['lat'] as num?)?.toDouble();
      lng = (data['lng'] as num?)?.toDouble();
    });

    if (lat != null && lng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat!, lng!), 16),
      );
    }
  }

  void _resetForm() {
    // ... (this logic remains the same) ...
        setState(() {
      editingId = null;
      _addressController.clear();
      _nameController.clear();
      _phoneController.clear();
      _detailsController.clear();
      _selectedLabel = 'Home';
      lat = null;
      lng = null;
      _autocompleteSuggestions = [];
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_initialCameraPosition, 10),
    );
  }

  Future<void> _deleteAddress(String docId) async {
    // ... (this logic remains the same) ...
        final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses')
        .doc(docId)
        .delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Address deleted')));
  }

  // --- REMOVED ---
  // void _goToCheckout() { ... }
  // --- END REMOVED ---

  // --- UI Helper Functions ---

  InputDecoration _inputDecoration(String labelText,
      {String? hintText, Widget? suffixIcon}) {
    // ... (this logic remains the same) ...
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.amber, width: 2.0),
      ),
    );
  }

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to manage addresses."));
    }
    final userId = user.uid;

    final LatLng mapTarget = (lat != null && lng != null)
        ? LatLng(lat!, lng!)
        : _initialCameraPosition;
    final Set<Marker> markers = (lat != null && lng != null)
        ? {Marker(markerId: const MarkerId('selected'), position: mapTarget)}
        : {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          // MODIFIED: Just pop the screen
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Delivery Address',
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      // --- REMOVED FloatingActionButton ---
      body: Column(
        children: [
          // --- Map Preview (Always showing) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: mapTarget,
                    zoom: (lat != null && lng != null) ? 16 : 10,
                  ),
                  markers: markers,
                  onMapCreated: (controller) => _mapController = controller,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  liteModeEnabled: false,
                ),
              ),
            ),
          ),

          // --- Main Content (Scrollable Form and List) ---
          Expanded(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const SizedBox(height: 10),

                    // 1. LOCATION SELECTION SECTION
                    const Text('1. Set Location',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Address Label Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLabel,
                      items: _labels.map((label) {
                        return DropdownMenuItem(
                            value: label, child: Text(label));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedLabel = value ?? 'Home'),
                      decoration: _inputDecoration('Address Label'),
                    ),
                    const SizedBox(height: 10),

                    // Address Field (Manual input with geocoding trigger)
                    TextField(
                      controller: _addressController,
                      // The main trigger for geocoding when user is done typing
                      onSubmitted: (_) => _geocodeAddress(),
                      decoration: _inputDecoration(
                        'Type your address',
                        hintText: 'e.g. 16 Jalan Merah, Taman XYZ',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.amber),
                          onPressed: _geocodeAddress,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Map Button (Alternative method)
                    ElevatedButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: Text(
                          lat != null
                              ? 'Re-select Location on Map'
                              : 'Select Location on Map',
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    if (lat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Location verified on map. Lat: ${lat!.toStringAsFixed(4)}, Lng: ${lng!.toStringAsFixed(4)}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 30),

                    // 2. CONTACT AND DETAILS SECTION
                    const Text('2. Contact and Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),

                    // Contact Name
                    TextField(
                      controller: _nameController,
                      decoration: _inputDecoration('Contact Name',
                          hintText: 'e.g. John Doe'),
                    ),
                    const SizedBox(height: 10),

                    // Contact Phone
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Phone Number',
                          hintText: 'e.g. 0123456789'),
                    ),
                    const SizedBox(height: 10),

                    // Details (Level/Unit)
                    TextField(
                      controller: _detailsController,
                      decoration: _inputDecoration('Address Details (Optional)',
                          hintText: 'e.g. Level 3, Unit B-12'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Save/Update Button
                    ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                          editingId != null
                              ? 'Update Address'
                              : 'Save New Address',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (editingId != null)
                      TextButton(
                        onPressed: _resetForm,
                        child: const Text('Cancel Edit',
                            style: TextStyle(color: Colors.red)),
                      ),
                    const Divider(height: 40),

                    // --- Saved Addresses List (Section 3) ---
                    const Text('3. Saved Addresses',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('addresses')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting)
                          return const Center(
                              child: CircularProgressIndicator());
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                          return const Center(
                              child: Text('No addresses saved yet.'));

                        final docs = snapshot.data!.docs;
                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final label = data['label'] ?? 'Home';
                            final address = data['address'];
                            final details = data['details'] ?? '';
                            final name = data['contactName'] ?? 'N/A';
                            final phone = data['contactPhone'] ?? 'N/A';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                  leading: Icon(
                                      label == 'Home'
                                          ? Icons.home
                                          : (label == 'Office'
                                              ? Icons.work
                                              : Icons.location_on),
                                      color: Colors.amber),
                                  title: Text('$label - $name',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    '$address\nDetails: $details\nPhone: $phone',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.amber, size: 20),
                                        onPressed: () =>
                                            _startEditing(doc.id, data),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent, size: 20),
                                        onPressed: () => _deleteAddress(doc.id),
                                      ),
                                    ],
                                  ),
                                  // --- MODIFIED: Pop with the selected address data ---
                                  onTap: () {
                                    Navigator.pop(context, data);
                                  }),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),

                // --- Autocomplete Suggestions Overlay ---
                if (_autocompleteSuggestions.isNotEmpty)
                  Positioned(
                    top: 130, // Adjust position based on your layout
                    left: 20,
                    right: 20,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        // ... (autocomplete UI remains the same) ...
                         decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade100)),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _autocompleteSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _autocompleteSuggestions[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: Colors.grey, size: 20),
                              title: Text(suggestion,
                                  style: const TextStyle(fontSize: 14)),
                              onTap: () => _selectSuggestion(suggestion),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}