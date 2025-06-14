import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference _unitsCollection = FirebaseFirestore.instance
      .collection('units');

  Future<String> addUnit(Map<String, dynamic> unitData) async {
    try {
      DocumentReference docRef = await _unitsCollection.add(unitData);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw "Firestore error: ${e.message}";
    } catch (e) {
      throw "Unexpected error: $e";
    }
  }

  /// Get all units, returning only location and id fields
  Future<List<Map<String, dynamic>>> getAllUnits() async {
    QuerySnapshot snapshot = await _unitsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {'location': data['location'], 'id': data['id']};
    }).toList();
  }
}
