import 'package:flutter/material.dart';

class Botanical {
  static const forest = Color(0xFF183F32);
  static const ink = Color(0xFF203D31);
  static const lime = Color(0xFFD2E5A1);
  static const cream = Color(0xFFEDF1E4);
  static const sage = Color(0xFFDCE8D1);
  static const peach = Color(0xFFF3DDC8);
  static const lavender = Color(0xFFE4DBED);
  static const teal = Color(0xFF336B60);
  static const muted = Color(0xFF6D7C70);

  static ThemeData theme({bool dark = false}) {
    final scheme = ColorScheme.fromSeed(
        seedColor: forest,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: dark ? const Color(0xFFA5C6B3) : forest,
        onPrimary: dark ? const Color(0xFF17261F) : Colors.white,
        secondary: dark ? const Color(0xFFBFB6A2) : const Color(0xFF536D35),
        surface: dark ? const Color(0xFF171A1C) : cream,
        surfaceContainerLowest:
            dark ? const Color(0xFF121517) : const Color(0xFFF7F5E9),
        surfaceContainerLow: dark ? const Color(0xFF1E2225) : null,
        surfaceContainer: dark ? const Color(0xFF24282B) : null,
        surfaceContainerHigh: dark ? const Color(0xFF2B3033) : null,
        surfaceContainerHighest: dark ? const Color(0xFF34393D) : null,
        onSurface: dark ? const Color(0xFFE9E7E1) : null,
        onSurfaceVariant: dark ? const Color(0xFFC3C7C5) : null,
        outline: dark ? const Color(0xFF8B9490) : null,
        outlineVariant: dark ? const Color(0xFF434A48) : null,
        primaryContainer: dark ? const Color(0xFF30483D) : null,
        onPrimaryContainer: dark ? const Color(0xFFD8EBDF) : null,
        secondaryContainer: dark ? const Color(0xFF393B37) : sage,
        onSecondaryContainer: dark ? const Color(0xFFE4DFD2) : null,
        tertiary: dark ? const Color(0xFFEBC7A2) : const Color(0xFF8B563A));
    final base = ThemeData(
        useMaterial3: true, colorScheme: scheme, fontFamily: 'Manrope');
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        headlineLarge: TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 38,
            height: 1.12,
            color: scheme.onSurface),
        headlineMedium: TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 30,
            height: 1.15,
            color: scheme.onSurface),
        titleLarge: TextStyle(
            fontSize: 21, fontWeight: FontWeight.w800, color: scheme.onSurface),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: scheme.onSurface),
        bodyLarge: TextStyle(
            fontSize: 15, height: 1.65, color: scheme.onSurfaceVariant),
        bodyMedium: TextStyle(
            fontSize: 13, height: 1.55, color: scheme.onSurfaceVariant),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF252A2D) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)))),
      chipTheme: base.chipTheme.copyWith(
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          selectedColor: dark ? const Color(0xFF30483D) : sage,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: forest,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 0.6),
    );
  }
}
