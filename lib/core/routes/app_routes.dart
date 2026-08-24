import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:borneo_hike_v2/core/widgets/main_layout.dart';
import 'package:borneo_hike_v2/features/trail/screens/trail_detail_screen.dart';
import 'package:borneo_hike_v2/features/trail/screens/safety_check_in_screen.dart';
import 'package:borneo_hike_v2/features/hike/screens/active_hike_screen.dart';
import 'package:borneo_hike_v2/features/hike/screens/hike_summary_screen.dart';
import 'package:borneo_hike_v2/features/auth/screens/login_screen.dart';
import 'package:borneo_hike_v2/features/auth/screens/register_screen.dart';
import 'package:borneo_hike_v2/features/home/screens/article_detail_screen.dart';
import 'package:borneo_hike_v2/features/profile/screens/hike_history.dart';
import 'package:borneo_hike_v2/features/profile/screens/user_statistics.dart';
import 'package:borneo_hike_v2/features/profile/screens/settings_screen.dart';
import 'package:borneo_hike_v2/models/trail.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    final bool loggedIn = FirebaseAuth.instance.currentUser != null;
    final bool loggingIn =
        state.matchedLocation == '/login' || state.matchedLocation == '/register';
    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const MainLayout()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/trail-detail',
      builder: (_, state) {
        final trail = state.extra as Trail;
        return TrailDetailScreen(trail: trail);
      },
    ),
    GoRoute(
      path: '/safety-checkin',
      builder: (_, state) {
        final trail = state.extra as Trail;
        return SafetyCheckInScreen(trail: trail);
      },
    ),
    GoRoute(
      path: '/active-hike',
      builder: (_, state) {
        final trail = state.extra as Trail;
        return ActiveHikeScreen(trail: trail);
      },
    ),
    GoRoute(
      path: '/hike-summary',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return HikeSummaryScreen(
          trail: extra['trail'] as Trail,
          elapsedTime: extra['elapsedTime'] as Duration,
          photos: extra['photos'] as List<XFile>,
          routePoints: (extra['routePoints'] as List<LatLng>?) ?? [],
          distanceKm: (extra['distanceKm'] as double?) ?? 0.0,
        );
      },
    ),
    GoRoute(
      path: '/article-detail',
      builder: (_, state) {
        final article = state.extra as DocumentSnapshot;
        return ArticleDetailScreen(article: article);
      },
    ),
    GoRoute(
      path: '/hike-history',
      builder: (_, __) => const HikeHistoryScreen(),
    ),
    GoRoute(
      path: '/user-statistics',
      builder: (_, __) => const UserStatisticsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
  ],
);

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
