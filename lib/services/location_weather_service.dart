import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherData {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final int uvIndex;
  final double tempHigh;
  final double tempLow;
  final int weatherCode;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.tempHigh,
    required this.tempLow,
    required this.weatherCode,
  });

  String get description {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode >= 1 && weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode == 45 || weatherCode == 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 55) return 'Drizzle';
    if (weatherCode >= 61 && weatherCode <= 65) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain Showers';
    if (weatherCode >= 95) return 'Thunderstorm';
    return 'Fair';
  }

  IconData get icon {
    if (weatherCode == 0) return Icons.wb_sunny_outlined;
    if (weatherCode >= 1 && weatherCode <= 3) return Icons.wb_cloudy_outlined;
    if (weatherCode == 45 || weatherCode == 48) return Icons.foggy;
    if (weatherCode >= 51 && weatherCode <= 55) return Icons.grain;
    if (weatherCode >= 61 && weatherCode <= 65) return Icons.umbrella_outlined;
    if (weatherCode >= 71 && weatherCode <= 77) return Icons.ac_unit;
    if (weatherCode >= 80 && weatherCode <= 82) return Icons.water_drop_outlined;
    if (weatherCode >= 95) return Icons.thunderstorm_outlined;
    return Icons.wb_cloudy_outlined;
  }

  bool get isGoodForHiking {
    // Not thunderstorm/heavy rain and temp between 15 and 36°C
    return weatherCode < 61 && temperature >= 15 && temperature <= 36;
  }

  static WeatherData get fallback => const WeatherData(
        temperature: 28.0,
        feelsLike: 31.0,
        humidity: 75.0,
        windSpeed: 10.0,
        uvIndex: 6,
        tempHigh: 32.0,
        tempLow: 24.0,
        weatherCode: 0,
      );
}

class LocationWeatherService {
  static Future<Position> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _getFallbackPosition();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _getFallbackPosition();
      }
      if (permission == LocationPermission.deniedForever) return _getFallbackPosition();

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('GPS failure, using fallback: $e');
      return _getFallbackPosition();
    }
  }

  static Position _getFallbackPosition() {
    return Position(
      latitude: 1.5533,
      longitude: 110.3592, // Kuching, Sarawak
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  static Future<WeatherData> getWeather(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lon.toStringAsFixed(4)}'
      '&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,uv_index'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&forecast_days=1'
      '&timezone=auto',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final daily = data['daily'] as Map<String, dynamic>? ?? {};

        return WeatherData(
          temperature: (current['temperature_2m'] ?? 28.0).toDouble(),
          feelsLike: (current['apparent_temperature'] ?? 28.0).toDouble(),
          humidity: (current['relative_humidity_2m'] ?? 70.0).toDouble(),
          windSpeed: (current['wind_speed_10m'] ?? 10.0).toDouble(),
          uvIndex: (current['uv_index'] ?? 0).toInt(),
          tempHigh: ((daily['temperature_2m_max'] as List?)?.first ?? 32.0).toDouble(),
          tempLow: ((daily['temperature_2m_min'] as List?)?.first ?? 24.0).toDouble(),
          weatherCode: (current['weather_code'] ?? 0).toInt(),
        );
      }
    } catch (e) {
      debugPrint('Weather network error: $e');
    }
    return WeatherData.fallback;
  }

  // Legacy helpers kept for backward compat
  static String getWeatherDescription(int code) => WeatherData(
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        windSpeed: 0,
        uvIndex: 0,
        tempHigh: 0,
        tempLow: 0,
        weatherCode: code,
      ).description;

  static IconData getWeatherIcon(int code) => WeatherData(
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        windSpeed: 0,
        uvIndex: 0,
        tempHigh: 0,
        tempLow: 0,
        weatherCode: code,
      ).icon;
}
