import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {

  /// Gets the device's current GPS position at highest accuracy.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  /// Converts GPS coordinates to a full readable address.
  ///
  /// Strategy (handles sparse OSM data in Indian cities like Yavatmal):
  /// 1. Call Nominatim at zoom=19 for structured address fields
  /// 2. Build address from individual fields (house_no, road, area, city, state)
  /// 3. If structured fields are too sparse (only city+state), use
  ///    Nominatim's display_name and clean it up
  /// 4. Try zoom=17 for a nearby landmark name
  /// 5. Combine: "Near <Landmark>, <detailed address>"
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final headers = {
        'User-Agent': 'SmartServe-CitizenApp/1.0',
        'Accept-Language': 'en',
      };

      // ── Step 1: Detailed address call ────────────────────────────────────
      final res1 = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=$lat&lon=$lng&format=json&addressdetails=1'
          '&zoom=19&namedetails=1',
        ),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (res1.statusCode != 200) return null;

      final geo      = json.decode(res1.body) as Map<String, dynamic>;
      final addr     = geo['address'] as Map<String, dynamic>? ?? {};
      final rawDisplayName = geo['display_name'] as String? ?? '';

      // ── Step 2: Build structured address from individual fields ──────────
      final List<String> parts = [];

      final house = addr['house_number'] as String? ?? '';
      final road  = (addr['road']
          ?? addr['pedestrian']
          ?? addr['path']
          ?? addr['footway']
          ?? addr['street']
          ?? addr['highway']
          ?? '') as String;

      if (house.isNotEmpty && road.isNotEmpty) {
        parts.add('$house, $road');
      } else if (road.isNotEmpty) {
        parts.add(road);
      }

      final area = (addr['neighbourhood']
          ?? addr['suburb']
          ?? addr['quarter']
          ?? addr['residential']
          ?? addr['village']
          ?? addr['hamlet']
          ?? addr['locality']
          ?? addr['county']
          ?? '') as String;
      final joinedSoFar = parts.join(' ');
      if (area.isNotEmpty && !joinedSoFar.contains(area)) {
        parts.add(area);
      }

      final city = (addr['city']
          ?? addr['town']
          ?? addr['city_district']
          ?? addr['state_district']
          ?? '') as String;
      final joinedSoFar2 = parts.join(' ');
      if (city.isNotEmpty && !joinedSoFar2.contains(city)) {
        parts.add(city);
      }

      final state = addr['state'] as String? ?? '';
      final joinedSoFar3 = parts.join(' ');
      if (state.isNotEmpty && !joinedSoFar3.contains(state)) {
        parts.add(state);
      }

      String addressStr = parts.join(', ');

      // ── Step 3: If structured result is too sparse, use display_name ─────
      // "Too sparse" = only city+state (2 or fewer parts), which means OSM
      // doesn't have detailed street data for this location (common in India)
      if (parts.length <= 2 && rawDisplayName.isNotEmpty) {
        addressStr = _cleanDisplayName(rawDisplayName);
      }

      // ── Step 4: Find nearby landmark ─────────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 600));

      String landmark = '';
      try {
        final res2 = await http.get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse'
            '?lat=$lat&lon=$lng&format=json&zoom=17',
          ),
          headers: headers,
        ).timeout(const Duration(seconds: 8));

        if (res2.statusCode == 200) {
          final lmData = json.decode(res2.body) as Map<String, dynamic>;
          final name   = lmData['name'] as String? ?? '';

          // Only use if it's a meaningful named place
          if (name.isNotEmpty
              && name != road
              && name != city
              && name != state
              && name.length > 3
              && !addressStr.contains(name)) {
            landmark = name;
          }
        }
      } catch (_) {
        // Landmark lookup failed — continue without it
      }

      // ── Step 5: Combine ───────────────────────────────────────────────────
      String final_address;
      if (landmark.isNotEmpty && addressStr.isNotEmpty) {
        final_address = 'Near $landmark, $addressStr';
      } else if (addressStr.isNotEmpty) {
        final_address = addressStr;
      } else {
        return null; // will show coords as fallback
      }

      return final_address;

    } catch (_) {
      return null;
    }
  }

  /// Cleans up Nominatim's display_name for Indian addresses.
  ///
  /// Raw display_name example:
  /// "12, Station Road, Yavatmal Naka, Yavatmal, Yavatmal, Maharashtra, 445001, India"
  ///
  /// Cleaned result:
  /// "12, Station Road, Yavatmal Naka, Yavatmal, Maharashtra"
  static String _cleanDisplayName(String displayName) {
    final parts = displayName
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final cleaned = <String>[];
    final seen    = <String>{};

    for (final part in parts) {
      // Skip: country name, PIN/ZIP codes (all digits), duplicates
      if (part == 'India') continue;
      if (RegExp(r'^\d{4,6}$').hasMatch(part)) continue; // PIN code
      if (seen.contains(part.toLowerCase())) continue;    // duplicate

      seen.add(part.toLowerCase());
      cleaned.add(part);

      // Stop after state (usually 5–6 meaningful parts)
      if (cleaned.length >= 6) break;
    }

    return cleaned.join(', ');
  }

  /// Fallback: raw coordinates string
  static String formatCoords(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}