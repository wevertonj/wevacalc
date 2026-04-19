import 'package:flutter/material.dart';

/// Gerador de ThemeData claro e escuro usando ColorScheme.fromSeed.
class AppTheme {
  AppTheme._();

  static ThemeData light({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
    );
  }

  static ThemeData dark({required Color seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
    );
  }
}
