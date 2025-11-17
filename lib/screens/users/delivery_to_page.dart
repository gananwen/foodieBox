import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import '../../api/api_config.dart';

class DeliveryToPage extends StatefulWidget {
  const DeliveryToPage({super.key});

  @override
  State<DeliveryToPage> createState() => _DeliveryToPageState();
}

class _DeliveryToPageState extends State<DeliveryToPage> {
  List<dynamic> _places = [];
  bool _loading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);

      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${position.latitude},${position.longitude}'
          '&radius=3000&type=restaurant'
          '&key=${ApiConfig.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _places = data['results'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.0174533;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
        (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _selectPlace(dynamic place) {
    final loc = place['geometry']['location'];
    final selected = {
      'label': place['name'],
      'contactName': 'You',
      'address': place['vicinity'],
      'lat': loc['lat'],
      'lng': loc['lng'],
    };
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deliver To')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _places.isEmpty
              ? const Center(child: Text('No nearby places found.'))
              : ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    final loc = place['geometry']['location'];
                    final distance = (_currentPosition != null)
                        ? _calculateDistance(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            loc['lat'],
                            loc['lng'],
                          ).toStringAsFixed(2)
                        : '–';

                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.amber),
                      title: Text(place['name']),
                      subtitle: Text('${place['vicinity']}\n$distance km'),
                      isThreeLine: true,
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
    );
  }
}
