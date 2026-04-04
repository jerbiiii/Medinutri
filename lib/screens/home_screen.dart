import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/services/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:medinutri/services/auth_provider.dart';
import 'package:medinutri/screens/chat_screen.dart';
import 'package:medinutri/screens/nutrition_screen.dart';
import 'package:medinutri/screens/telemedicine_screen.dart';
import 'package:medinutri/screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final profile = auth.currentProfile;
    final isDark = themeNotifier.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: themeNotifier.brightness == Brightness.dark ? const Color(0xFF000000) : Colors.grey[50],
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
              child: IconButton(
                icon: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                tooltip: "Profil",
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF000000) : Colors.blueAccent,
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
                onPressed: () => themeNotifier.toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => auth.logout(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'MediNutri AI',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
              ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF000000), const Color(0xFF1A1A1A)]
                      : [Colors.blueAccent, const Color(0xFF64B5F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bonjour, ${profile?.name ?? 'Patient'}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Votre assistant de santé est prêt.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildServiceCard(
                    context,
                    title: "Docteur IA",
                    subtitle: "Analysez vos symptômes immédiatement",
                    icon: Icons.medical_services_outlined,
                    color: Colors.redAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    context,
                    title: "Télémédecine",
                    subtitle: "Consultez un vrai médecin en vidéo",
                    icon: Icons.video_call_outlined,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelemedicineScreen())),
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    context,
                    title: "Programme Nutrition",
                    subtitle: "Plans personnalisés suite au diagnostic",
                    icon: Icons.restaurant_menu,
                    color: Colors.lightGreenAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionScreen())),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Tableau de bord de santé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                        child: const Text("Détails"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuickStat(context, "IMC", profile?.bmi.toStringAsFixed(1) ?? "--", Colors.blue, profile?.bmiStatus ?? "N/A"),
                      const SizedBox(width: 12),
                      _buildQuickStat(context, "Poids", "${profile?.weight ?? '--'}kg", Colors.green, "Dernière pesée"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildServiceCard(BuildContext context,
      {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : color.withValues(alpha: 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Correct bolding
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, Color color, String subvalue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subvalue, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
