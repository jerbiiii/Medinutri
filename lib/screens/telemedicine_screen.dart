import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/screens/voice_consultation_screen.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/services/theme_notifier.dart';
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
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
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
          // ── Diagnostic card ─────────────────────────
          _buildDiagnosticCard(
            isDark,
            theme,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Médecins disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          // ── Doctors list ────────────────────────────
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
  //  DIAGNOSTIC CARD
  // ─────────────────────────────────────────────────────
  Widget _buildDiagnosticCard(bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isDark ? const Color(0xFF121212) : null,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : const Color(0xFF0D9488).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: isDark ? const Color(0xFF0D9488) : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Diagnostic préliminaire IA',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _loadingDiagnosis
              ? Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          isDark ? const Color(0xFF0D9488) : Colors.white,
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
  //  DOCTOR CARD
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
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.transparent
                : const Color(0xFF0D9488).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                doctor.imageUrl,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => CircleAvatar(
                  radius: 29,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  child: Text(
                    doctor.name.split(' ').last[0],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doctor.specialty,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[500],
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.15),
                            const Color(0xFF10B981).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'En ligne',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Call button
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: ThemeNotifier.primaryGradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.video_call_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VoiceConsultationScreen(doctor: doctor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Appel vidéo',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white60 : const Color(0xFF0D9488),
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
        const CircularProgressIndicator(color: Color(0xFF0D9488)),
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: ThemeNotifier.primaryGradient),
          ),
          child: ElevatedButton.icon(
            onPressed: () => hp.loadOrGenerateDoctors(forceRefresh: true),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
      ],
    ),
  );
}
