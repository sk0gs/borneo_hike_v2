import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/trail.dart';
import '../../../services/trail_service.dart';
import '../../../services/location_weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TrailService _trailService = TrailService();
  final User? _user = FirebaseAuth.instance.currentUser;
  
  String temperature = "--°C";
  String weatherDesc = "Loading weather...";
  IconData weatherIcon = Icons.cloud_outlined;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final pos = await LocationWeatherService.getCurrentPosition();
      final weather = await LocationWeatherService.getWeather(pos.latitude, pos.longitude);
      
      if (!mounted) return;

      final int weatherCode = weather['current']?['weather_code'] ?? 0;
      final String desc = LocationWeatherService.getWeatherDescription(weatherCode);
      final IconData icon = LocationWeatherService.getWeatherIcon(weatherCode);

      setState(() {
        temperature = "${weather['current']?['temperature_2m'] ?? "--"}°C";
        weatherDesc = desc;
        weatherIcon = icon;
      });
    } catch (e) {
      debugPrint("Weather/GPS Error: $e");
      if (!mounted) return;
      setState(() {
        weatherDesc = "Weather unavailable";
        weatherIcon = Icons.error_outline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = _user?.email?.split('@')[0] ?? "Hiker";
    if (displayName.isNotEmpty) {
      displayName = displayName[0].toUpperCase() + displayName.substring(1);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("BorneoHike", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome, $displayName 👋", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Where are you hiking today?", style: TextStyle(fontSize: 16, color: Colors.grey)),

              const SizedBox(height: 20),

              // Weather Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(weatherIcon, size: 45, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$temperature • Kuching", 
                              style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(weatherDesc, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _loadWeather,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const Text("Available Trails", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

              const SizedBox(height: 12),

              // Real-time Trails from Firestore
              StreamBuilder<List<Trail>>(
                stream: _trailService.getTrails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Text("Error loading trails: ${snapshot.error}");
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No trails available in database.");
                  }

                  final trails = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trails.length,
                    itemBuilder: (context, index) {
                      final trail = trails[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: trail.color.withAlpha(50),
                            child: Text(trail.emoji, style: const TextStyle(fontSize: 24)),
                          ),
                          title: Text(trail.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${trail.parkName} • ${trail.distanceKm} km • ${trail.difficulty}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            context.push('/trail-detail', extra: trail);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
