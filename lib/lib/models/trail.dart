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

  // Coordinates
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

  factory Trail.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trail(
      id: doc.id,
      name: data['name'] ?? '',
      parkName: data['parkName'] ?? '',
      distanceKm: (data['distanceKm'] ?? 0).toDouble(),
      estTimeMinutes: data['estTimeMinutes'] ?? 0,
      difficulty: data['difficulty'] ?? 'Moderate',
      elevationGain: data['elevationGain'] ?? 0,
      description: data['description'] ?? '',
      emoji: data['emoji'] ?? '🌲',
      color: Color(int.parse(data['color'] ?? '0xFF4CAF50')),

      latitude: (data['latitude'] ?? 1.7170).toDouble(),
      longitude: (data['longitude'] ?? 110.3250).toDouble(),
    );
  }
}