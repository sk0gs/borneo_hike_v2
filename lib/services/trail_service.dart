import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/trail.dart';
import '../models/hike_record.dart';


class TrailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all trails from Firestore.
  Stream<List<Trail>> getTrails() {
    return _firestore.collection('trails').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => Trail.fromFirestore(doc)).toList(),
        );
  }

  /// Fetch a single trail by ID.
  Future<Trail?> getTrailById(String id) async {
    final doc = await _firestore.collection('trails').doc(id).get();
    if (doc.exists) return Trail.fromFirestore(doc);
    return null;
  }

  /// Persist a completed hike summary to Firestore and update user stats.
  Future<void> saveHikeSummary({
    required Trail trail,
    required Duration elapsedTime,
    required double distanceKm,
    required int elevationGain,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final calories = (distanceKm * 65).toInt();
    final pace = elapsedTime.inSeconds > 0 && distanceKm > 0
        ? (elapsedTime.inSeconds / 60) / distanceKm
        : 0.0;

    // Save hike record
    await _firestore.collection('hike_records').add({
      'userId': user.uid,
      'trailId': trail.id,
      'trailName': trail.name,
      'parkName': trail.parkName,
      'distanceKm': distanceKm,
      'elapsedSeconds': elapsedTime.inSeconds,
      'elevationGain': elevationGain,
      'calories': calories,
      'paceMinPerKm': pace,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Increment user stats
    await _firestore.collection('users').doc(user.uid).update({
      'totalHikes': FieldValue.increment(1),
      'totalDistance': FieldValue.increment(distanceKm),
    });
  }

  /// Fetch all hike records for the current user, newest first.
  Future<List<HikeRecord>> getHikeHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final snapshot = await _firestore
          .collection('hike_records')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => HikeRecord.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('getHikeHistory error: $e');
      return [];
    }
  }
}
