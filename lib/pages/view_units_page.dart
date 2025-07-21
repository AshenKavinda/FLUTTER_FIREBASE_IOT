import 'package:flutter/material.dart';
import 'package:flutter_firebase_iot/pages/unit_details_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
    _testDatabaseConnection();
  }

  Future<void> _testDatabaseConnection() async {
    try {
      print('DEBUG: Testing database connection...');
      final db = DatabaseService();
      List<MapEntry<String, Map<String, dynamic>>> units =
          await db.getAllUnitDocs();
      print(
        'DEBUG: Database connection successful. Found ${units.length} units.',
      );
      for (var unit in units) {
        print('DEBUG: Unit ID: ${unit.key}, Data: ${unit.value}');
      }
    } catch (e) {
      print('DEBUG: Database connection failed: $e');
    }
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
    print('DEBUG: Loading units with filter: $_selectedFilter');
    final db = DatabaseService();
    List<MapEntry<String, Map<String, dynamic>>> docs;

    if (_selectedFilter == 'Deleted') {
      docs = await db.getDeletedUnits();
    } else {
      docs = await db.getAllUnitDocs();
      if (_selectedFilter == 'Unavailable Units') {
        docs =
            docs.where((doc) => doc.value['status'] == 'unavailable').toList();
      } else if (_selectedFilter == 'Unavailable Lockers') {
        docs =
            docs.where((doc) {
              final lockersData = doc.value['lockers'] ?? [];
              final lockers =
                  (lockersData as List)
                      .map((locker) => Map<String, dynamic>.from(locker as Map))
                      .toList();
              return lockers.any((locker) => locker['status'] == 'unavailable');
            }).toList();
      }
    }

    print('DEBUG: Found ${docs.length} units');
    Set<Marker> markers = {};
    for (var doc in docs) {
      print('DEBUG: Processing unit ID: ${doc.key}');
      Map<String, dynamic> location = Map<String, dynamic>.from(
        doc.value['location'] as Map,
      );
      double lat = location['latitude'].toDouble();
      double lng = location['longitude'].toDouble();

      markers.add(
        Marker(
          markerId: MarkerId(doc.key),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: 'loker'),
          onTap: () {
            print('DEBUG: Marker tapped for unit ID: ${doc.key}');
            setState(() => _selectedUnitId = doc.key);
          },
        ),
      );
    }
    setState(() => _markers = markers);
    print('DEBUG: Set ${markers.length} markers on map');
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
                            Map<String, dynamic>? doc = await db.getUnitById(
                              _searchController.text.trim(),
                            );
                            if (doc != null) {
                              Map<String, dynamic> location =
                                  Map<String, dynamic>.from(
                                    doc['location'] as Map,
                                  );
                              double lat = location['latitude'].toDouble();
                              double lng = location['longitude'].toDouble();

                              _mapController.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(lat, lng),
                                  16,
                                ),
                              );
                              setState(
                                () =>
                                    _selectedUnitId =
                                        _searchController.text.trim(),
                              );
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
                  onPressed: () {
                    print(
                      'DEBUG: Navigating to UnitDetailsPage with ID: $_selectedUnitId',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                UnitDetailsPage(unitId: _selectedUnitId!),
                      ),
                    );
                  },
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
              Map<String, dynamic>? doc = await db.getUnitById(
                _selectedUnitId!,
              );
              if (doc != null) {
                Map<String, dynamic> destination = Map<String, dynamic>.from(
                  doc['location'] as Map,
                );
                double lat = destination['latitude'].toDouble();
                double lng = destination['longitude'].toDouble();

                final Uri url = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  throw 'Could not launch $url';
                }
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
