import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/fono_ayuda_screen.dart';
import 'services/history_service.dart';
import 'services/emotional_pulse_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HistoryService.init();
  await EmotionalPulseService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const ArmonIAApp());
}

class ArmonIAApp extends StatelessWidget {
  const ArmonIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArmonIA',
      theme: ThemeData(
        primaryColor: const Color(0xFF7FA8B8),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/history': (_) => const HistoryScreen(),
        '/exercises': (_) => const ExercisesScreen(),
        '/fono': (_) => const FonoAyudaScreen(),
      },
    );
  }
}