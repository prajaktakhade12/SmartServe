import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);
  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _loadingLocation = true;
  // Default fallback: center of India
  LatLng _initialPosition = const LatLng(20.5937, 78.9629);
  double _initialZoom = 5;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() => _loadingLocation = false); return; }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { setState(() => _loadingLocation = false); return; }
      }
      if (permission == LocationPermission.deniedForever) { setState(() => _loadingLocation = false); return; }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _initialPosition = LatLng(pos.latitude, pos.longitude);
        _initialZoom = 15;
        _loadingLocation = false;
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: 15),
        ),
      );
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF003c8f)]))),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: _initialZoom),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (LatLng latLng) {
              setState(() => _selectedLocation = latLng);
            },
            markers: _selectedLocation != null
                ? {Marker(
                    markerId: const MarkerId("selected"),
                    position: _selectedLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  )}
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Loading indicator
          if (_loadingLocation)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                child: Row(children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  const Text("Getting your location...", style: TextStyle(fontSize: 14)),
                ]),
              ),
            ),

          // Hint when location loaded
          if (!_loadingLocation && _selectedLocation == null)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                child: const Row(children: [
                  Icon(Icons.touch_app_rounded, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Expanded(child: Text("Tap on the map to select your location", style: TextStyle(fontSize: 14))),
                ]),
              ),
            ),

          // Coordinates display
          if (_selectedLocation != null)
            Positioned(
              bottom: 90, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                child: Row(children: [
                  const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    "${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  )),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, {
                  'lat': _selectedLocation!.latitude,
                  'lng': _selectedLocation!.longitude,
                  'address': "${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}",
                });
              },
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.check_rounded, color: Colors.white),
              label: const Text("Confirm Location", style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}