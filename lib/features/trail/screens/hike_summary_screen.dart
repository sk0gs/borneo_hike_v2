import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/trail.dart';

class HikeSummaryScreen extends StatelessWidget {
  final Trail trail;
  final Duration elapsedTime;
  final List<XFile> photos;

  const HikeSummaryScreen({
    super.key,
    required this.trail,
    required this.elapsedTime,
    required this.photos,
  });

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hike Summary"), 
        backgroundColor: Colors.green[700],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.celebration, size: 80, color: Colors.green),
            const Text("Great Job!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text("You completed ${trail.name}", style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 30),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _formatTime(elapsedTime), 
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)
                    ),
                    const Text("Total Time", style: TextStyle(fontSize: 16)),
                    const Divider(height: 30),
                    Text(
                      "${trail.distanceKm} km", 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                    ),
                    const Text("Distance"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (photos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Photos Captured", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(photos[index].path), 
                              height: 120, 
                              width: 120, 
                              fit: BoxFit.cover
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("Back to Home", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
