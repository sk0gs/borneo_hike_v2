import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../models/trail.dart';

class TrailDetailScreen extends StatelessWidget {
  final Trail trail;
  const TrailDetailScreen({super.key, required this.trail});

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2ECC71);
      case 'hard':
        return Colors.redAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F18),
      body: CustomScrollView(
        slivers: [
          // Map header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF0A1F18),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(trail.latitude, trail.longitude),
                  initialZoom: 13.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.borneo_hike_v2',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(trail.latitude, trail.longitude),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2ECC71),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2ECC71).withValues(alpha: 0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.terrain_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trail.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trail.parkName,
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _difficultyColor(trail.difficulty)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _difficultyColor(trail.difficulty)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        trail.difficulty,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _difficultyColor(trail.difficulty),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF112D24),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      _TrailStat(
                        value: '${trail.distanceKm}',
                        unit: 'km',
                        label: 'Distance',
                      ),
                      _buildDivider(),
                      _TrailStat(
                        value: trail.formattedEstTime,
                        unit: '',
                        label: 'Est. Time',
                      ),
                      _buildDivider(),
                      _TrailStat(
                        value: '${trail.elevationGain}',
                        unit: 'm',
                        label: 'Elevation',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Description
                if (trail.description.isNotEmpty) ...[
                  const Text(
                    'About this trail',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    trail.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/safety-checkin', extra: trail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Start This Hike',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 48, color: Colors.white.withValues(alpha: 0.1));
  }
}

class _TrailStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _TrailStat({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
