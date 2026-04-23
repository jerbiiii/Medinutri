import 'dart:math';
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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _navigateToNext();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      Future.doWhile(() async {
        if (!authProvider.isLoading) return false;
        await Future.delayed(const Duration(milliseconds: 50));
        return true;
      }),
    ]);

    if (!mounted) return;

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
                    const Color(0xFF0D9488),
                    const Color(0xFF14B8A6),
                    const Color(0xFF38BDF8),
                    const Color(0xFF818CF8),
                  ],
            stops: isDark ? null : const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Floating particles ──────────────────────
            ..._buildParticles(),

            // ── Decorative circles ──────────────────────
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),

            // ── Main content ────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo avec animation pulse + shimmer
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 100,
                        height: 100,
                      ),
                    )
                    .animate()
                    .fade(duration: 800.ms)
                    .scale(
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    )
                    .shimmer(delay: 1200.ms, duration: 1800.ms, color: Colors.white.withValues(alpha: 0.3)),

                const SizedBox(height: 36),

                // App name
                Text(
                      'MediNutri IA',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3.0,
                            fontSize: 30,
                          ),
                    )
                    .animate(delay: 400.ms)
                    .fade(duration: 800.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

                const SizedBox(height: 10),

                Text(
                  'Votre nutrition assistée par IA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w300,
                  ),
                ).animate(delay: 800.ms).fade(duration: 800.ms),
              ],
            ),

            // ── Loading bar at bottom ───────────────────
            Positioned(
              bottom: 60,
              child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    final random = Random(42);
    return List.generate(8, (i) {
      final size = 6.0 + random.nextDouble() * 14;
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 800;
      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _particleController,
          builder: (_, _) {
            final offset = sin(_particleController.value * 2 * pi + i) * 20;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06 + random.nextDouble() * 0.06),
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
