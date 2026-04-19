import 'package:flutter/material.dart';

/// Paleta de 9 seed colors disponíveis para o usuário personalizar o tema.
class AppColors {
  AppColors._();

  static const List<Color> seedColors = [
    Color(0xFFFFC107), // Amber (padrão — estilo premium/dourado)
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFFE91E63), // Pink
    Color(0xFF607D8B), // Blue Grey
  ];

  static const Color defaultSeedColor = Color(0xFFFFC107);
}
