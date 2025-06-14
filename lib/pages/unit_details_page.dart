import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/theme.dart';

class UnitDetailsPage extends StatelessWidget {
  final String unitId;

  const UnitDetailsPage({Key? key, required this.unitId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unit Details'),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('units').doc(unitId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Unit not found'));
          }

          var unitData = snapshot.data!.data() as Map<String, dynamic>;
          GeoPoint location = unitData['location'];
          List<dynamic> lockers = unitData['lockers'] ?? [];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unit ID: $unitId', style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Lat: ${location.latitude.toStringAsFixed(6)}'),
                Text('Lng: ${location.longitude.toStringAsFixed(6)}'),
                SizedBox(height: 20),
                Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(
                    unitData['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor:
                      unitData['status'] == 'available'
                          ? Colors.green
                          : Colors.red,
                ),
                SizedBox(height: 20),
                Text(
                  'Lockers (${lockers.length}):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...lockers.map(
                  (locker) => ListTile(
                    title: Text('Locker ${locker['id']}'),
                    trailing: Chip(
                      label: Text(
                        locker['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          locker['status'] == 'available'
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
