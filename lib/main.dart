import 'package:flutter/material.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:medinutri/screens/login_screen.dart';
import 'package:medinutri/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
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
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'MediNutri IA',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.themeData.copyWith(
        textTheme: GoogleFonts.outfitTextTheme(
          themeNotifier.themeData.textTheme,
        ),
      ),
      home: authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
