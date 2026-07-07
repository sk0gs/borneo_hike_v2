import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Trail {
  final String id;
  final String name;
  final String parkName;
  final double distanceKm;
  final int estTimeMinutes;
  final String difficulty;
  final int elevationGain;
  final String description;
  final String emoji;
  final Color color;
  final double latitude;
  final double longitude;

  Trail({
    required this.id,
    required this.name,
    required this.parkName,
    required this.distanceKm,
    required this.estTimeMinutes,
    required this.difficulty,
    required this.elevationGain,
    required this.description,
    required this.emoji,
    required this.color,
    required this.latitude,
    required this.longitude,
  });

  String get formattedEstTime {
    if (estTimeMinutes < 60) return "$estTimeMinutes min";
    final hours = estTimeMinutes / 60;
    return "${hours.toStringAsFixed(1)} hrs";
  }

  factory Trail.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    Color parseColor(dynamic c) {
      if (c is int) return Color(c);
      if (c is String) {
        try {
          String hex = c.replaceAll('#', '').replaceAll('0x', '');
          if (hex.length == 6) hex = 'FF$hex';
          return Color(int.parse(hex, radix: 16));
        } catch (_) {}
      }
      return Colors.green;
    }

    return Trail(
      id: doc.id,
      name: data['name'] ?? 'Unknown Trail',
      parkName: data['parkName'] ?? 'Unknown Park',
      distanceKm: (data['distanceKm'] ?? 0).toDouble(),
      estTimeMinutes: data['estTimeMinutes'] ?? 0,
      difficulty: data['difficulty'] ?? 'Moderate',
      elevationGain: data['elevationGain'] ?? 0,
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '🌲',
      color: parseColor(data['color'] ?? data['colorValue']),
      latitude: (data['latitude'] ?? 1.5533).toDouble(),
      longitude: (data['longitude'] ?? 110.3592).toDouble(),
    );
  }
}
