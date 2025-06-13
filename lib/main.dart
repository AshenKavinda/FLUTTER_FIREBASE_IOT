import 'package:flutter/material.dart';
import 'pages/admin_dashboard.dart';
import 'pages/unit_details_page.dart';
import 'pages/income_analysis_page.dart';
import 'utils/theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => AdminDashboard(),
        '/unit-details': (context) => UnitDetailsPage(),
        '/income-analysis': (context) => IncomeAnalysisPage(),
      },
    );
  }
}
