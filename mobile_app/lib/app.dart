import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/alert_provider.dart';
import 'providers/anomaly_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/rescue_center_provider.dart';
import 'providers/shelter_provider.dart';
import 'providers/victim_provider.dart';
import 'screens/splash/splash_screen.dart';

class FireEyeApp extends StatelessWidget {
  const FireEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnomalyProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => ShelterProvider()),
        ChangeNotifierProvider(create: (_) => RescueCenterProvider()),
        ChangeNotifierProvider(create: (_) => VictimProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: MaterialApp(
        title: 'FIRE-EYE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}

