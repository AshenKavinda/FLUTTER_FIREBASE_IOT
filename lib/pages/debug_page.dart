// pages/debug_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugPage extends StatelessWidget {
  const DebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firestore Debug')),
      body: Center(
        child: ElevatedButton(
          onPressed: _testFirestore,
          child: Text('Test Firestore Connection'),
        ),
      ),
    );
  }

  Future<void> _testFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'timestamp': DateTime.now(),
      });
      print('DEBUG: Firestore write successful');
    } catch (e) {
      print('DEBUG: Firestore error: $e');
    }
  }
}
