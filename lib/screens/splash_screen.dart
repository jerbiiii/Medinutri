import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/screens/home_screen.dart';
import 'package:medinutri/screens/login_screen.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Délai pour l'effet visuel (SplashScreen)
    await Future.delayed(const Duration(milliseconds: 2800));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Navigation vers la page appropriée
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F2027),
                    const Color(0xFF203A43),
                    const Color(0xFF2C5364),
                  ]
                : [
                    themeNotifier.seedColor.withOpacity(0.8),
                    themeNotifier.seedColor,
                    themeNotifier.seedColor.withBlue(255),
                  ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Éléments décoratifs en arrière-plan
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec animation
                Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 120,
                        height: 120,
                      ),
                    )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .shimmer(delay: 1200.ms, duration: 1500.ms),

                const SizedBox(height: 40),

                // Texte de l'application
                Text(
                      'MediNutri IA',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                    )
                    .animate(delay: 400.ms)
                    .fade(duration: 800.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

                const SizedBox(height: 10),

                Text(
                  'Votre nutrition assistée par IA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 800.ms).fade(duration: 800.ms),
              ],
            ),

            // Indicateur de chargement discret en bas
            Positioned(
              bottom: 60,
              child:
                  const SizedBox(
                        width: 40,
                        height: 4,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2000.ms),
            ),
          ],
        ),
      ),
    );
  }
}
