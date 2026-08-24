import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:borneo_hike_v2/core/theme/app_theme.dart';
import 'package:borneo_hike_v2/services/location_weather_service.dart';
import 'package:borneo_hike_v2/services/user_service.dart';
import 'package:borneo_hike_v2/services/trail_service.dart';
import 'package:borneo_hike_v2/services/unit_service.dart';
import 'package:borneo_hike_v2/models/trail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  final TrailService _trailService = TrailService();

  String _greeting = 'Good Morning';
  String _userName = 'Hiker';
  WeatherData? _weather;
  AqiData? _aqi;
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
    _loadUser();
    _loadWeather();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getUser();
    if (user != null && mounted) {
      setState(() => _userName = user.name);
    }
  }

  Future<void> _loadWeather() async {
    try {
      final pos = await LocationWeatherService.getCurrentPosition();
      final weatherFuture =
          LocationWeatherService.getWeather(pos.latitude, pos.longitude);
      final aqiFuture =
          LocationWeatherService.getAqi(pos.latitude, pos.longitude);
      final weather = await weatherFuture;
      final aqi = await aqiFuture;
      if (mounted) {
        setState(() {
          _weather = weather;
          _aqi = aqi;
          _weatherLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weather = WeatherData.fallback;
          _aqi = AqiData.unavailable;
          _weatherLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bgColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: theme.primaryAccent,
        backgroundColor: theme.cardSecondaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: theme.bgColor,
              pinned: true,
              title: Text(
                'BorneoHike',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: theme.textColor,
                ),
              ),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.cardSecondaryColor,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'H',
                      style: TextStyle(
                        color: theme.primaryAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 240),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    '$_greeting,',
                    style: TextStyle(fontSize: 14, color: theme.subTextColor),
                  ),
                  Text(
                    _userName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildWeatherCard(theme),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        'Available Trails',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'See all',
                        style: TextStyle(fontSize: 13, color: theme.subTextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTrailsList(theme),
                  const SizedBox(height: 32),
                  Text(
                    'Latest from Borneo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildArticlesList(theme),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(AppTheme theme) {
    if (_weatherLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: theme.primaryAccent,
          ),
        ),
      );
    }

    final w = _weather ?? WeatherData.fallback;
    final aqi = _aqi;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Weather ──────────────────────────────────────────────────
          ValueListenableBuilder<TemperatureUnit>(
            valueListenable: UnitService.tempUnitNotifier,
            builder: (context, _, __) {
              final tempInt = UnitService.formatTempInt(w.temperature);
              final feelsLikeInt = UnitService.formatTempInt(w.feelsLike);
              final tempHighInt = UnitService.formatTempInt(w.tempHigh);
              final tempLowInt = UnitService.formatTempInt(w.tempLow);
              final unitSymbol = UnitService.tempSymbol;

              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      '$tempInt',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w200,
                        color: theme.textColor,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        unitSymbol,
                        style: TextStyle(
                          fontSize: 20,
                          color: theme.subTextColor,
                        ),
                      ),
                    ),
                  ]),
                  Text(
                    w.description,
                    style: TextStyle(fontSize: 14, color: theme.subTextColor),
                  ),
                  Text(
                    'Feels like $feelsLikeInt$unitSymbol • H:$tempHighInt° L:$tempLowInt°',
                    style: TextStyle(fontSize: 12, color: theme.subTextColor),
                  ),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Icon(w.icon, size: 40, color: theme.primaryAccent),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: w.isGoodForHiking
                          ? theme.primaryAccent.withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      w.isGoodForHiking ? 'Good for hiking' : 'Use caution',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: w.isGoodForHiking
                            ? theme.primaryAccent
                            : Colors.orange,
                      ),
                    ),
                  ),
                ]),
              ]);
            },
          ),

          const SizedBox(height: 20),
          Divider(color: theme.borderColor, height: 1),
          const SizedBox(height: 16),

          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildWeatherDetail(
              theme,
              Icons.water_drop_outlined,
              '${w.humidity.round()}%',
              'Humidity',
            ),
            ValueListenableBuilder<DistanceUnit>(
              valueListenable: UnitService.distanceUnitNotifier,
              builder: (context, _, __) {
                return _buildWeatherDetail(
                  theme,
                  Icons.air,
                  UnitService.formatWindSpeed(w.windSpeed),
                  'Wind',
                );
              },
            ),
            _buildWeatherDetail(
              theme,
              Icons.wb_sunny_outlined,
              'UV ${w.uvIndex}',
              'UV Index',
            ),
          ]),

          // ── AQI strip ────────────────────────────────────────────────
          if (aqi != null) _buildAqiStrip(theme, aqi),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(AppTheme theme, IconData icon, String value, String label) {
    return Column(children: [
      Icon(icon, color: theme.subTextColor, size: 18),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.textColor,
        ),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: theme.subTextColor)),
    ]);
  }

  // ── AQI strip ────────────────────────────────────────────────────────────────

  Widget _buildAqiStrip(AppTheme theme, AqiData aqi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(color: theme.borderColor, height: 1),
        const SizedBox(height: 14),

        // Header row
        Row(
          children: [
            Text(
              'AIR QUALITY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.subTextColor,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(aqi.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            if (!aqi.isUnavailable)
              Text(
                '${aqi.usAqi}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: aqi.color,
                ),
              ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: aqi.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                aqi.category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: aqi.color,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: aqi.barProgress,
            backgroundColor: theme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(aqi.color),
            minHeight: 6,
          ),
        ),

        const SizedBox(height: 10),

        // Advice
        Text(
          aqi.advice,
          style: TextStyle(fontSize: 12, color: theme.subTextColor),
        ),

        // Pollutant chips
        if (!aqi.isUnavailable) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPollutantChip(
                theme,
                'PM2.5',
                '${aqi.pm25.toStringAsFixed(1)} μg/m³',
              ),
              const SizedBox(width: 8),
              _buildPollutantChip(
                theme,
                'PM10',
                '${aqi.pm10.toStringAsFixed(0)} μg/m³',
              ),
              const SizedBox(width: 8),
              _buildPollutantChip(
                theme,
                'CO',
                '${aqi.co.toStringAsFixed(0)} μg/m³',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPollutantChip(AppTheme theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: theme.cardSecondaryColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.borderColor),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: theme.textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailsList(AppTheme theme) {
    return StreamBuilder<List<Trail>>(
      stream: _trailService.getTrails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2ECC71),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No trails available',
              style: TextStyle(color: theme.subTextColor),
            ),
          );
        }
        final trails = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trails.length,
          itemBuilder: (context, index) {
            final trail = trails[index];
            return _TrailCard(
              theme: theme,
              trail: trail,
              onTap: () => context.push('/trail-detail', extra: trail),
            );
          },
        );
      },
    );
  }

  Widget _buildArticlesList(AppTheme theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('articles').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2ECC71),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No articles found',
              style: TextStyle(color: theme.subTextColor),
            ),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final article = docs[index];
            return _ArticleCard(
              theme: theme,
              article: article,
              onTap: () => context.push('/article-detail', extra: article),
            );
          },
        );
      },
    );
  }
}

class _TrailCard extends StatelessWidget {
  final AppTheme theme;
  final Trail trail;
  final VoidCallback onTap;

  const _TrailCard({
    required this.theme,
    required this.trail,
    required this.onTap,
  });

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
          boxShadow: theme.isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: trail.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.terrain_rounded, color: trail.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trail.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                      fontSize: 15,
                    ),
                  ),
                  ValueListenableBuilder<DistanceUnit>(
                    valueListenable: UnitService.distanceUnitNotifier,
                    builder: (context, _, __) {
                      return Text(
                        '${trail.parkName} • ${UnitService.formatDistance(trail.distanceKm)}',
                        style: TextStyle(fontSize: 12, color: theme.subTextColor),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  color: _difficultyColor(trail.difficulty),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.subTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final AppTheme theme;
  final DocumentSnapshot article;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.theme,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final data = article.data() as Map<String, dynamic>? ?? {};
    final title = data['title'] ?? 'Trail Safety Tips';
    final category = data['category'] ?? 'Safety';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.borderColor),
          boxShadow: theme.isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.article_outlined,
                color: theme.primaryAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(fontSize: 12, color: theme.subTextColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.subTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
