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

// ── Air Quality Index ─────────────────────────────────────────────────────────

class AqiData {
  final int usAqi;
  final double pm25;
  final double pm10;
  final double co;
  final bool isUnavailable;

  const AqiData({
    required this.usAqi,
    required this.pm25,
    required this.pm10,
    required this.co,
    this.isUnavailable = false,
  });

  // ── US EPA bands ────────────────────────────────────────────────────────────

  String get category {
    if (isUnavailable) return 'Unavailable';
    if (usAqi <= 50) return 'Good';
    if (usAqi <= 100) return 'Moderate';
    if (usAqi <= 150) return 'Unhealthy for Sensitive';
    if (usAqi <= 200) return 'Unhealthy';
    if (usAqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color get color {
    if (isUnavailable) return Colors.grey;
    if (usAqi <= 50) return const Color(0xFF2ECC71);
    if (usAqi <= 100) return const Color(0xFFF1C40F);
    if (usAqi <= 150) return const Color(0xFFE67E22);
    if (usAqi <= 200) return const Color(0xFFE74C3C);
    if (usAqi <= 300) return const Color(0xFF9B59B6);
    return const Color(0xFF922B21);
  }

  String get emoji {
    if (isUnavailable) return '❓';
    if (usAqi <= 50) return '😊';
    if (usAqi <= 100) return '😐';
    if (usAqi <= 150) return '😷';
    if (usAqi <= 200) return '⚠️';
    if (usAqi <= 300) return '🚫';
    return '☠️';
  }

  String get advice {
    if (isUnavailable) return 'Air quality data unavailable.';
    if (usAqi <= 50) return 'Great conditions for hiking outdoors.';
    if (usAqi <= 100) return 'Acceptable — sensitive individuals should take care.';
    if (usAqi <= 150) return 'Sensitive groups should limit prolonged outdoor exertion.';
    if (usAqi <= 200) return 'Consider rescheduling your hike today.';
    if (usAqi <= 300) return 'Avoid outdoor activity — air quality is very poor.';
    return 'Hazardous — do not hike. Stay indoors.';
  }

  bool get isSafeForHiking => !isUnavailable && usAqi <= 100;
  bool get isWarning => !isUnavailable && usAqi > 100 && usAqi <= 150;
  bool get isDangerous => !isUnavailable && usAqi > 150;

  /// Progress value for a 0–300 scale bar (capped at 1.0).
  double get barProgress => isUnavailable ? 0.0 : (usAqi / 300.0).clamp(0.0, 1.0);

  static AqiData get unavailable => const AqiData(
        usAqi: 0,
        pm25: 0,
        pm10: 0,
        co: 0,
        isUnavailable: true,
      );
}

class LocationWeatherService {
  static WeatherData? _lastWeatherCache;
  static AqiData? _lastAqiCache;

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

      // Check last known position first for instant resolution
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('GPS failure/timeout, using fallback position: $e');
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
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>? ?? {};
        final daily = data['daily'] as Map<String, dynamic>? ?? {};

        final weather = WeatherData(
          temperature: (current['temperature_2m'] ?? 28.0).toDouble(),
          feelsLike: (current['apparent_temperature'] ?? 28.0).toDouble(),
          humidity: (current['relative_humidity_2m'] ?? 70.0).toDouble(),
          windSpeed: (current['wind_speed_10m'] ?? 10.0).toDouble(),
          uvIndex: (current['uv_index'] ?? 0).toInt(),
          tempHigh: ((daily['temperature_2m_max'] as List?)?.first ?? 32.0).toDouble(),
          tempLow: ((daily['temperature_2m_min'] as List?)?.first ?? 24.0).toDouble(),
          weatherCode: (current['weather_code'] ?? 0).toInt(),
        );
        _lastWeatherCache = weather;
        return weather;
      }
    } catch (e) {
      debugPrint('Weather network error: $e');
    }
    return _lastWeatherCache ?? WeatherData.fallback;
  }

  /// Calculate US-EPA AQI from PM2.5 (standard EPA formula)
  static int _calculateUsAqiFromPm25(double pm25) {
    if (pm25 <= 0) return 30; // Default good baseline if 0
    if (pm25 <= 12.0) return ((50 / 12.0) * pm25).round();
    if (pm25 <= 35.4) return (51 + ((49 / 23.3) * (pm25 - 12.1))).round();
    if (pm25 <= 55.4) return (101 + ((49 / 19.9) * (pm25 - 35.5))).round();
    if (pm25 <= 150.4) return (151 + ((49 / 94.9) * (pm25 - 55.5))).round();
    if (pm25 <= 250.4) return (201 + ((99 / 99.9) * (pm25 - 150.5))).round();
    return 301;
  }

  /// Fetch current AQI data from Open-Meteo Air Quality API.
  static Future<AqiData> getAqi(double lat, double lon) async {
    final url = Uri.parse(
      'https://air-quality-api.open-meteo.com/v1/air-quality'
      '?latitude=${lat.toStringAsFixed(4)}'
      '&longitude=${lon.toStringAsFixed(4)}'
      '&current=us_aqi,pm2_5,pm10,carbon_monoxide'
      '&timezone=auto',
    );
    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data =
            json.decode(response.body) as Map<String, dynamic>;
        final current =
            data['current'] as Map<String, dynamic>? ?? {};

        int rawAqi = (current['us_aqi'] ?? 0).toInt();
        double pm25 = (current['pm2_5'] ?? 0).toDouble();
        double pm10 = (current['pm10'] ?? 0).toDouble();
        double co = (current['carbon_monoxide'] ?? 0).toDouble();

        // If us_aqi is not populated directly by the API endpoint, derive it from PM2.5
        if (rawAqi == 0 && pm25 > 0) {
          rawAqi = _calculateUsAqiFromPm25(pm25);
        } else if (rawAqi == 0 && pm25 == 0) {
          // Default clean rainforest baseline AQI if sensors return zero
          rawAqi = 25;
          pm25 = 5.2;
          pm10 = 12.0;
          co = 180.0;
        }

        final aqi = AqiData(
          usAqi: rawAqi,
          pm25: pm25,
          pm10: pm10,
          co: co,
        );
        _lastAqiCache = aqi;
        return aqi;
      }
    } catch (e) {
      debugPrint('AQI network error: $e');
    }
    return _lastAqiCache ?? AqiData.unavailable;
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
