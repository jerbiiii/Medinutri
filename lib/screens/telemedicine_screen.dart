import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/screens/voice_consultation_screen.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:provider/provider.dart';

class TelemedicineScreen extends StatefulWidget {
  const TelemedicineScreen({super.key});

  @override
  State<TelemedicineScreen> createState() => _TelemedicineScreenState();
}

class _TelemedicineScreenState extends State<TelemedicineScreen> {
  String? _diagnosticSummary;
  bool _loadingDiagnosis = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    final hp = Provider.of<HealthProvider>(context, listen: false);
    // Charger/générer médecins en arrière-plan
    hp.loadOrGenerateDoctors();
    // Charger le résumé diagnostic
    _loadDiagnosis(hp);
  }

  Future<void> _loadDiagnosis(HealthProvider hp) async {
    setState(() => _loadingDiagnosis = true);
    final summary = await hp.generateDiagnosticSummary();
    if (mounted) {
      setState(() {
        _diagnosticSummary = summary;
        _loadingDiagnosis = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = Provider.of<HealthProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Télémédecine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser les médecins',
            onPressed: () {
              hp.loadOrGenerateDoctors(forceRefresh: true);
              _loadDiagnosis(hp);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Carte diagnostic dynamique ──────────────
          _buildDiagnosticCard(
            isDark,
            theme,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Médecins disponibles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ── Liste médecins IA ──────────────────────
          Expanded(
            child: hp.isLoadingDoctors
                ? _buildDoctorsLoading()
                : hp.doctors.isEmpty
                ? _buildDoctorsEmpty(hp)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: hp.doctors.length,
                    itemBuilder: (ctx, i) => _buildDoctorCard(
                      ctx,
                      hp.doctors[i],
                      isDark,
                      theme,
                    ).animate().fadeIn(delay: (100 + i * 80).ms).slideX(),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  CARTE DIAGNOSTIC IA
  // ─────────────────────────────────────────────────────
  Widget _buildDiagnosticCard(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withValues(alpha: 0.75),
                ],
              ),
        color: isDark ? const Color(0xFF121212) : null,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: isDark ? 0.1 : 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user,
                color: isDark ? theme.primaryColor : Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                'Diagnostic préliminaire IA',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loadingDiagnosis
              ? Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          isDark ? theme.primaryColor : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Analyse de votre dernière consultation...',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Text(
                  _diagnosticSummary ??
                      'Consultez le Dr. Vitality pour obtenir un diagnostic.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  //  CARTE MÉDECIN
  // ─────────────────────────────────────────────────────
  Widget _buildDoctorCard(
    BuildContext context,
    Doctor doctor,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: Image.network(
              doctor.imageUrl,
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 29,
                backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  doctor.name.split(' ').last[0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doctor.specialty,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 15),
                    const SizedBox(width: 4),
                    Text(
                      doctor.rating,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'En ligne',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bouton consultation
          Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.video_call_rounded,
                  color: theme.primaryColor,
                  size: 30,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceConsultationScreen(doctor: doctor),
                  ),
                ),
              ),
              Text(
                'Appel vidéo',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        const Text('L\'IA génère votre liste de médecins...'),
      ],
    ).animate().fadeIn(),
  );

  Widget _buildDoctorsEmpty(HealthProvider hp) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('👨‍⚕️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text(
          'Aucun médecin disponible',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Une connexion est nécessaire pour charger les médecins.'),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => hp.loadOrGenerateDoctors(forceRefresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
        ),
      ],
    ),
  );
}
