import 'package:flutter/material.dart';
import 'screens/live_tracking_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EquibelleApp());
}

class EquibelleApp extends StatelessWidget {
  const EquibelleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equibelle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LiveTrackingScreen(),
    );
  }
}
