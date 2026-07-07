import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import '../../../models/trail.dart';

class ActiveHikeScreen extends StatefulWidget {
  final Trail trail;
  const ActiveHikeScreen({super.key, required this.trail});

  @override
  State<ActiveHikeScreen> createState() => _ActiveHikeScreenState();
}

class _ActiveHikeScreenState extends State<ActiveHikeScreen> {
  final _mapController = MapController();
  final _picker = ImagePicker();

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  Position? _currentPosition;
  final List<LatLng> _routePoints = [];
  double _totalDistanceKm = 0.0;
  StreamSubscription<Position>? _locationSub;
  final List<XFile> _photos = [];

  bool _isPaused = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startLocationTracking();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _startLocationTracking() async {
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (_isPaused || !mounted) return;

      final newPoint = LatLng(position.latitude, position.longitude);

      if (_routePoints.isNotEmpty) {
        final last = _routePoints.last;
        final dist = const Distance().as(LengthUnit.Meter, last, newPoint);
        _totalDistanceKm += dist / 1000;
      }

      setState(() {
        _currentPosition = position;
        _routePoints.add(newPoint);
      });

      _mapController.move(newPoint, 16.5);
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _capturePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _photos.add(image));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved')),
        );
      }
    }
  }

  Future<void> _finishHike() async {
    setState(() => _isFinishing = true);
    _timer?.cancel();
    await _locationSub?.cancel();

    if (mounted) {
      context.pushReplacement('/hike-summary', extra: {
        'trail': widget.trail,
        'elapsedTime': _elapsed,
        'distanceKm': _totalDistanceKm,
        'routePoints': _routePoints,
        'photos': _photos,
      });
    }
  }

  String _formatTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double get _currentPace {
    if (_totalDistanceKm < 0.01 || _elapsed.inSeconds < 1) return 0;
    return (_elapsed.inSeconds / 60) / _totalDistanceKm;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialLocation = LatLng(widget.trail.latitude, widget.trail.longitude);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.borneo_hike_v2',
              ),
              // Route polyline
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF2ECC71),
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Current location marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          _currentPosition!.latitude, _currentPosition!.longitude),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2ECC71).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Top bar: trail name + timer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.trail.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.trail.parkName,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF2ECC71)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(_elapsed),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom panel
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.28,
            maxChildSize: 0.55,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0A1F18),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Live stats
                        Row(
                          children: [
                            _LiveStat(
                              value:
                                  '${_totalDistanceKm.toStringAsFixed(2)}',
                              unit: 'km',
                              label: 'Distance',
                            ),
                            _buildStatDivider(),
                            _LiveStat(
                              value: _currentPace > 0
                                  ? _currentPace.toStringAsFixed(1)
                                  : '--',
                              unit: '/km',
                              label: 'Pace (min)',
                            ),
                            _buildStatDivider(),
                            _LiveStat(
                              value:
                                  '${(_totalDistanceKm * 65).toInt()}',
                              unit: 'kcal',
                              label: 'Calories',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action buttons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ActionCircle(
                              icon: Icons.camera_alt_outlined,
                              label: 'Photo',
                              onTap: _capturePhoto,
                            ),
                            _ActionCircle(
                              icon: Icons.flag_outlined,
                              label: 'Mark',
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text('Waypoint marked'))),
                            ),
                            _ActionCircle(
                              icon: Icons.report_outlined,
                              label: 'Report',
                              color: Colors.orangeAccent,
                              onTap: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text('Hazard reported'))),
                            ),
                            _ActionCircle(
                              icon: Icons.sos_rounded,
                              label: 'SOS',
                              color: Colors.redAccent,
                              onTap: () {},
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Pause / Finish
                        Row(
                          children: [
                            // Pause
                            GestureDetector(
                              onTap: _togglePause,
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3F2E),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1)),
                                ),
                                child: Icon(
                                  _isPaused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Finish
                            Expanded(
                              child: GestureDetector(
                                onTap: _isFinishing ? null : _finishHike,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: _isFinishing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Text(
                                            'Finish Hike',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
        width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1));
  }
}

class _LiveStat extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _LiveStat({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF2ECC71),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}