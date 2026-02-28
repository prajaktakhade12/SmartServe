import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../citizen/issue_detail_screen.dart';

class NearbyIssuesScreen extends StatefulWidget {
  final String selectedLanguage;
  const NearbyIssuesScreen({Key? key, required this.selectedLanguage}) : super(key: key);

  @override
  State<NearbyIssuesScreen> createState() => _NearbyIssuesScreenState();
}

class _NearbyIssuesScreenState extends State<NearbyIssuesScreen> {
  List<dynamic> _issues = [];
  bool _loading = true;
  bool _mapView = false;
  double _radius = 5;
  GoogleMapController? _mapController;
  LatLng? _myLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() => _loading = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _myLocation = LatLng(pos.latitude, pos.longitude);

      final result = await ApiService.getNearbyIssues(pos.latitude, pos.longitude, radius: _radius);
      setState(() {
        _issues = result;
        _loading = false;
        _buildMarkers();
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _buildMarkers() {
    _markers = {};
    if (_myLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('me'),
        position: _myLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    }
    for (var issue in _issues) {
      if (issue['latitude'] != null && issue['longitude'] != null) {
        _markers.add(Marker(
          markerId: MarkerId(issue['id'].toString()),
          position: LatLng(issue['latitude'], issue['longitude']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            issue['status'] == 'COMPLETED' ? BitmapDescriptor.hueGreen :
            issue['status'] == 'IN_PROGRESS' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: issue['title'], snippet: issue['location']),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => IssueDetailScreen(
              issue: Map<String, dynamic>.from(issue),
              selectedLanguage: widget.selectedLanguage))),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Issues (${_issues.length})'),
        flexibleSpace: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]))),
        actions: [
          IconButton(
            icon: Icon(_mapView ? Icons.list_rounded : Icons.map_rounded, color: Colors.white),
            onPressed: () => setState(() => _mapView = !_mapView),
            tooltip: _mapView ? 'List View' : 'Map View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadNearby,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Radius selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Theme.of(context).cardColor,
                  child: Row(children: [
                    const Icon(Icons.radar_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('Radius:', style: TextStyle(fontWeight: FontWeight.w600)),
                    Expanded(child: Slider(
                      value: _radius,
                      min: 1, max: 20,
                      divisions: 19,
                      label: '${_radius.toStringAsFixed(0)} km',
                      onChanged: (v) => setState(() => _radius = v),
                      onChangeEnd: (_) => _loadNearby(),
                    )),
                    Text('${_radius.toStringAsFixed(0)} km',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ]),
                ),

                Expanded(
                  child: _issues.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.location_off_rounded, size: 70, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('No issues found within ${_radius.toStringAsFixed(0)} km',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ]))
                      : _mapView && _myLocation != null
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(target: _myLocation!, zoom: 13),
                              onMapCreated: (c) => _mapController = c,
                              markers: _markers,
                              myLocationEnabled: true,
                              zoomControlsEnabled: true,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _issues.length,
                              itemBuilder: (ctx, i) => _issueCard(_issues[i]),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _issueCard(Map issue) {
    final status = issue['status'] ?? 'REPORTED';
    final color = AppTheme.getStatusColor(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => IssueDetailScreen(
            issue: Map<String, dynamic>.from(issue),
            selectedLanguage: widget.selectedLanguage))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.getCategoryColor(issue['category'] ?? '').withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.report_problem_rounded,
                color: AppTheme.getCategoryColor(issue['category'] ?? ''), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(issue['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(issue['location'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(status.replaceAll('_', ' '),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('${issue['distance_km']} km',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
      ),
    );
  }
}