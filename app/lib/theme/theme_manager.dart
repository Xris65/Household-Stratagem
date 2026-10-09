import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeManager extends ChangeNotifier {
  AppThemeData _currentTheme;

  AppThemeData get currentTheme => _currentTheme;

  ThemeManager({String? initialTheme}) 
      : _currentTheme = initialTheme != null 
          ? AppThemeData.fromString(initialTheme) 
          : AppThemeData.neonOps;

  Future<void> setTheme(AppThemeType type) async {
    _currentTheme = AppThemeData.fromType(type);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', _currentTheme.name);
  }
}

class ThemeProvider extends InheritedNotifier<ThemeManager> {
  const ThemeProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ThemeManager of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedWidgetOfExactType<ThemeProvider>()!.notifier!;
    } else {
      return (context.getElementForInheritedWidgetOfExactType<ThemeProvider>()!.widget as ThemeProvider).notifier!;
    }
  }
}
