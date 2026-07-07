import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../../models/trail.dart';
import 'package:borneo_hike_v2/features/hike/screens/hike_summary_screen.dart';

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
  List<XFile> capturedImages = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startLocationTracking();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsedTime += const Duration(seconds: 1));
    });
  }

  Future<void> _startLocationTracking() async {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() => _currentPosition = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 16.5);
    });
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => capturedImages.add(photo));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo saved! (${capturedImages.length} total)")),
      );
    }
  }

  void _finishHike() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HikeSummaryScreen(
          trail: widget.trail,
          elapsedTime: _elapsedTime,
          photos: capturedImages,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(1.7170, 110.3250),
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
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
              color: Colors.black.withOpacity(0.75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.trail.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(widget.trail.parkName, style: const TextStyle(color: Colors.green)),
                    ],
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
                decoration: const BoxDecoration(
                  color: Color(0xFF1A3F2E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("${widget.trail.distanceKm} km • ${widget.trail.difficulty}"),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(Icons.camera_alt, "Sighting", Colors.purple, onTap: _takePhoto),
                          _buildActionButton(Icons.report_problem, "Report", Colors.orange),
                          _buildActionButton(Icons.place, "Mark", Colors.blue),
                          _buildActionButton(Icons.sos, "SOS", Colors.red, isSos: true),
                        ],
                      ),

                      const Spacer(),

                      // Higher & Bigger Finish Button
                      SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _finishHike,
                          child: const Text("FINISH HIKE"),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
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
        if (isSos) _showSosDialog();
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label recorded")));
      },
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🚨 SOS Activated"),
        content: const Text("Your location has been shared with emergency contacts."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }
}