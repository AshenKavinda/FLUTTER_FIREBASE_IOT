import 'package:flutter/material.dart';

class AppColors {
  static const Color navyBlue = Color.fromARGB(255, 4, 91, 179);
  static const Color tealBlue = Color.fromARGB(255, 0, 157, 255);
}

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.navyBlue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.navyBlue,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: AppColors.tealBlue,
    elevation: 2,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: TextTheme(
    titleLarge: TextStyle(
      // Replaces headline6
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    bodyMedium: TextStyle(
      // Replaces bodyText2
      color: AppColors.navyBlue,
      fontSize: 16,
    ),
  ),
);
