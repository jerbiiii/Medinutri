import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/screens/chat_screen.dart';
import 'package:medinutri/screens/login_screen.dart';
import 'package:medinutri/screens/nutrition_screen.dart';
import 'package:medinutri/screens/telemedicine_screen.dart';
import 'package:medinutri/screens/profile_screen.dart';
import 'package:medinutri/screens/notification_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medinutri/widgets/skeleton_loader.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final profile = auth.currentProfile;
    final isDark = themeNotifier.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: _buildProfileAvatar(profile?.photoPath, themeNotifier),
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF000000)
                : const Color(0xFF0D9488),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: Colors.white,
                ),
                onPressed: () => themeNotifier.toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'MediNutri AI',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF000000), const Color(0xFF1A1A1A)]
                        : ThemeNotifier.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting with photo ────────────────
                  Row(
                    children: [
                      if (profile?.photoPath != null)
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: ThemeNotifier.primaryGradient,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipOval(
                              child: _buildImageWidget(profile!.photoPath!, size: 52),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour, ${profile?.name ?? 'Patient'} 👋',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Prenez soin de votre santé aujourd\'hui ✨',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 28),

                  // ── Service cards ──────────────────────
                  _buildServiceCard(
                    context,
                    title: 'Docteur IA',
                    subtitle: 'Analysez vos symptômes immédiatement',
                    icon: Icons.medical_services_outlined,
                    color: const Color(0xFFEF4444),
                    delay: 0,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    context,
                    title: 'Télémédecine',
                    subtitle: 'Consultez un médecin IA par la voix',
                    icon: Icons.record_voice_over_outlined,
                    color: const Color(0xFF3B82F6),
                    delay: 100,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TelemedicineScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    context,
                    title: 'Programme Nutrition',
                    subtitle: 'Plans personnalisés selon votre profil',
                    icon: Icons.restaurant_menu,
                    color: const Color(0xFF10B981),
                    delay: 200,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NutritionScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    context,
                    title: 'Rappels de Repas',
                    subtitle: 'Ne ratez plus aucun repas',
                    icon: Icons.notifications_active_outlined,
                    color: const Color(0xFFF59E0B),
                    delay: 300,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Health dashboard ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tableau de bord de santé',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ),
                        child: const Text(
                          'Détails',
                          style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fade(duration: 500.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      profile == null 
                        ? const Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 20))
                        : _buildQuickStat(
                            context,
                            'IMC',
                            profile.bmi.toStringAsFixed(1),
                            const Color(0xFF3B82F6),
                            profile.bmiStatus,
                          ),
                      const SizedBox(width: 12),
                      profile == null 
                        ? const Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: 20))
                        : _buildQuickStat(
                            context,
                            'Poids',
                            '${profile.weight} kg',
                            const Color(0xFF10B981),
                            'Dernière pesée',
                          ),
                    ],
                  ).animate(delay: 500.ms).fade(duration: 500.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar dans la barre d'app (miniature)
  Widget _buildProfileAvatar(String? photoPath, ThemeNotifier themeNotifier) {
    return ClipOval(
      child: photoPath != null
          ? _buildImageWidget(photoPath, size: 40)
          : const Icon(Icons.person_rounded, color: Colors.white, size: 24),
    );
  }

  Widget _buildImageWidget(String path, {required double size}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _fallbackIcon(size),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.5,
              height: size * 0.5,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }
    
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _fallbackIcon(size),
      );
    }
    
    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.6),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int delay = 0,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : color.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient icon circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: isDark ? Colors.white60 : color,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: delay)).fade(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    String value,
    Color color,
    String subvalue,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.transparent : color.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            // Mini progress bar
            Container(
              height: 3,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.3)],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subvalue,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
