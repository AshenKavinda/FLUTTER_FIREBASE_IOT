import 'package:firebase_database/firebase_database.dart';

/// Migration utility to convert existing units from array-based lockers to object-based lockers
class DataMigration {
  static final DatabaseReference _unitsRef = FirebaseDatabase.instance.ref('units');

  /// Convert all units from array-based to object-based locker structure
  static Future<void> migrateAllUnitsToObjectStructure() async {
    try {
      print('Starting migration to object-based locker structure...');
      
      // Get all units
      DatabaseEvent event = await _unitsRef.once();
      
      if (event.snapshot.value == null) {
        print('No units found to migrate.');
        return;
      }

      Map<dynamic, dynamic> unitsMap = event.snapshot.value as Map<dynamic, dynamic>;
      int migrated = 0;
      int skipped = 0;

      for (var entry in unitsMap.entries) {
        String unitId = entry.key.toString();
        Map<String, dynamic> unitData = Map<String, dynamic>.from(entry.value as Map);

        if (await _migrateUnitToObjectStructure(unitId, unitData)) {
          migrated++;
          print('✅ Migrated unit: $unitId');
        } else {
          skipped++;
          print('⏭️  Skipped unit: $unitId (already object structure or no lockers)');
        }
      }

      print('Migration completed! Migrated: $migrated, Skipped: $skipped');
    } catch (e) {
      print('❌ Migration failed: $e');
      throw e;
    }
  }

  /// Convert a single unit from array-based to object-based locker structure
  static Future<bool> _migrateUnitToObjectStructure(String unitId, Map<String, dynamic> unitData) async {
    try {
      // Check if lockers exist and are in array format
      if (unitData['lockers'] == null) {
        return false; // No lockers to migrate
      }

      // If lockers is already a Map (object structure), skip
      if (unitData['lockers'] is Map) {
        return false; // Already migrated
      }

      // If lockers is a List (array structure), convert to object
      if (unitData['lockers'] is List) {
        List<dynamic> lockersList = unitData['lockers'] as List;
        Map<String, dynamic> lockersObject = {};

        for (var locker in lockersList) {
          if (locker is Map<String, dynamic> && locker['id'] != null) {
            String lockerId = locker['id'].toString();
            lockersObject[lockerId] = Map<String, dynamic>.from(locker);
          }
        }

        // Update the unit with object-based lockers
        await _unitsRef.child(unitId).child('lockers').set(lockersObject);
        return true; // Successfully migrated
      }

      return false; // Unknown structure
    } catch (e) {
      print('❌ Failed to migrate unit $unitId: $e');
      return false;
    }
  }

  /// Convert a single unit back to array-based structure (rollback)
  static Future<void> rollbackUnitToArrayStructure(String unitId) async {
    try {
      DatabaseEvent event = await _unitsRef.child(unitId).once();
      
      if (event.snapshot.value == null) {
        print('Unit $unitId not found.');
        return;
      }

      Map<String, dynamic> unitData = Map<String, dynamic>.from(event.snapshot.value as Map);

      if (unitData['lockers'] != null && unitData['lockers'] is Map) {
        Map<String, dynamic> lockersObject = Map<String, dynamic>.from(unitData['lockers'] as Map);
        List<Map<String, dynamic>> lockersList = [];

        lockersObject.forEach((key, value) {
          if (value is Map) {
            Map<String, dynamic> locker = Map<String, dynamic>.from(value);
            locker['id'] = key; // Ensure ID is present
            lockersList.add(locker);
          }
        });

        await _unitsRef.child(unitId).child('lockers').set(lockersList);
        print('✅ Rolled back unit $unitId to array structure');
      }
    } catch (e) {
      print('❌ Failed to rollback unit $unitId: $e');
      throw e;
    }
  }

  /// Preview what the migration would do without actually changing data
  static Future<void> previewMigration() async {
    try {
      print('Previewing migration...\n');
      
      DatabaseEvent event = await _unitsRef.once();
      
      if (event.snapshot.value == null) {
        print('No units found.');
        return;
      }

      Map<dynamic, dynamic> unitsMap = event.snapshot.value as Map<dynamic, dynamic>;

      for (var entry in unitsMap.entries) {
        String unitId = entry.key.toString();
        Map<String, dynamic> unitData = Map<String, dynamic>.from(entry.value as Map);

        print('Unit ID: $unitId');
        
        if (unitData['lockers'] == null) {
          print('  Status: No lockers');
        } else if (unitData['lockers'] is Map) {
          Map<String, dynamic> lockersObject = Map<String, dynamic>.from(unitData['lockers'] as Map);
          print('  Status: Already object structure (${lockersObject.length} lockers)');
          print('  Locker IDs: ${lockersObject.keys.toList()}');
        } else if (unitData['lockers'] is List) {
          List<dynamic> lockersList = unitData['lockers'] as List;
          print('  Status: Array structure - NEEDS MIGRATION (${lockersList.length} lockers)');
          List<String> lockerIds = [];
          for (var locker in lockersList) {
            if (locker is Map && locker['id'] != null) {
              lockerIds.add(locker['id'].toString());
            }
          }
          print('  Locker IDs: $lockerIds');
        } else {
          print('  Status: Unknown structure - ${unitData['lockers'].runtimeType}');
        }
        print('');
      }
    } catch (e) {
      print('❌ Preview failed: $e');
    }
  }
}
