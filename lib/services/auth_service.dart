import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> register(String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Update display name in Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // Create user profile in Firestore
    await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
      'name': displayName,
      'email': email,
      'totalHikes': 0,
      'totalDistance': 0.0,
      'speciesSpotted': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
