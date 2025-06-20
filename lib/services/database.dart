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

  /// Get all unit documents (for marker loading)
  Future<List<QueryDocumentSnapshot>> getAllUnitDocs() async {
    QuerySnapshot snapshot =
        await _unitsCollection.where('deleted', isEqualTo: false).get();
    return snapshot.docs;
  }

  /// Get a unit document by its Firestore document ID
  Future<DocumentSnapshot> getUnitById(String id) async {
    return await _unitsCollection.doc(id).get();
  }
}
