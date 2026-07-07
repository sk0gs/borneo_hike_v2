import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:borneo_hike_v2/services/location_weather_service.dart';
import 'package:borneo_hike_v2/services/user_service.dart';
import 'package:borneo_hike_v2/services/trail_service.dart';
import 'package:borneo_hike_v2/models/trail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserService();
  final _trailService = TrailService();
  String _greeting = 'Good Morning';
  String _userName = 'Hiker';
  WeatherData? _weather;
  bool _weatherLoading = true;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadData();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUserData(), _loadWeather()]);
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getUser();
      if (user != null && mounted) {
        setState(() => _userName = user.name.split(' ').first);
      }
    } catch (e) {
      debugPrint('User data error: $e');
    }
  }

  Future<void> _loadWeather() async {
    try {
      final pos = await LocationWeatherService.getCurrentPosition();
      final weather = await LocationWeatherService.getWeather(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _weather = weather;
          _weatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weather = WeatherData.fallback;
          _weatherLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F18),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF2ECC71),
        backgroundColor: const Color(0xFF1A3F2E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: const Color(0xFF0A1F18),
              pinned: true,
              title: const Text(
                'BorneoHike',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
              ),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1A3F2E),
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'H',
                      style: const TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              // Increased bottom padding to 240 so content clears the high floating nav bar
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 240),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('$_greeting,', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  Text(_userName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 24),
                  _buildWeatherCard(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Text('Available Trails', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      const Spacer(),
                      Text('See all', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTrailsList(),
                  const SizedBox(height: 32),
                  const Text('Latest from Borneo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 16),
                  _buildArticlesList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weatherLoading) {
      return Container(height: 120, decoration: BoxDecoration(color: const Color(0xFF112D24), borderRadius: BorderRadius.circular(16)), child: const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71))));
    }
    final w = _weather ?? WeatherData.fallback;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF112D24), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${w.temperature.round()}', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w200, color: Colors.white, height: 1)),
              const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('°C', style: TextStyle(fontSize: 20, color: Colors.white60))),
            ]),
            Text(w.description, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            Text('Feels like ${w.feelsLike.round()}°C • H:${w.tempHigh.round()}° L:${w.tempLow.round()}°', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Icon(w.icon, size: 40, color: const Color(0xFF2ECC71)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: w.isGoodForHiking ? const Color(0xFF2ECC71).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(w.isGoodForHiking ? 'Good for hiking' : 'Use caution', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: w.isGoodForHiking ? const Color(0xFF2ECC71) : Colors.orange)),
            ),
          ]),
        ]),
        const SizedBox(height: 20),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildWeatherDetail(Icons.water_drop_outlined, '${w.humidity.round()}%', 'Humidity'),
          _buildWeatherDetail(Icons.air, '${w.windSpeed.round()} km/h', 'Wind'),
          _buildWeatherDetail(Icons.wb_sunny_outlined, 'UV ${w.uvIndex}', 'UV Index'),
        ]),
      ]),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: Colors.grey[500], size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }

  Widget _buildTrailsList() {
    return StreamBuilder<List<Trail>>(
      stream: _trailService.getTrails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF2ECC71))));
        if (snapshot.hasError) return _buildErrorTile('Connection error. Check Firebase rules.');
        final trails = snapshot.data ?? [];
        if (trails.isEmpty) return Text('No trails available.', style: TextStyle(color: Colors.grey[600], fontSize: 14));
        return Column(children: trails.map((trail) => _TrailCard(trail: trail, onTap: () => context.push('/trail-detail', extra: trail))).toList());
      },
    );
  }

  Widget _buildArticlesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('articles').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorTile('Failed to load articles.');
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Text('Check back later for news.', style: TextStyle(color: Colors.grey[600], fontSize: 14));
        return Column(children: snapshot.data!.docs.map((doc) {
          final article = doc.data() as Map<String, dynamic>;
          return _ArticleCard(article: article, onTap: () => context.push('/article-detail', extra: doc));
        }).toList());
      },
    );
  }

  Widget _buildErrorTile(String message) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.2))), child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 13)));
  }
}

class _TrailCard extends StatelessWidget {
  final Trail trail;
  final VoidCallback onTap;
  const _TrailCard({required this.trail, required this.onTap});
  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy': return const Color(0xFF2ECC71);
      case 'hard': return Colors.redAccent;
      default: return Colors.orangeAccent;
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF112D24), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: trail.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.terrain_rounded, color: trail.color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trail.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
            const SizedBox(height: 2),
            Text('${trail.parkName} • ${trail.distanceKm} km', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _difficultyColor(trail.difficulty).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Text(trail.difficulty, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _difficultyColor(trail.difficulty)))),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[700], size: 20),
        ]),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Map<String, dynamic> article;
  final VoidCallback onTap;
  const _ArticleCard({required this.article, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: const Color(0xFF112D24), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (article['imageUrl'] != null)
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(article['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: const Color(0xFF1A3F2E), child: Icon(Icons.image_outlined, color: Colors.grey[700], size: 36)))),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(article['title'] ?? 'Untitled', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 6),
            Text('${article['readTime'] ?? 5} min read • ${article['category'] ?? 'Nature'}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        ]),
      ),
    );
  }
}
