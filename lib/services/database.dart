import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../utils/models.dart';

class DatabaseService {
  final DatabaseReference _unitsRef = FirebaseDatabase.instance.ref('units');

  Future<String> addUnit(Map<String, dynamic> unitData) async {
    try {
      // Generate a unique key for the new unit
      DatabaseReference newUnitRef = _unitsRef.push();

      // Convert GeoPoint to a map for Realtime Database
      if (unitData['location'] != null && unitData['location'] is GeoPoint) {
        GeoPoint location = unitData['location'];
        unitData['location'] = location.toMap();
      }

      // Convert lockers list to object format for database storage
      unitData = _convertLockersListToObject(unitData);

      // Convert DateTime objects to ISO strings
      unitData = _convertDateTimesToStrings(unitData);

      await newUnitRef.set(unitData);
      return newUnitRef.key!;
    } on FirebaseException catch (e) {
      throw "Firebase Realtime Database error: ${e.message}";
    } catch (e) {
      throw "Unexpected error: $e";
    }
  }

  /// Get all unit documents (for marker loading)
  Future<List<MapEntry<String, Map<String, dynamic>>>> getAllUnitDocs() async {
    try {
      DatabaseEvent event =
          await _unitsRef.orderByChild('deleted').equalTo(false).once();

      if (event.snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> unitsMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      return unitsMap.entries
          .map(
            (entry) {
              Map<String, dynamic> unitData = Map<String, dynamic>.from(entry.value as Map);
              // Convert lockers object to list format for UI compatibility
              unitData = _convertLockersObjectToList(unitData);
              return MapEntry<String, Map<String, dynamic>>(
                entry.key.toString(),
                unitData,
              );
            },
          )
          .toList();
    } catch (e) {
      throw "Error fetching units: $e";
    }
  }

  /// Get a unit document by its Realtime Database key
  Future<Map<String, dynamic>?> getUnitById(String id) async {
    try {
      print('DEBUG: DatabaseService.getUnitById called with ID: $id');
      DatabaseEvent event = await _unitsRef.child(id).once();
      print('DEBUG: Database event received: ${event.snapshot.value}');

      if (event.snapshot.value == null) {
        print('DEBUG: No data found for ID: $id');
        return null;
      }

      Map<String, dynamic> result = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );
      // Convert lockers object to list format for UI compatibility
      result = _convertLockersObjectToList(result);
      print('DEBUG: Returning data: $result');
      return result;
    } catch (e) {
      print('DEBUG: Error in getUnitById: $e');
      throw "Error fetching unit: $e";
    }
  }

  /// Update a unit document
  Future<void> updateUnit(String id, Map<String, dynamic> data) async {
    try {
      // Convert GeoPoint to a map for Realtime Database
      if (data['location'] != null && data['location'] is GeoPoint) {
        GeoPoint location = data['location'];
        data['location'] = location.toMap();
      }

      // Convert lockers list to object format for database storage
      data = _convertLockersListToObject(data);

      // Convert DateTime objects to ISO strings
      data = _convertDateTimesToStrings(data);

      await _unitsRef.child(id).update(data);
    } catch (e) {
      throw "Error updating unit: $e";
    }
  }

  /// Get deleted units
  Future<List<MapEntry<String, Map<String, dynamic>>>> getDeletedUnits() async {
    try {
      DatabaseEvent event =
          await _unitsRef.orderByChild('deleted').equalTo(true).once();

      if (event.snapshot.value == null) {
        return [];
      }

      Map<dynamic, dynamic> unitsMap =
          event.snapshot.value as Map<dynamic, dynamic>;

      return unitsMap.entries
          .map(
            (entry) {
              Map<String, dynamic> unitData = Map<String, dynamic>.from(entry.value as Map);
              // Convert lockers object to list format for UI compatibility
              unitData = _convertLockersObjectToList(unitData);
              return MapEntry<String, Map<String, dynamic>>(
                entry.key.toString(),
                unitData,
              );
            },
          )
          .toList();
    } catch (e) {
      throw "Error fetching deleted units: $e";
    }
  }

