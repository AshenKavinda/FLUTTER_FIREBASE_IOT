import 'package:flutter/material.dart';
import 'package:flutter_firebase_iot/pages/unit_details_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';
import '../services/database.dart';

class ViewUnitsPage extends StatefulWidget {
  @override
  _ViewUnitsPageState createState() => _ViewUnitsPageState();
}

class _ViewUnitsPageState extends State<ViewUnitsPage> {
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polylines = {};
  Position? _currentPosition;
  String? _selectedUnitId;

  // Filter options
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Unavailable Units',
    'Unavailable Lockers',
    'Deleted',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUnits();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        12,
      ),
    );
  }

  Future<void> _loadUnits() async {
    final db = DatabaseService();
    List<QueryDocumentSnapshot> docs;
    if (_selectedFilter == 'Deleted') {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('units')
              .where('deleted', isEqualTo: true)
              .get();
      docs = snapshot.docs;
    } else {
      docs = await db.getAllUnitDocs();
      if (_selectedFilter == 'Unavailable Units') {
        docs = docs.where((doc) => doc['status'] == 'unavailable').toList();
      } else if (_selectedFilter == 'Unavailable Lockers') {
        docs =
            docs.where((doc) {
              final lockers = List<Map<String, dynamic>>.from(
                doc['lockers'] ?? [],
              );
              return lockers.any((locker) => locker['status'] == 'unavailable');
            }).toList();
      }
    }
    Set<Marker> markers = {};
    for (var doc in docs) {
      GeoPoint location = doc['location'];
      markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: 'loker'),
          onTap: () => setState(() => _selectedUnitId = doc.id),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Units'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(6.9271, 79.8612), // Default Colombo coordinates
              zoom: 12,
            ),
            markers: _markers,
            polylines: Set<Polyline>.of(polylines.values),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by Unit ID',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search, color: AppColors.navyBlue),
                          onPressed: () async {
                            if (_searchController.text.isEmpty) return;
                            final db = DatabaseService();
                            DocumentSnapshot doc = await db.getUnitById(
                              _searchController.text.trim(),
                            );
                            if (doc.exists) {
                              GeoPoint location = doc['location'];
                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(location.latitude, location.longitude),
                                  16,
                                ),
                              );
                              setState(() => _selectedUnitId = doc.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items:
                          _filterOptions
                              .map(
                                (f) =>
                                    DropdownMenuItem(value: f, child: Text(f)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedFilter = val;
                          });
                          _loadUnits();
                        }
                      },
                      isExpanded: true,
                      underline: SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedUnitId != null)
            Positioned(
              bottom: 20,
              left: 20,
              child: SizedBox(
                width: 140, // medium size
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // square-ish
                    ),
                    alignment: Alignment.centerLeft, // left align
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: Icon(
                    Icons.visibility,
                    color: Colors.white,
                  ), // proper icon
                  label: Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  UnitDetailsPage(unitId: _selectedUnitId!),
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'location',
            backgroundColor: Colors.orange,
            child: Icon(Icons.my_location, color: AppColors.navyBlue),
            onPressed: _getCurrentLocation,
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'open_in_google_maps',
            backgroundColor: Colors.blue,
            child: Icon(Icons.map, color: Colors.white),
            onPressed: () async {
              if (_selectedUnitId == null) return;
              final db = DatabaseService();
              DocumentSnapshot doc = await db.getUnitById(_selectedUnitId!);
              GeoPoint destination = doc['location'];
              final Uri url = Uri.parse(
                'https://www.google.com/maps/dir/?api=1&destination=\${destination.latitude},\${destination.longitude}&travelmode=driving',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_unit',
            backgroundColor: AppColors.navyBlue,
            child: Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/add-unit'),
          ),
        ],
      ),
    );
  }
}
