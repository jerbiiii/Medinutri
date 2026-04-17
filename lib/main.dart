import 'package:flutter/material.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/services/notification_service.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:medinutri/screens/splash_screen.dart';
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

  // Initialiser les notifications (restaure les rappels programmés)
  await NotificationService.instance.initialize();

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

class MediNutriApp extends StatelessWidget {
  const MediNutriApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'MediNutri IA',
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