  /// Helper method to convert DateTime objects to ISO strings
  Map<String, dynamic> _convertDateTimesToStrings(Map<String, dynamic> data) {
    Map<String, dynamic> result = Map.from(data);

    result.forEach((key, value) {
      if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is List) {
        result[key] =
            value.map((item) {
              if (item is Map<String, dynamic>) {
                return _convertDateTimesToStrings(item);
              } else if (item is DateTime) {
                return item.toIso8601String();
              }
              return item;
            }).toList();
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertDateTimesToStrings(value);
      }
    });

    return result;
  }

  /// Convert lockers list format to object format for database storage
  /// Input: {"lockers": [{"id": "123", "locked": false}, {"id": "456", "locked": true}]}
  /// Output: {"lockers": {"123": {"id": "123", "locked": false}, "456": {"id": "456", "locked": true}}}
  Map<String, dynamic> _convertLockersListToObject(Map<String, dynamic> data) {
    Map<String, dynamic> result = Map.from(data);

    if (result['lockers'] != null && result['lockers'] is List) {
      List<dynamic> lockersList = result['lockers'] as List;
      Map<String, dynamic> lockersObject = {};

      for (var locker in lockersList) {
        if (locker is Map<String, dynamic> && locker['id'] != null) {
          String lockerId = locker['id'].toString();
          lockersObject[lockerId] = Map<String, dynamic>.from(locker);
        }
      }

      result['lockers'] = lockersObject;
    }

    return result;
  }

  /// Convert lockers object format to list format for UI compatibility
  /// Input: {"lockers": {"123": {"id": "123", "locked": false}, "456": {"id": "456", "locked": true}}}
  /// Output: {"lockers": [{"id": "123", "locked": false}, {"id": "456", "locked": true}]}
  Map<String, dynamic> _convertLockersObjectToList(Map<String, dynamic> data) {
    Map<String, dynamic> result = Map.from(data);

    if (result['lockers'] != null && result['lockers'] is Map) {
      Map<String, dynamic> lockersObject = Map<String, dynamic>.from(result['lockers'] as Map);
      List<Map<String, dynamic>> lockersList = [];

      lockersObject.forEach((key, value) {
        if (value is Map) {
          Map<String, dynamic> locker = Map<String, dynamic>.from(value);
          // Ensure the locker has its ID
          locker['id'] = key;
          lockersList.add(locker);
        }
      });

      result['lockers'] = lockersList;
    }

    return result;
  }

  /// Update a specific locker in a unit (using object structure)
  Future<void> updateLocker(String unitId, String lockerId, Map<String, dynamic> lockerData) async {
    try {
      // Convert DateTime objects to ISO strings
      lockerData = _convertDateTimesToStrings(lockerData);
      
      await _unitsRef.child(unitId).child('lockers').child(lockerId).update(lockerData);
    } catch (e) {
      throw "Error updating locker: $e";
    }
  }

  /// Add a new locker to a unit (using object structure)
  Future<void> addLocker(String unitId, Map<String, dynamic> lockerData) async {
    try {
      String lockerId = lockerData['id'] ?? _generateLockerId();
      lockerData['id'] = lockerId;
      
      // Convert DateTime objects to ISO strings
      lockerData = _convertDateTimesToStrings(lockerData);
      
      await _unitsRef.child(unitId).child('lockers').child(lockerId).set(lockerData);
    } catch (e) {
      throw "Error adding locker: $e";
    }
  }

  /// Remove a locker from a unit (using object structure)
  Future<void> removeLocker(String unitId, String lockerId) async {
    try {
      await _unitsRef.child(unitId).child('lockers').child(lockerId).remove();
    } catch (e) {
      throw "Error removing locker: $e";
    }
  }

  /// Generate a unique locker ID
  String _generateLockerId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
