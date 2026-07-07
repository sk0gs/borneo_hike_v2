class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final int totalHikes;
  final double totalDistance;
  final int speciesSpotted;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.totalHikes = 0,
    this.totalDistance = 0.0,
    this.speciesSpotted = 0,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? 'Hiker',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      totalHikes: data['totalHikes'] ?? 0,
      totalDistance: (data['totalDistance'] ?? 0).toDouble(),
      speciesSpotted: data['speciesSpotted'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'totalHikes': totalHikes,
      'totalDistance': totalDistance,
      'speciesSpotted': speciesSpotted,
    };
  }
}
