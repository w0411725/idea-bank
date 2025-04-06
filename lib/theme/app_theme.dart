import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
