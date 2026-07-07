import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/trail_service.dart';
import '../models/trail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrailService _trailService = TrailService();
  String userName = "Hiker";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BorneoHike")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Good Morning, $userName", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // DIAGNOSTIC BOX
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.withAlpha(30),
              child: Text("DEBUG: User is ${FirebaseAuth.instance.currentUser == null ? 'LOGGED OUT' : 'LOGGED IN'}", style: TextStyle(fontSize: 10)),
            ),

            const SizedBox(height: 20),
            const Text("Available Trails", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            StreamBuilder<List<Trail>>(
              stream: _trailService.getTrails(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red, fontSize: 12));
                if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                
                final trails = snapshot.data ?? [];
                if (trails.isEmpty) return const Text("No trails found. Please check your Firestore 'trails' collection.");

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trails.length,
                  itemBuilder: (context, index) {
                    final trail = trails[index];
                    return ListTile(
                      leading: Text(trail.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(trail.name),
                      subtitle: Text(trail.parkName),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
