import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF007AFF),
  scaffoldBackgroundColor: Color(0xFF1C1C1E),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1C1C1E),
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF007AFF),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF007AFF),
  ),
  iconTheme: IconThemeData(
    color: Color(0xFF007AFF),
  ),
  listTileTheme: ListTileThemeData(
    iconColor: Color(0xFF007AFF),
  ),
  cardTheme: CardThemeData(
    color: Color(0xFF2C2C2E),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
