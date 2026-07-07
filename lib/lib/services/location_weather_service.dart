import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationWeatherService {
  static String getWeatherDescription(int code) {
    if (code == 0) return "Clear sky";
    if (code >= 1 && code <= 3) return "Partly cloudy";
    if (code == 45 || code == 48) return "Foggy";
    if (code >= 51 && code <= 55) return "Drizzle";
    if (code >= 61 && code <= 65) return "Rainy";
    if (code >= 71 && code <= 77) return "Snowy";
    if (code >= 80 && code <= 82) return "Rain showers";
    if (code >= 95) return "Thunderstorm";
    return "Fair";
  }

  static IconData getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code == 45 || code == 48) return Icons.cloud;
    if (code >= 51 && code <= 55) return Icons.grain;
    if (code >= 61 && code <= 65) return Icons.umbrella;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.beach_access;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.cloud_outlined;
  }

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
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint("GPS error, using fallback: $e");
      return _getFallbackPosition();
    }
  }

  static Position _getFallbackPosition() {
    return Position(
      latitude: 1.5533, longitude: 110.3592, // Kuching, Sarawak
      timestamp: DateTime.now(), accuracy: 0, altitude: 0, 
      altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
    );
  }

  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    // Open-Meteo expects latitude and longitude with max 4 decimal places
    final cleanLat = lat.toStringAsFixed(4);
    final cleanLon = lon.toStringAsFixed(4);
    
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$cleanLat&longitude=$cleanLon'
      '&current=temperature_2m,weather_code&timezone=auto'
    );

    try {
      debugPrint('Weather Request: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Weather API Error: ${response.statusCode}');
        return _getSafeDefault();
      }
    } catch (e) {
      debugPrint('Weather Network Error: $e');
      return _getSafeDefault();
    }
  }

  static Map<String, dynamic> _getSafeDefault() {
    return {
      'current': {'temperature_2m': 28.0, 'weather_code': 0}
    };
  }
}
