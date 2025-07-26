import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/theme.dart';
import '../services/database.dart';
import '../utils/models.dart';

class UnitDetailsPage extends StatefulWidget {
  final String unitId;
  const UnitDetailsPage({Key? key, required this.unitId}) : super(key: key);

  @override
  State<UnitDetailsPage> createState() => _UnitDetailsPageState();
}

class _UnitDetailsPageState extends State<UnitDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _isAvailable = true;
  bool _isLoading = false;
  bool _isDeleted = false;
  List<Map<String, dynamic>> _lockers = [];
  Map<String, dynamic>? _unitData;
  List<TextEditingController> _priceControllers = [];

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    for (final c in _priceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchUnit();
  }

  Future<void> _fetchUnit() async {
    print('DEBUG: Fetching unit with ID: ${widget.unitId}');
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? doc = await DatabaseService().getUnitById(
        widget.unitId,
      );
      print('DEBUG: Retrieved doc: $doc');
      if (doc == null) {
        print('DEBUG: Unit not found for ID: ${widget.unitId}');
        Fluttertoast.showToast(
          msg: 'Unit not found',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pop(context);
        return;
      }
      _unitData = doc;
      Map<String, dynamic> location = Map<String, dynamic>.from(
        _unitData!['location'] as Map,
      );
      _latController.text = location['latitude'].toStringAsFixed(6);
      _lngController.text = location['longitude'].toStringAsFixed(6);
      _isAvailable = _unitData!['status'] == 'available';
      _isDeleted = _unitData!['deleted'] == true;

      // Convert lockers list with proper type casting, filtering out null values
      List<dynamic> lockersData = _unitData!['lockers'] ?? [];
      _lockers =
          lockersData
              .where((locker) => locker != null) // Filter out null values
              .map((locker) => Map<String, dynamic>.from(locker as Map))
              .toList();

      // Initialize price controllers
      _priceControllers.forEach((c) => c.dispose());
      _priceControllers =
          _lockers
              .map(
                (locker) => TextEditingController(
                  text: locker['price']?.toString() ?? '0',
                ),
              )
              .toList();
      setState(() {});
      print('DEBUG: Unit data loaded successfully');
    } catch (e) {
      print('DEBUG: Error loading unit: $e');
      Fluttertoast.showToast(
        msg: 'Error loading unit: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      Navigator.pop(context);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Location Services');
      return;
    }
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
      await Geolocator.openAppSettings();
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error getting location: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    double? lat = double.tryParse(_latController.text);
    double? lng = double.tryParse(_lngController.text);
    if (lat == null || lng == null) {
      Fluttertoast.showToast(msg: 'Please enter valid latitude and longitude');
      return;
    }
    setState(() => _isLoading = true);
    // Update price from controllers and timestamp for all lockers
    for (int i = 0; i < _lockers.length; i++) {
      double? price = double.tryParse(_priceControllers[i].text);
      _lockers[i]['price'] = price ?? 0;
      _lockers[i]['timestamp'] = DateTime.now();
    }
    Map<String, dynamic> updatedData = {
      'location': GeoPoint(lat, lng),
      'lockers': _lockers,
      'status': _isAvailable ? 'available' : 'unavailable',
      'timestamp': DateTime.now(),
      'deleted': _isDeleted,
    };
    try {
      await DatabaseService().updateUnit(widget.unitId, updatedData);
      Fluttertoast.showToast(msg: 'Unit updated successfully');
      await _fetchUnit();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error updating unit: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _softDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Delete'),
            content: Text('Are you sure you want to delete this unit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await DatabaseService().updateUnit(widget.unitId, {
        'deleted': true,
        'timestamp': DateTime.now(),
      });
      Fluttertoast.showToast(msg: 'Unit deleted (soft)');
      setState(() => _isDeleted = true);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting unit: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreUnit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Restore'),
            content: Text('Are you sure you want to restore this unit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Restore', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await DatabaseService().updateUnit(widget.unitId, {
        'deleted': false,
        'timestamp': DateTime.now(),
      });
      Fluttertoast.showToast(msg: 'Unit restored');
      setState(() => _isDeleted = false);
      await _fetchUnit();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error restoring unit: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _unitData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Unit Details'),
          backgroundColor: AppColors.navyBlue,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Unit Details'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isDeleted)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Soft Delete',
              onPressed: _softDelete,
            ),
          if (_isDeleted)
            IconButton(
              icon: Icon(Icons.restore, color: Colors.green),
              tooltip: 'Restore',
              onPressed: _restoreUnit,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Unit ID: ${widget.unitId}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
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
                        child: Text(
                          'Get Current Location',
                          style: TextStyle(color: AppColors.navyBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text('Unit Status'),
                subtitle: Text(_isAvailable ? 'Available' : 'Unavailable'),
                value: _isAvailable,
                activeColor: AppColors.tealBlue,
                inactiveTrackColor: AppColors.navyBlue,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              SizedBox(height: 20),
              Text(
                'Lockers (${_lockers.length}):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._lockers.asMap().entries.map((entry) {
                int idx = entry.key;
                var locker = entry.value;
                final priceController =
                    _priceControllers.length > idx
                        ? _priceControllers[idx]
                        : TextEditingController(
                          text: locker['price']?.toString() ?? '0',
                        );
                return ListTile(
                  title: Text('Locker ${locker['id']}'),
                  subtitle: Row(
                    children: [
                      Text('Price: '),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              double? price = double.tryParse(val);
                              if (price != null) {
                                _lockers[idx]['price'] = price;
                                _lockers[idx]['timestamp'] = DateTime.now();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: locker['status'],
                    items:
                        ['available', 'unavailable']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase()),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        _lockers[idx]['status'] = val;
                      });
                    },
                  ),
                );
              }),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading || _isDeleted ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Save Changes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
              ),
              if (_isDeleted)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'This unit is deleted.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
