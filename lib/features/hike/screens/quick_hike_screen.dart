import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../models/trail.dart';
import '../../../services/trail_service.dart';
import '../../../services/unit_service.dart';
import '../../../core/theme/app_theme.dart';

class QuickHikeScreen extends StatefulWidget {
  const QuickHikeScreen({super.key});

  @override
  State<QuickHikeScreen> createState() => _QuickHikeScreenState();
}

class _QuickHikeScreenState extends State<QuickHikeScreen> {
  final _trailService = TrailService();
  bool _isLocating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _ensureLocation();
  }

  Future<void> _ensureLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied.');
      }

      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _locationError = e.toString());
    } finally {
      if (mounted) setState(() => _isLocating = false);
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
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start a Hike',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location status
                  Row(
                    children: [
                      Icon(
                        _isLocating
                            ? Icons.gps_not_fixed_rounded
                            : (_locationError != null
                                ? Icons.gps_off_rounded
                                : Icons.gps_fixed_rounded),
                        size: 14,
                        color: _isLocating
                            ? Colors.grey[600]
                            : (_locationError != null
                                ? Colors.orangeAccent
                                : const Color(0xFF2ECC71)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLocating
                            ? 'Getting location...'
                            : (_locationError != null
                                ? 'Location unavailable'
                                : 'Location ready'),
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLocating
                              ? Colors.grey[600]
                              : (_locationError != null
                                  ? Colors.orangeAccent
                                  : Colors.grey[500]),
                        ),
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _ensureLocation,
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF2ECC71),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<List<Trail>>(
                stream: _trailService.getTrails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF2ECC71), strokeWidth: 2),
                    );
                  }

                  final trails = snapshot.data ?? [];

                  if (trails.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.terrain_outlined,
                              size: 48, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text(
                            'No trails available.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: trails.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final trail = trails[index];
                      return GestureDetector(
                        onTap: () =>
                            context.push('/safety-checkin', extra: trail),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: trail.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.terrain_rounded,
                                    color: trail.color, size: 24),
                              ),
                              const SizedBox(width: 14),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trail.name,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trail.parkName,
                                      style: TextStyle(
                                          fontSize: 12, color: theme.subTextColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ValueListenableBuilder<DistanceUnit>(
                                          valueListenable: UnitService.distanceUnitNotifier,
                                          builder: (context, _, __) {
                                            return _InfoChip(
                                              label: UnitService.formatDistance(trail.distanceKm),
                                              icon: Icons.straighten_rounded,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _InfoChip(
                                          label: trail.formattedEstTime,
                                          icon: Icons.schedule_outlined,
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _difficultyColor(trail.difficulty)
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            trail.difficulty,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _difficultyColor(trail.difficulty),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.play_circle_outline_rounded,
                                  color: const Color(0xFF2ECC71), size: 28),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
