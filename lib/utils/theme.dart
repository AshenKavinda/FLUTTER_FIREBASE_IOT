import 'package:flutter/material.dart';

class AppColors {
  static const Color navyBlue = Color(0xFF001F3F);
  static const Color tealBlue = Color(0xFF3A6D8C);
  static const Color skyBlue = Color(0xFF6A9AB0);
  static const Color cream = Color(0xFFEAD8B1);
}

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.navyBlue,
  scaffoldBackgroundColor: AppColors.cream,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.navyBlue,
    foregroundColor: AppColors.cream,
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
      color: AppColors.cream,
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
