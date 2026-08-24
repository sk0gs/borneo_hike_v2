import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../models/trail.dart';
import '../../../services/location_weather_service.dart';
import '../../../services/unit_service.dart';

class TrailDetailScreen extends StatefulWidget {
  final Trail trail;
  const TrailDetailScreen({super.key, required this.trail});

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  AqiData? _aqi;
  bool _aqiLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAqi();
  }

  Future<void> _loadAqi() async {
    try {
      final aqi = await LocationWeatherService.getAqi(
        widget.trail.latitude,
        widget.trail.longitude,
      );
      if (mounted) setState(() { _aqi = aqi; _aqiLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _aqi = AqiData.unavailable; _aqiLoading = false; });
    }
  }

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
    final trail = widget.trail;
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
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF2ECC71).withValues(alpha: 0.5),
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
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
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
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      ValueListenableBuilder<DistanceUnit>(
                        valueListenable: UnitService.distanceUnitNotifier,
                        builder: (context, _, __) {
                          return _TrailStat(
                            value: UnitService.formatDistanceValue(trail.distanceKm),
                            unit: UnitService.distanceSymbol,
                            label: 'Distance',
                          );
                        },
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

                // ── AQI safety banner ─────────────────────────────────
                _buildAqiBanner(),
                const SizedBox(height: 20),

                // ── CTA ───────────────────────────────────────────────
                if (!_aqiLoading && _aqi?.isDangerous == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Air quality is poor — proceed with caution',
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange[300]),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/safety-checkin', extra: trail),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (!_aqiLoading && _aqi?.isDangerous == true)
                              ? Colors.orange
                              : const Color(0xFF2ECC71),
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

  // ── AQI banner ──────────────────────────────────────────────────────────────

  Widget _buildAqiBanner() {
    if (_aqiLoading) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF112D24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2ECC71),
            ),
          ),
        ),
      );
    }

    final aqi = _aqi ?? AqiData.unavailable;
    final accentColor = aqi.color;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF112D24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          'Air Quality — Trail Location',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        Text(aqi.emoji,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // AQI value + category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          aqi.isUnavailable ? '--' : '${aqi.usAqi}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  aqi.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress bar
                    if (!aqi.isUnavailable) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: aqi.barProgress,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.07),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(accentColor),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Advice
                    Text(
                      aqi.advice,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500], height: 1.4),
                    ),

                    // Pollutant chips
                    if (!aqi.isUnavailable) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip('PM2.5',
                              '${aqi.pm25.toStringAsFixed(1)} μg/m³'),
                          const SizedBox(width: 6),
                          _chip('PM10',
                              '${aqi.pm10.toStringAsFixed(0)} μg/m³'),
                          const SizedBox(width: 6),
                          _chip('CO', '${aqi.co.toStringAsFixed(0)} μg/m³'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
        width: 1, height: 48, color: Colors.white.withValues(alpha: 0.1));
  }
}

// ── Trail stat cell ────────────────────────────────────────────────────────────

class _TrailStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _TrailStat(
      {required this.value, required this.unit, required this.label});

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
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
