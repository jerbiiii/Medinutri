import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/screens/voice_consultation_screen.dart';

class TelemedicineScreen extends StatelessWidget {
  TelemedicineScreen({super.key});

  final List<Doctor> doctors = [
    Doctor(
      id: "1",
      name: "Dr. Ahmed Ben Salem",
      specialty: "Cardiologue",
      rating: "4.8",
      image: "https://i.pravatar.cc/150?u=ahmed",
      gender: "male",
    ),
    Doctor(
      id: "2",
      name: "Dr. Sarah El Amrani",
      specialty: "Généraliste",
      rating: "4.9",
      image: "https://i.pravatar.cc/150?u=sarah",
      gender: "female",
    ),
    Doctor(
      id: "3",
      name: "Dr. Marc Lefebvre",
      specialty: "Nutritionniste / Endocrinologue",
      rating: "4.7",
      image: "https://i.pravatar.cc/150?u=marc",
      gender: "male",
    ),
    Doctor(
      id: "4",
      name: "Dr. Youssef El Fassi",
      specialty: "Psychiatre",
      rating: "4.9",
      image: "https://i.pravatar.cc/150?u=youssef",
      gender: "male",
    ),
    Doctor(
      id: "5",
      name: "Dr. Sofia Mansouri",
      specialty: "Dermatologue",
      rating: "4.9",
      image: "https://i.pravatar.cc/150?u=sofia",
      gender: "female",
    ),
    Doctor(
      id: "6",
      name: "Dr. Jean-Pierre Dupont",
      specialty: "Endocrinologue",
      rating: "4.8",
      image: "https://i.pravatar.cc/150?u=jean",
      gender: "male",
    ),
    Doctor(
      id: "7",
      name: "Dr. Julie Dubois",
      specialty: "Psychologue",
      rating: "5.0",
      image: "https://i.pravatar.cc/150?u=julie",
      gender: "female",
    ),
    Doctor(
      id: "8",
      name: "Dr. Myriam Bensaid",
      specialty: "Ophtalmologue",
      rating: "4.6",
      image: "https://i.pravatar.cc/150?u=myriam",
      gender: "female",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Télémédecine"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthStatusCard(context, isDark).animate().fadeIn().slideY(begin: 0.1, end: 0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text(
              "Médecins disponibles en ligne",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn(delay: 200.ms),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return _buildDoctorCard(context, doctor, isDark)
                    .animate()
                    .fadeIn(delay: (300 + index * 100).ms)
                    .slideX();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : null,
        gradient: !isDark 
          ? LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)]) 
          : null,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: isDark ? 0.1 : 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: isDark ? theme.primaryColor : Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                "Diagnostic Préliminaire AI",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Votre dernier rapport indique un besoin de suivi nutritionnel. Une consultation vidéo avec un spécialiste est recommandée.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.white.withValues(alpha: 0.9), 
              fontSize: 14, 
              height: 1.5
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(doctor.image)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(doctor.specialty, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(doctor.rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.video_call, color: Theme.of(context).primaryColor, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VoiceConsultationScreen(
                    doctor: doctor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
