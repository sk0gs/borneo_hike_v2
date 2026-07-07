import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUser(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    await _saveToLocal(user);
  }

  Future<AppUser?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final appUser = AppUser.fromFirestore(doc.data()!, user.uid);
        await _saveToLocal(appUser);
        return appUser;
      }
    } catch (e) {
      // Offline fallback
      final local = await _getFromLocal();
      if (local != null) return local;
      rethrow; // Rethrow so the UI can show the error
    }
    return null;
  }

  Future<void> _saveToLocal(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toMap()));
    await prefs.setString('user_uid', user.uid);
  }

  Future<AppUser?> _getFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('user_data');
    if (jsonStr == null) return null;
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final uid = prefs.getString('user_uid') ?? '';
    return AppUser.fromFirestore(data, uid);
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final ref = _storage.ref().child('user_profiles').child('${user.uid}.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      await _firestore.collection('users').doc(user.uid).update({'photoUrl': url});
      return url;
    } catch (e) {
      return null;
    }
  }
}
