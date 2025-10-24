import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../utils/styles.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;

  // Default to Kuala Lumpur, Malaysia
  LatLng _currentMapCenter = const LatLng(3.1390, 101.6869);
  String _currentAddress = "Kuala Lumpur, Malaysia";

  // User's real-time current position
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getUserCurrentLocation();
  }

  Future<void> _getUserCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentMapCenter = currentLatLng;
        _currentPosition = position;
      });

      await _getAddressFromLatLng(currentLatLng);

      // Move camera to current location
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentMapCenter, 17),
      );
    } catch (e) {
      // Keep default Malaysia location if GPS fails
      setState(() {
        _currentAddress = "Kuala Lumpur, Malaysia";
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks.first;

      String address =
          "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";

      setState(() {
        _currentAddress = address.isEmpty ? "Unknown Location" : address;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Unable to get address.";
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _currentMapCenter = position.target;
  }

  void _onCameraIdle() {
    _getAddressFromLatLng(_currentMapCenter);
  }

  void _confirmLocation() {
    Navigator.pop(context, _currentAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Location'),
        backgroundColor: kPrimaryActionColor, // Pink top bar
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _currentMapCenter, zoom: 17.0),
            mapType: MapType.normal,
            myLocationEnabled: true, // Blue dot for user's location
            myLocationButtonEnabled: true, // Optional: button to center on user
            zoomControlsEnabled: false,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          // Center marker
          const Center(
            child:
                Icon(Icons.location_on, size: 40, color: kPrimaryActionColor),
          ),

          // Address display on top
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Text(
                _currentAddress,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),

          // Confirm button (bigger, rounded, professional)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryActionColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                      fontSize: 20,
                      color: kTextColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
