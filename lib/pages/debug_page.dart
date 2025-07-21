// pages/debug_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Realtime Database Debug')),
      body: Center(
        child: ElevatedButton(
          onPressed: _testDatabase,
          child: Text('Test Database Connection'),
        ),
      ),
    );
  }

  Future<void> _testDatabase() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('test');
      await ref.push().set({'timestamp': DateTime.now().toIso8601String()});
      print('DEBUG: Database write successful');
    } catch (e) {
      print('DEBUG: Database error: $e');
    }
  }
}
