import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
            const SizedBox(height: 16),
            const Text("Daanish", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Kuching, Sarawak", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),
            const ListTile(
              leading: Icon(Icons.hiking), 
              title: Text("Total Hikes"), 
              trailing: Text("12", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const ListTile(
              leading: Icon(Icons.straighten), 
              title: Text("Total Distance"), 
              trailing: Text("87 km", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const ListTile(
              leading: Icon(Icons.emoji_nature), 
              title: Text("Species Spotted"), 
              trailing: Text("18", style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                // Logout logic
              },
            ),
          ],
        ),
      ),
    );
  }
}
