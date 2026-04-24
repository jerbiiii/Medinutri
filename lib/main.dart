import 'package:flutter/material.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/services/notification_service.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:medinutri/services/widget_service.dart';
import 'package:medinutri/screens/splash_screen.dart';
import 'package:medinutri/screens/medication_alarm_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialiser les services locaux
  await NotificationService.instance.initialize();
  await WidgetService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, HealthProvider>(
          create: (_) => HealthProvider(),
          update: (_, auth, health) => health!..updateUser(auth.currentUser, auth.currentProfile),
        ),
      ],
      child: const MediNutriApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MediNutriApp extends StatefulWidget {
  const MediNutriApp({super.key});

  @override
  State<MediNutriApp> createState() => _MediNutriAppState();
}

class _MediNutriAppState extends State<MediNutriApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // Écouter les clics sur les notifications
    NotificationService.instance.onNotificationPayload = (payload) {
      if (payload != null && payload.startsWith('medication_')) {
        final parts = payload.split('|');
        if (parts.length >= 1) {
          final medId = parts[0].replaceFirst('medication_', '');
          final name = parts.length > 1 ? parts[1] : 'Traitement';
          final dosage = parts.length > 2 ? parts[2] : 'À prendre maintenant';
          
          _showAlarmScreen(medId, name, dosage);
        }
      }
    };
  }

  void _showAlarmScreen(String medId, String name, String dosage) {
    // On attend un peu que l'app soit prête
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MedicationAlarmScreen(
              medicationId: medId,
              medicationName: name,
              dosage: dosage,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'MediNutri IA',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.themeData.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(
          themeNotifier.themeData.textTheme,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
