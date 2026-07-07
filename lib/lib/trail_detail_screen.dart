import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/trail.dart';

class TrailDetailScreen extends StatelessWidget {
  final Trail trail;
  const TrailDetailScreen({super.key, required this.trail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(trail.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      trail.color.withOpacity(0.8),
                      trail.color,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    trail.emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("${trail.distanceKm} km", "Distance"),
                      _buildStat(trail.formattedEstTime, "Est. Time"),
                      _buildStat("${trail.elevationGain}m", "Elevation"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Chip(
                        label: Text(trail.difficulty),
                        backgroundColor: _getDifficultyColor(trail.difficulty).withOpacity(0.2),
                        side: BorderSide(color: _getDifficultyColor(trail.difficulty)),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(trail.parkName),
                        backgroundColor: Colors.white10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "About this trail",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    trail.description,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      onPressed: () => context.push('/safety-checkin', extra: trail),
                      child: const Text(
                        "START THIS HIKE",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
