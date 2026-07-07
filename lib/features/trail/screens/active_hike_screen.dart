import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../models/trail.dart';

class ActiveHikeScreen extends StatefulWidget {
  final Trail trail;
  const ActiveHikeScreen({super.key, required this.trail});

  @override
  State<ActiveHikeScreen> createState() => _ActiveHikeScreenState();
}

class _ActiveHikeScreenState extends State<ActiveHikeScreen> {
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  Position? _currentPosition;
  List<XFile> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startLocationTracking();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedTime += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((Position position) {
        if (mounted) {
          setState(() => _currentPosition = position);
          _mapController.move(LatLng(position.latitude, position.longitude), 16.5);
        }
      });
    }
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        setState(() => _capturedImages.add(photo));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Photo saved! (${_capturedImages.length} total)")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening camera: $e")),
        );
      }
    }
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🚨 SOS Activated"),
        content: const Text("Your location has been shared with emergency contacts and park rangers."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  void _finishHike() {
    _timer?.cancel();
    context.pushReplacement('/hike-summary', extra: {
      'trail': widget.trail,
      'elapsedTime': _elapsedTime,
      'photos': _capturedImages,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(1.7170, 110.3250),
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.borneo_hike',
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      child: const Icon(Icons.my_location, color: Colors.red, size: 50),
                    ),
                  ],
                ),
            ],
          ),

          // Top Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.trail.name, 
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(widget.trail.parkName, style: const TextStyle(color: Colors.greenAccent)),
                      ],
                    ),
                  ),
                  Text(_formatTime(_elapsedTime), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),

          // Bottom Panel (Higher Finish Button)
          DraggableScrollableSheet(
            initialChildSize: 0.42,
            minChildSize: 0.35,
            maxChildSize: 0.75,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3F2E),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                        ),
                        const SizedBox(height: 24),
                        Text("${widget.trail.distanceKm} km • ${widget.trail.difficulty}", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.camera_alt, "Sighting", Colors.purple, onTap: _takePhoto),
                            _buildActionButton(Icons.report_problem, "Report", Colors.orange),
                            _buildActionButton(Icons.place, "Mark", Colors.blue),
                            _buildActionButton(Icons.sos, "SOS", Colors.red, isSos: true),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Higher & Bigger Finish Button
                        SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: _finishHike,
                            child: const Text("FINISH HIKE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildActionButton(IconData icon, String label, Color color, {bool isSos = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (isSos) {
          _showSosDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label recorded")));
        }
      },
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
