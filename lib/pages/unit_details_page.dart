import 'package:flutter/material.dart';
import '../utils/theme.dart';

class UnitDetailsPage extends StatelessWidget {
  const UnitDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Unit Details')),
      body: Center(
        child: Text(
          'Unit Details Content',
          style: TextStyle(color: AppColors.navyBlue, fontSize: 20),
        ),
      ),
    );
  }
}
