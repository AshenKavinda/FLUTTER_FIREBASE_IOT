import 'package:flutter/material.dart';
import 'package:flutter_firebase_iot/pages/add_unit_page.dart';
import 'package:flutter_firebase_iot/pages/debug_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/view_units_page.dart';
import 'pages/income_analysis_page.dart';
import 'utils/theme.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => AdminDashboard(),
        '/unit-details': (context) => ViewUnitsPage(),
        '/income-analysis': (context) => IncomeAnalysisPage(),
        '/add-unit': (context) => AddUnitPage(),
        '/debug': (context) => DebugPage(),
      },
    );
  }
}
