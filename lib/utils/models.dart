// Custom GeoPoint class to replace Firestore's GeoPoint
class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);

  // Convert to Map for Realtime Database storage
  Map<String, double> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  // Create from Map when reading from Realtime Database
  factory GeoPoint.fromMap(Map<String, dynamic> map) {
    return GeoPoint(map['latitude'].toDouble(), map['longitude'].toDouble());
  }

  @override
  String toString() {
    return 'GeoPoint(latitude: $latitude, longitude: $longitude)';
  }
}
