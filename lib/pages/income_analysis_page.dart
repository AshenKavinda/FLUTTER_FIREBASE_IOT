import 'package:flutter/material.dart';
import '../utils/theme.dart';

class IncomeAnalysisPage extends StatelessWidget {
  const IncomeAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Income Analysis')),
      body: Center(
        child: Text(
          'Income Analysis Content',
          style: TextStyle(color: AppColors.navyBlue, fontSize: 20),
        ),
      ),
    );
  }
}
