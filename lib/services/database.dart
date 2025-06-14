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

  /// Fetch units with pagination
  /// [limit] is the number of documents per page
  /// [startAfterDoc] is the last document from the previous page (for pagination)
  Future<List<QueryDocumentSnapshot>> fetchUnits({
    int limit = 10,
    DocumentSnapshot? startAfterDoc,
  }) async {
    Query query = _unitsCollection.orderBy('name').limit(limit);
    if (startAfterDoc != null) {
      query = query.startAfterDocument(startAfterDoc);
    }
    QuerySnapshot snapshot = await query.get();
    return snapshot.docs;
  }
}
