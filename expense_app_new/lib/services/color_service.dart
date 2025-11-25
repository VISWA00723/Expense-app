import 'package:flutter/material.dart';

class ColorService {
  // Extended color palette with 24 distinct colors
  static const List<Color> categoryColors = [
    // Primary colors
    Color(0xFF1E88E5), // Blue
    Color(0xFF7E57C2), // Purple
    Color(0xFFEC407A), // Pink
    Color(0xFFFF7043), // Deep Orange
    Color(0xFF43A047), // Green
    Color(0xFF00ACC1), // Cyan
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFFFFA726), // Orange
    
    // Secondary colors
    Color(0xFF29B6F6), // Light Blue
    Color(0xFFAB47BC), // Light Purple
    Color(0xFFEF5350), // Red
    Color(0xFF66BB6A), // Light Green
    Color(0xFF26C6DA), // Light Cyan
    Color(0xFFFFA000), // Amber
    Color(0xFF00897B), // Teal
    Color(0xFF1976D2), // Indigo
    
    // Tertiary colors
    Color(0xFF0097A7), // Dark Cyan
    Color(0xFF6A1B9A), // Dark Purple
    Color(0xFFC62828), // Dark Red
    Color(0xFF00695C), // Dark Teal
    Color(0xFF283593), // Dark Indigo
    Color(0xFFF57F17), // Dark Amber
    Color(0xFF455A64), // Blue Grey
    Color(0xFF37474F), // Dark Blue Grey
  ];

  // Get color for category by index
  static Color getColorByIndex(int index) {
    return categoryColors[index % categoryColors.length];
  }

  // Get color by category name (consistent across sessions)
  static Color getColorByName(String categoryName) {
    int hash = categoryName.hashCode;
    int index = hash.abs() % categoryColors.length;
    return categoryColors[index];
  }

  // Get color by category ID (ensures unique colors without collisions)
  static Color getColorById(int id) {
    return categoryColors[id % categoryColors.length];
  }

  // Get contrasting text color (white or black)
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Get lighter shade of color
  static Color getLighterShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withLightness((hslColor.lightness + 0.15).clamp(0.0, 1.0)).toColor();
  }

  // Get darker shade of color
  static Color getDarkerShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  // Get all colors with names
  static List<MapEntry<String, Color>> getNamedColors() {
    return [
      MapEntry('Blue', categoryColors[0]),
      MapEntry('Purple', categoryColors[1]),
      MapEntry('Pink', categoryColors[2]),
      MapEntry('Deep Orange', categoryColors[3]),
      MapEntry('Green', categoryColors[4]),
      MapEntry('Cyan', categoryColors[5]),
      MapEntry('Deep Purple', categoryColors[6]),
      MapEntry('Orange', categoryColors[7]),
      MapEntry('Light Blue', categoryColors[8]),
      MapEntry('Light Purple', categoryColors[9]),
      MapEntry('Red', categoryColors[10]),
      MapEntry('Light Green', categoryColors[11]),
      MapEntry('Light Cyan', categoryColors[12]),
      MapEntry('Amber', categoryColors[13]),
      MapEntry('Teal', categoryColors[14]),
      MapEntry('Indigo', categoryColors[15]),
      MapEntry('Dark Cyan', categoryColors[16]),
      MapEntry('Dark Purple', categoryColors[17]),
      MapEntry('Dark Red', categoryColors[18]),
      MapEntry('Dark Teal', categoryColors[19]),
      MapEntry('Dark Indigo', categoryColors[20]),
      MapEntry('Dark Amber', categoryColors[21]),
      MapEntry('Blue Grey', categoryColors[22]),
      MapEntry('Dark Blue Grey', categoryColors[23]),
    ];
  }
}
