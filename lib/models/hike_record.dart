import 'package:cloud_firestore/cloud_firestore.dart';

class HikeRecord {
  final String id;
  final String userId;
  final String trailId;
  final String trailName;
  final String parkName;
  final double distanceKm;
  final int elapsedSeconds;
  final int elevationGain;
  final int calories;
  final double paceMinPerKm;
  final DateTime? timestamp;

  const HikeRecord({
    required this.id,
    required this.userId,
    required this.trailId,
    required this.trailName,
    required this.parkName,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.elevationGain,
    required this.calories,
    required this.paceMinPerKm,
    this.timestamp,
  });

  factory HikeRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final ts = data['timestamp'];
    DateTime? parsedTime;
    if (ts is Timestamp) parsedTime = ts.toDate();

    return HikeRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      trailId: data['trailId'] ?? '',
      trailName: data['trailName'] ?? 'Unknown Trail',
      parkName: data['parkName'] ?? 'Unknown Park',
      distanceKm: (data['distanceKm'] ?? 0).toDouble(),
      elapsedSeconds: data['elapsedSeconds'] ?? 0,
      elevationGain: data['elevationGain'] ?? 0,
      calories: data['calories'] ?? 0,
      paceMinPerKm: (data['paceMinPerKm'] ?? 0).toDouble(),
      timestamp: parsedTime,
    );
  }

  // ── Computed helpers ────────────────────────────────────────────────────────

  String get formattedDuration {
    final d = Duration(seconds: elapsedSeconds);
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  String get formattedPace {
    if (paceMinPerKm <= 0) return '--';
    final min = paceMinPerKm.floor();
    final sec = ((paceMinPerKm - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  String get formattedDate {
    if (timestamp == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${timestamp!.day} ${months[timestamp!.month - 1]} ${timestamp!.year}';
  }
}
