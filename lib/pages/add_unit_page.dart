import 'package:flutter/material.dart';
import 'package:flutter_firebase_iot/utils/theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/database.dart';
import '../utils/models.dart';

class AddUnitPage extends StatefulWidget {
  const AddUnitPage({super.key});

  @override
  _AddUnitPageState createState() => _AddUnitPageState();
}

class _AddUnitPageState extends State<AddUnitPage> {
  final _formKey = GlobalKey<FormState>();
  int _lockersCount = 1;
  bool _isAvailable = true;
  Position? _currentPosition;
  bool _isLoading = false;

  // Controllers for latitude and longitude
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Location Services');
      return;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
        msg:
            'Location permissions are permanently denied. Enable in app settings.',
      );
      // Optionally open app settings
      await Geolocator.openAppSettings();
      return;
    }

    // Get the current location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    }
  }

  Future<void> _saveUnit() async {
    print('DEBUG: Saving unit with $_lockersCount lockers');
    if (!_formKey.currentState!.validate()) return;
    double? lat = double.tryParse(_latController.text);
    double? lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null) {
      Fluttertoast.showToast(msg: 'Please enter valid latitude and longitude');
      return;
    }
    setState(() => _isLoading = true);
    print(
      'DEBUG: Saving unit with $_lockersCount lockers at '
      'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}',
    );
    // Generate lockers list
    List<Map<String, dynamic>> lockers = List.generate(_lockersCount, (index) {
      return {
        'id': 'locker_${index + 1}',
        'status': 'available',
        'locked': 1,
        'reservedDocID': '',
        'price': 0,
        'timestamp': DateTime.now(),
        'reserved': false,
      };
    });

    Map<String, dynamic> unitData = {
      'location': GeoPoint(lat, lng),
      'lockers': lockers,
      'status': _isAvailable ? 'available' : 'unavailable',
      'timestamp': DateTime.now(),
      'deleted': false,
    };

    try {
      print('DEBUG: Saving unit data: $unitData');
      await DatabaseService().addUnit(unitData);
      Fluttertoast.showToast(msg: 'Unit added successfully');
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error saving unit: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add New Unit'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Location Section
              Card(
                color: AppColors.tealBlue,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                hintText: 'e.g. 6.9271',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final v = double.tryParse(value ?? '');
                                if (v == null) return 'Enter valid latitude';
                                if (v < -90 || v > 90)
                                  return 'Latitude must be -90 to 90';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                hintText: 'e.g. 79.8612',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                final v = double.tryParse(value ?? '');
                                if (v == null) return 'Enter valid longitude';
                                if (v < -180 || v > 180)
                                  return 'Longitude must be -180 to 180';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Card(
                            color: Colors.red[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.red[800],
                                size: 20,
                              ),
                              tooltip: 'Clear',
                              onPressed: () {
                                _latController.clear();
                                _lngController.clear();
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child:
                            _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                  'Get Current Location',
                                  style: TextStyle(color: AppColors.navyBlue),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Lockers Count
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Number of Lockers',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                initialValue: '1',
                validator: (value) {
                  if (value == null ||
                      int.tryParse(value) == null ||
                      int.parse(value) < 1) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onChanged: (value) => _lockersCount = int.tryParse(value) ?? 1,
              ),
              SizedBox(height: 20),

              // Status Toggle
              SwitchListTile(
                title: Text('Unit Status'),
                subtitle: Text(_isAvailable ? 'Available' : 'Unavailable'),
                value: _isAvailable,
                activeColor: AppColors.tealBlue,
                inactiveTrackColor: AppColors.navyBlue,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              SizedBox(height: 30),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUnit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Save Unit',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
