import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DistanceUnit { metric, imperial }
enum TemperatureUnit { celsius, fahrenheit }

class UnitService {
  static const String _distanceKey = 'distance_unit';
  static const String _tempKey = 'temperature_unit';

  static final ValueNotifier<DistanceUnit> distanceUnitNotifier =
      ValueNotifier<DistanceUnit>(DistanceUnit.metric);

  static final ValueNotifier<TemperatureUnit> tempUnitNotifier =
      ValueNotifier<TemperatureUnit>(TemperatureUnit.celsius);

  /// Initialize and load saved unit preferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final distStr = prefs.getString(_distanceKey);
      if (distStr == 'imperial') {
        distanceUnitNotifier.value = DistanceUnit.imperial;
      } else {
        distanceUnitNotifier.value = DistanceUnit.metric;
      }

      final tempStr = prefs.getString(_tempKey);
      if (tempStr == 'fahrenheit') {
        tempUnitNotifier.value = TemperatureUnit.fahrenheit;
      } else {
        tempUnitNotifier.value = TemperatureUnit.celsius;
      }
    } catch (e) {
      debugPrint('Error loading unit preferences: $e');
    }
  }

  /// Change and save distance unit preference
  static Future<void> setDistanceUnit(DistanceUnit unit) async {
    distanceUnitNotifier.value = unit;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _distanceKey,
        unit == DistanceUnit.imperial ? 'imperial' : 'metric',
      );
    } catch (e) {
      debugPrint('Error saving distance unit: $e');
    }
  }

  /// Change and save temperature unit preference
  static Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    tempUnitNotifier.value = unit;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tempKey,
        unit == TemperatureUnit.fahrenheit ? 'fahrenheit' : 'celsius',
      );
    } catch (e) {
      debugPrint('Error saving temperature unit: $e');
    }
  }

  // ── Helper Conversions ──────────────────────────────────────────────────────

  static bool get isImperialDistance =>
      distanceUnitNotifier.value == DistanceUnit.imperial;

  static String get distanceSymbol => isImperialDistance ? 'mi' : 'km';

  static double convertDistance(double distanceInKm) {
    if (isImperialDistance) {
      return distanceInKm * 0.621371;
    }
    return distanceInKm;
  }

  static String formatDistanceValue(double distanceInKm, {int decimals = 1}) {
    final converted = convertDistance(distanceInKm);
    return converted.toStringAsFixed(decimals);
  }

  static String formatDistance(double distanceInKm, {int decimals = 1}) {
    return '${formatDistanceValue(distanceInKm, decimals: decimals)} $distanceSymbol';
  }

  static bool get isFahrenheit =>
      tempUnitNotifier.value == TemperatureUnit.fahrenheit;

  static String get tempSymbol => isFahrenheit ? '°F' : '°C';

  static double convertTemp(double celsius) {
    if (isFahrenheit) {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }

  static String formatTemp(double celsius) {
    final converted = convertTemp(celsius).round();
    return '$converted$tempSymbol';
  }

  static int formatTempInt(double celsius) {
    return convertTemp(celsius).round();
  }

  static String get windSpeedSymbol => isImperialDistance ? 'mph' : 'km/h';

  static String formatWindSpeed(double speedKmh) {
    if (isImperialDistance) {
      final mph = speedKmh * 0.621371;
      return '${mph.round()} mph';
    }
    return '${speedKmh.round()} km/h';
  }
}
