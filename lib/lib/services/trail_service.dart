import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trail.dart';

class TrailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all trails
  Stream<List<Trail>> getTrails() {
    return _firestore.collection('trails').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Trail.fromFirestore(doc)).toList();
    });
  }

  // Fetch single trail by ID
  Future<Trail?> getTrailById(String id) async {
    final doc = await _firestore.collection('trails').doc(id).get();
    if (doc.exists) {
      return Trail.fromFirestore(doc);
    }
    return null;
  }
}
