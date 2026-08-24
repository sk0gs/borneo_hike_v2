import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'services/theme_service.dart';
import 'services/unit_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeService.init();
  await UnitService.init();

  runApp(const BorneoHikeApp());
}

class BorneoHikeApp extends StatelessWidget {
  const BorneoHikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp.router(
          title: 'BorneoHike',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Light Theme
          theme: ThemeData.light().copyWith(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1B8A4D),
            scaffoldBackgroundColor: const Color(0xFFF2F7F4),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B8A4D),
              secondary: Color(0xFF2ECC71),
              surface: Color(0xFFFFFFFF),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFE2EFE7),
              foregroundColor: Color(0xFF0F291E),
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          // Dark Theme
          darkTheme: ThemeData.dark().copyWith(
            brightness: Brightness.dark,
            primaryColor: Colors.green[700],
            scaffoldBackgroundColor: const Color(0xFF0A1F18),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2ECC71),
              secondary: Color(0xFF1A3F2E),
              surface: Color(0xFF112D24),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF112D24),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1A3F2E),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
