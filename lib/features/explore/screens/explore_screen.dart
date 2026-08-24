import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:borneo_hike_v2/core/theme/app_theme.dart';
import 'package:borneo_hike_v2/services/unit_service.dart';
import 'package:borneo_hike_v2/models/trail.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedDifficulty = 'All';
  final List<String> _difficulties = ['All', 'Easy', 'Moderate', 'Hard'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _focusTrail(Trail trail) {
    _mapController.move(LatLng(trail.latitude, trail.longitude), 14.0);
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
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: theme.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search trails or parks...',
                      hintStyle: TextStyle(color: theme.subTextColor, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: theme.subTextColor, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: theme.subTextColor, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primaryAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Difficulty chips
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _difficulties.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final d = _difficulties[i];
                        final isSelected = _selectedDifficulty == d;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDifficulty = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryAccent
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryAccent
                                    : theme.borderColor,
                              ),
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.black : theme.subTextColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Map & List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('trails').snapshots(),
              builder: (context, snapshot) {
                List<Marker> markers = [];
                List<Trail> allTrails = [];

                if (snapshot.hasData) {
                  allTrails = snapshot.data!.docs
                      .map((doc) => Trail.fromFirestore(doc))
                      .toList();

                  markers = allTrails.map((trail) {
                    return Marker(
                      point: LatLng(trail.latitude, trail.longitude),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => context.push('/trail-detail', extra: trail),
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.primaryAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryAccent.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.terrain_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }).toList();
                }

                // Filter for trail list
                var displayTrails = allTrails;
                if (_searchQuery.isNotEmpty) {
                  displayTrails = displayTrails
                      .where((t) =>
                          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          t.parkName.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }
                if (_selectedDifficulty != 'All') {
                  displayTrails = displayTrails
                      .where((t) => t.difficulty == _selectedDifficulty)
                      .toList();
                }

                return Expanded(
                  child: Column(
                    children: [
                      // Map
                      Expanded(
                        flex: 11,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: const MapOptions(
                                initialCenter: LatLng(1.7170, 110.3250),
                                initialZoom: 10,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.borneo_hike_v2',
                                ),
                                MarkerLayer(markers: markers),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Trail list
                      Expanded(
                        flex: 9,
                        child: displayTrails.isEmpty
                            ? Center(
                                child: Text(
                                  'No trails found.',
                                  style: TextStyle(color: theme.subTextColor),
                                ),
                              )
                            : ValueListenableBuilder<DistanceUnit>(
                                valueListenable: UnitService.distanceUnitNotifier,
                                builder: (context, _, __) {
                                  return ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                                    itemCount: displayTrails.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final trail = displayTrails[i];
                                      return GestureDetector(
                                        onTap: () => context.push('/trail-detail', extra: trail),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: theme.cardColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: theme.borderColor),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      trail.name,
                                                      style: TextStyle(
                                                        color: theme.textColor,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${trail.parkName}  •  ${UnitService.formatDistance(trail.distanceKm)}  •  ${trail.difficulty}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme.subTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.my_location_rounded,
                                                  color: _difficultyColor(trail.difficulty),
                                                  size: 20,
                                                ),
                                                onPressed: () => _focusTrail(trail),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
