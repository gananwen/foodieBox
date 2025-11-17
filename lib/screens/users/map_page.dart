import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api/api_config.dart';
import '../../util/styles.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  // --- ( ✨ UPDATED: Default location changed to New York, US ✨ ) ---
  LatLng _currentMapCenter = const LatLng(40.7128, -74.0060); // New York City
  // --- ( ✨ END UPDATE ✨ ) ---
  String _currentAddress = "Loading...";
  bool _locationReady = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _getUserCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _getUserCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // If permission is denied, just use the default US location
        setState(() {
          _locationReady = true;
        });
        await _getAddressFromLatLng(_currentMapCenter);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentMapCenter = currentLatLng;
        _locationReady = true;
      });

      await _getAddressFromLatLng(currentLatLng);
      // --- ( ✨ NEW: Move map to user location AFTER getting it ✨ ) ---
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 17));
      // --- ( ✨ END NEW ✨ ) ---
    } catch (e) {
      // Handle potential errors (like location services being off)
      print("Error getting location: $e");
      setState(() {
        _locationReady = true; // Allow map to load with default US location
      });
      await _getAddressFromLatLng(_currentMapCenter); // Get address for default
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        setState(() =>
            _currentAddress = address.isEmpty ? "Unknown Location" : address);
      } else {
        setState(() => _currentAddress = "Unknown Location");
      }
    } catch (_) {
      setState(() => _currentAddress = "Unable to get address.");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // --- ( ✨ UPDATED: Set initial position, but don't animate yet ✨ ) ---
    // The animation will happen in _getUserCurrentLocation if successful
    mapController?.moveCamera(CameraUpdate.newLatLngZoom(_currentMapCenter, 17));
    // --- ( ✨ END UPDATE ✨ ) ---
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;
  }

  void _onCameraIdle() {
    // To avoid spamming geocoding API, only update if not searching
    if (_searchController.text.isEmpty) {
      _getAddressFromLatLng(_currentMapCenter);
    }
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'address': _currentAddress,
      'lat': _currentMapCenter.latitude,
      'lng': _currentMapCenter.longitude,
    });
  }

  void _onSearchChanged() async {
    final input = _searchController.text;
    if (input.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    // --- ( ✨ UPDATED: Changed country component to 'us' ✨ ) ---
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${ApiConfig.googleMapsApiKey}&components=country:us';
    // --- ( ✨ END UPDATE ✨ ) ---
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      setState(() => _suggestions = data['predictions']);
    } else {
      setState(() => _suggestions = []);
    }
  }

  void _selectPlace(String placeId) async {
    // Clear suggestions immediately for better UI
    setState(() {
      _suggestions = [];
    });

    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${ApiConfig.googleMapsApiKey}';
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK' && data['result'] != null) {
      final loc = data['result']['geometry']['location'];
      final addr = data['result']['formatted_address'];
      final newCenter = LatLng(loc['lat'], loc['lng']);

      setState(() {
        _currentMapCenter = newCenter;
        _currentAddress = addr;
        _searchController.text =
            addr; // Set text to full address
      });

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(newCenter, 17));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Choose Your Location'),
          backgroundColor: kPrimaryActionColor),
      body: !_locationReady
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: _currentMapCenter, zoom: 17.0),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                ),
                const Center(
                    child: Icon(Icons.location_on,
                        size: 40, color: kPrimaryActionColor)),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ]),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                              hintText: 'Search location',
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12)),
                        ),
                      ),
                      if (_suggestions.isNotEmpty)
                        Container(
                          height:
                              200, // Limit height of suggestions
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ]),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final s = _suggestions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(s['description']),
                                onTap: () => _selectPlace(s['place_id']),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(
                        top: 90,
                        left: 20,
                        right: 20), // Moved down to avoid search
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ]),
                    child: Text(_currentAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryActionColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: const Text('Confirm Location',
                          style: TextStyle(
                              fontSize: 20,
                              color: kCardColor,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}