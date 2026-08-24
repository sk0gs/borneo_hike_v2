import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Load persisted theme preference from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? modeStr = prefs.getString(_key);
      if (modeStr == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else if (modeStr == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else {
        themeModeNotifier.value = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Change and persist theme mode preference
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_key, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_key, 'dark');
      } else {
        await prefs.setString(_key, 'system');
      }
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
