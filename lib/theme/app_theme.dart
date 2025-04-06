import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 2,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
