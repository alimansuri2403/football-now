import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color darkBg = Color(0xFF0A0E21);
  static const Color darkCard = Color(0xFF151A30);
  static const Color darkAccent = Color(0xFF00E5FF); // Cyber Cyan
  static const Color lightBg = Color(0xFFF4F6FA);
  static const Color lightCard = Colors.white;
  static const Color lightAccent = Color(0xFF1A237E); // Deep Navy/Indigo
  
  static const Color liveColor = Color(0xFFFF1744); // Live neon red
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  
  static ThemeData get darkTheme {
    return darkThemeWithColor(darkAccent);
  }

  static ThemeData get lightTheme {
    return lightThemeWithColor(lightAccent);
  }

  static ThemeData darkThemeWithColor(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: const Color(0xFFFF4081),
        surface: darkCard,
        background: darkBg,
        onPrimary: Colors.black,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(textStyle: ThemeData.dark().textTheme.bodyLarge),
        bodyMedium: GoogleFonts.inter(textStyle: ThemeData.dark().textTheme.bodyMedium),
        bodySmall: GoogleFonts.inter(textStyle: ThemeData.dark().textTheme.bodySmall),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  static ThemeData lightThemeWithColor(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightCard,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: const Color(0xFF00E5FF),
        surface: lightCard,
        background: lightBg,
        onPrimary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: GoogleFonts.inter(textStyle: ThemeData.light().textTheme.bodyLarge),
        bodyMedium: GoogleFonts.inter(textStyle: ThemeData.light().textTheme.bodyMedium),
        bodySmall: GoogleFonts.inter(textStyle: ThemeData.light().textTheme.bodySmall),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }

  // Neon gradient for live scores
  static const LinearGradient liveGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cyan premium gradient
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism card decoration helper
  static BoxDecoration glassDecoration({
    required BuildContext context,
    double radius = 16,
    double borderOpacity = 0.08,
    double fillOpacity = 0.05,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark 
          ? Colors.white.withOpacity(fillOpacity) 
          : Colors.black.withOpacity(fillOpacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark 
            ? Colors.white.withOpacity(borderOpacity) 
            : Colors.black.withOpacity(borderOpacity),
        width: 1.5,
      ),
    );
  }
}
