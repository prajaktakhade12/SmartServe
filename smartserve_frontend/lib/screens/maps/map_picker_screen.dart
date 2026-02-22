import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng _selectedLocation = const LatLng(20.5937, 78.9629);
  bool _locationPicked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF003c8f)],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.5937, 78.9629),
              zoom: 5,
            ),
            onTap: (LatLng latLng) {
              setState(() {
                _selectedLocation = latLng;
                _locationPicked = true;
              });
            },
            markers: _locationPicked
                ? {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: _selectedLocation,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue),
                    )
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Hint banner at top
          if (!_locationPicked)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: AppTheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Tap on the map to select your location",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Coordinates display
          if (_locationPicked)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${_selectedLocation.latitude.toStringAsFixed(5)}, "
                        "${_selectedLocation.longitude.toStringAsFixed(5)}",
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _locationPicked
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, {
                  'lat': _selectedLocation.latitude,
                  'lng': _selectedLocation.longitude,
                  'address':
                      "${_selectedLocation.latitude.toStringAsFixed(5)}, "
                      "${_selectedLocation.longitude.toStringAsFixed(5)}",
                });
              },
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text("Confirm Location",
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}