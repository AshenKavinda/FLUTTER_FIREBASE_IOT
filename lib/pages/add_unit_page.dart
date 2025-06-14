import 'package:flutter/material.dart';
import 'package:flutter_firebase_iot/utils/theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:random_string/random_string.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database.dart';

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
      setState(() => _currentPosition = position);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    }
  }

  Future<void> _saveUnit() async {
    print('DEBUG: Saving unit with $_lockersCount lockers');
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      Fluttertoast.showToast(msg: 'Please get location first');
      return;
    }

    setState(() => _isLoading = true);
    print(
      'DEBUG: Saving unit with $_lockersCount lockers at '
      'Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}',
    );
    // Generate lockers list
    List<Map<String, dynamic>> lockers = List.generate(_lockersCount, (index) {
      return {'id': randomAlphaNumeric(8), 'status': 'available'};
    });

    Map<String, dynamic> unitData = {
      'location': GeoPoint(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
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
                      if (_currentPosition != null)
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                          'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(color: Colors.white),
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
                inactiveTrackColor: AppColors.navyBlue.withOpacity(0.5),
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
