import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../models/trail.dart';
import '../../../services/trail_service.dart';

class HikeSummaryScreen extends StatefulWidget {
  final Trail trail;
  final Duration elapsedTime;
  final List<XFile> photos;
  final List<LatLng> routePoints;
  final double distanceKm;

  const HikeSummaryScreen({
    super.key,
    required this.trail,
    required this.elapsedTime,
    required this.photos,
    this.routePoints = const [],
    this.distanceKm = 0.0,
  });

  @override
  State<HikeSummaryScreen> createState() => _HikeSummaryScreenState();
}

class _HikeSummaryScreenState extends State<HikeSummaryScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveToFirestore();
  }

  Future<void> _saveToFirestore() async {
    try {
      await TrailService().saveHikeSummary(
        trail: widget.trail,
        elapsedTime: widget.elapsedTime,
        distanceKm: widget.distanceKm > 0 ? widget.distanceKm : widget.trail.distanceKm,
        elevationGain: widget.trail.elevationGain,
      );
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      debugPrint('Save hike error: $e');
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  String _formatPace(Duration elapsed, double distanceKm) {
    if (distanceKm < 0.01 || elapsed.inSeconds < 1) return '--';
    final paceSeconds = elapsed.inSeconds / distanceKm;
    final paceMin = (paceSeconds / 60).floor();
    final paceSec = (paceSeconds % 60).round();
    return "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";
  }

  double get _effectiveDistance =>
      widget.distanceKm > 0 ? widget.distanceKm : widget.trail.distanceKm;

  int get _calories => (_effectiveDistance * 65).toInt();

  @override
  Widget build(BuildContext context) {
    final routeCenter = widget.routePoints.isNotEmpty
        ? widget.routePoints[widget.routePoints.length ~/ 2]
        : LatLng(widget.trail.latitude, widget.trail.longitude);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F18),
      body: CustomScrollView(
        slivers: [
          // Map preview at top
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: routeCenter,
                      initialZoom: widget.routePoints.length > 1 ? 14.5 : 13.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.borneo_hike_v2',
                      ),
                      if (widget.routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: widget.routePoints,
                              color: const Color(0xFF2ECC71),
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      if (widget.routePoints.isNotEmpty) ...[
                        MarkerLayer(markers: [
                          // Start marker
                          Marker(
                            point: widget.routePoints.first,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF2ECC71),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // End marker
                          Marker(
                            point: widget.routePoints.last,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                  // Dark gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0A1F18).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                Text(
                  widget.trail.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.trail.parkName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),

                const SizedBox(height: 4),

                // Saved indicator
                Row(
                  children: [
                    Icon(
                      _saved ? Icons.check_circle_outline : Icons.sync,
                      size: 14,
                      color: _saved ? const Color(0xFF2ECC71) : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _saved ? 'Saved to your history' : 'Saving...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _saved ? const Color(0xFF2ECC71) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Primary stats grid (Strava-style)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF112D24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    children: [
                      // Row 1: Distance + Time
                      Row(
                        children: [
                          _SummaryPrimaryStat(
                            value: _effectiveDistance.toStringAsFixed(2),
                            unit: 'km',
                            label: 'Distance',
                          ),
                          Container(
                              width: 1,
                              height: 56,
                              color: Colors.white.withValues(alpha: 0.1)),
                          _SummaryPrimaryStat(
                            value: _formatDuration(widget.elapsedTime),
                            unit: '',
                            label: 'Moving Time',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                      const SizedBox(height: 20),

                      // Row 2: Pace + Elevation + Calories
                      Row(
                        children: [
                          _SummarySecondaryStat(
                            value: _formatPace(widget.elapsedTime, _effectiveDistance),
                            label: 'Avg Pace',
                          ),
                          _SummarySecondaryStat(
                            value: '${widget.trail.elevationGain} m',
                            label: 'Elev Gain',
                          ),
                          _SummarySecondaryStat(
                            value: '$_calories',
                            label: 'Calories',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Photos section
                if (widget.photos.isNotEmpty) ...[
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.photos[index].path),
                            height: 160,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Achievement row
                _buildAchievementRow(),

                const SizedBox(height: 28),

                // Done button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildAchievementRow() {
    final isPersonalBest = _effectiveDistance >= widget.trail.distanceKm * 0.95;
    final isPaceGood = widget.elapsedTime.inMinutes > 0 &&
        (_effectiveDistance / (widget.elapsedTime.inMinutes / 60)) > 3;

    return Row(
      children: [
        if (isPersonalBest) ...[
          _AchievementBadge(icon: Icons.emoji_events_outlined, label: 'Trail Complete'),
          const SizedBox(width: 10),
        ],
        if (isPaceGood)
          _AchievementBadge(icon: Icons.speed_outlined, label: 'Strong Pace'),
      ],
    );
  }
}

// ── Stat Widgets ─────────────────────────────────────────────────────────────

class _SummaryPrimaryStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _SummaryPrimaryStat({
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySecondaryStat extends StatelessWidget {
  final String value;
  final String label;

  const _SummarySecondaryStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AchievementBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2ECC71), size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2ECC71),
            ),
          ),
        ],
      ),
    );
  }
}
