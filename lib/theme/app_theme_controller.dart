import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController extends ChangeNotifier {
  static const _preferenceKey = 'is_dark_theme';

  AppThemeController({required bool isDark}) : _isDark = isDark;

  bool _isDark;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_preferenceKey, _isDark);
  }

  static Future<AppThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppThemeController(
      isDark: preferences.getBool(_preferenceKey) ?? true,
    );
  }
}
