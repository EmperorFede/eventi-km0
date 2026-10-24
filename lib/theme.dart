import 'package:flutter/material.dart';

ThemeData creaTema(Color colore, Brightness luminosita) {
  final scuro = luminosita == Brightness.dark;
  final schema = ColorScheme.fromSeed(
    seedColor: colore,
    brightness: luminosita,
    surface: scuro ? const Color(0xFF121212) : const Color(0xFFF7F6F2),
  ).copyWith(primary: colore);

  return ThemeData(
    colorScheme: schema,
    scaffoldBackgroundColor: schema.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: schema.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: schema.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scuro ? const Color(0xFF1E1E1D) : Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scuro ? const Color(0xFF181818) : Colors.white,
      indicatorColor: colore.withValues(alpha: 0.2),
    ),
  );
}
