import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EA), // Deep Indigo
        brightness: Brightness.dark,
        primary: const Color(0xFF7C4DFF),
        secondary: const Color(0xFF00E5FF),
        surface: const Color(0xFF121212),
        background: const Color(0xFF0A0A0A),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EA),
        brightness: Brightness.light,
        primary: const Color(0xFF6200EA),
        secondary: const Color(0xFF00E5FF),
        surface: const Color(0xFFFFFFFF),
        background: const Color(0xFFF5F5F7),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
