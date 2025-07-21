import 'package:flutter/material.dart';
import '../services/database.dart';
import '../utils/data_migration.dart';

class DatabaseTestPage extends StatefulWidget {
  @override
  _DatabaseTestPageState createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends State<DatabaseTestPage> {
  final TextEditingController _unitIdController = TextEditingController();
  final TextEditingController _lockerIdController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Structure Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Object-Based Locker Structure Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            
            // Migration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Migration Tools', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _previewMigration,
                      child: Text('Preview Migration'),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _runMigration,
                      child: Text('Run Migration to Object Structure'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Test Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Test Operations', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _unitIdController,
                      decoration: InputDecoration(
                        labelText: 'Unit ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _lockerIdController,
                      decoration: InputDecoration(
                        labelText: 'Locker ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testGetUnit,
                            child: Text('Get Unit'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testAddLocker,
                            child: Text('Add Test Locker'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testUpdateLocker,
                            child: Text('Update Locker'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testRemoveLocker,
                            child: Text('Remove Locker'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Results Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Results', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _result.isEmpty ? 'No results yet...' : _result,
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => setState(() => _result = ''),
                        child: Text('Clear Results'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _previewMigration() async {
    setState(() {
      _isLoading = true;
      _result = 'Previewing migration...\n';
    });

    try {
      await DataMigration.previewMigration();
      setState(() => _result += '\n✅ Preview completed. Check console for details.');
    } catch (e) {
      setState(() => _result += '\n❌ Preview failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _result = 'Running migration...\n';
    });

    try {
      await DataMigration.migrateAllUnitsToObjectStructure();
      setState(() => _result += '\n✅ Migration completed successfully!');
    } catch (e) {
      setState(() => _result += '\n❌ Migration failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGetUnit() async {
    if (_unitIdController.text.isEmpty) {
      setState(() => _result += '\n❌ Please enter a Unit ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\nGetting unit ${_unitIdController.text}...\n';
    });

    try {
      final db = DatabaseService();
      Map<String, dynamic>? unit = await db.getUnitById(_unitIdController.text);
      
      if (unit != null) {
        setState(() {
          _result += '✅ Unit found:\n';
          _result += '  Location: ${unit['location']}\n';
          _result += '  Status: ${unit['status']}\n';
          _result += '  Lockers (${unit['lockers']?.length ?? 0}):\n';
          
          if (unit['lockers'] is List) {
            List lockers = unit['lockers'] as List;
            for (var locker in lockers) {
              _result += '    - ${locker['id']}: ${locker['status']} (locked: ${locker['locked']})\n';
            }
          }
        });
      } else {
        setState(() => _result += '❌ Unit not found\n');
      }
    } catch (e) {
      setState(() => _result += '❌ Error: $e\n');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testAddLocker() async {
    if (_unitIdController.text.isEmpty) {
      setState(() => _result += '\n❌ Please enter a Unit ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\nAdding test locker to unit ${_unitIdController.text}...\n';
    });

    try {
      final db = DatabaseService();
      String newLockerId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      
      await db.addLocker(_unitIdController.text, {
        'id': newLockerId,
        'status': 'available',
        'locked': false,
        'reserved': false,
        'confirmation': false,
        'price': 100,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      setState(() => _result += '✅ Added locker: $newLockerId\n');
    } catch (e) {
      setState(() => _result += '❌ Error adding locker: $e\n');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testUpdateLocker() async {
    if (_unitIdController.text.isEmpty || _lockerIdController.text.isEmpty) {
      setState(() => _result += '\n❌ Please enter both Unit ID and Locker ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\nUpdating locker ${_lockerIdController.text} in unit ${_unitIdController.text}...\n';
    });

    try {
      final db = DatabaseService();
      
      await db.updateLocker(_unitIdController.text, _lockerIdController.text, {
        'status': 'reserved',
        'locked': true,
        'price': 150,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      setState(() => _result += '✅ Updated locker: ${_lockerIdController.text}\n');
    } catch (e) {
      setState(() => _result += '❌ Error updating locker: $e\n');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testRemoveLocker() async {
    if (_unitIdController.text.isEmpty || _lockerIdController.text.isEmpty) {
      setState(() => _result += '\n❌ Please enter both Unit ID and Locker ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\nRemoving locker ${_lockerIdController.text} from unit ${_unitIdController.text}...\n';
    });

    try {
      final db = DatabaseService();
      
      await db.removeLocker(_unitIdController.text, _lockerIdController.text);
      
      setState(() => _result += '✅ Removed locker: ${_lockerIdController.text}\n');
    } catch (e) {
      setState(() => _result += '❌ Error removing locker: $e\n');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _unitIdController.dispose();
    _lockerIdController.dispose();
    super.dispose();
  }
}
