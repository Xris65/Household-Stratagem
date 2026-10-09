import 'package:flutter/material.dart';

enum AppThemeType { trench, neonOps, ghost }

class AppThemeData {
  final AppThemeType type;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final String name;

  const AppThemeData({
    required this.type,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.name,
  });

  static const trench = AppThemeData(
    type: AppThemeType.trench,
    name: 'Trench',
    primary: Color(0xFF6B8E23), // Olive
    secondary: Colors.amber,
    background: Color(0xFF0F110C),
    surface: Color(0xFF1E211A),
    textPrimary: Colors.white,
    textSecondary: Colors.white60,
  );

  static const neonOps = AppThemeData(
    type: AppThemeType.neonOps,
    name: 'Neon-Ops',
    primary: Colors.cyanAccent,
    secondary: Colors.pinkAccent, // Magenta-ish
    background: Color(0xFF050505),
    surface: Color(0xFF141414),
    textPrimary: Colors.white,
    textSecondary: Colors.white70,
  );

  static const ghost = AppThemeData(
    type: AppThemeType.ghost,
    name: 'Ghost',
    primary: Colors.white,
    secondary: Color(0xFFD32F2F), // Crimson Red
    background: Color(0xFF000000),
    surface: Color(0xFF111111),
    textPrimary: Colors.white,
    textSecondary: Colors.white54,
  );

  static AppThemeData fromType(AppThemeType type) {
    switch (type) {
      case AppThemeType.trench: return trench;
      case AppThemeType.neonOps: return neonOps;
      case AppThemeType.ghost: return ghost;
    }
  }

  static AppThemeData fromString(String name) {
    switch (name) {
      case 'Trench': return trench;
      case 'Ghost': return ghost;
      case 'Neon-Ops': 
      default: return neonOps;
    }
  }
}
