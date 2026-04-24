import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medinutri/models/health_models.dart';
import '../services/supabase_service.dart';
import '../services/health_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class MedicationAlarmScreen extends StatefulWidget {
  final String medicationId;
  final String medicationName;
  final String dosage;

  const MedicationAlarmScreen({
    super.key,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
  });

  @override
  State<MedicationAlarmScreen> createState() => _MedicationAlarmScreenState();
}

class _MedicationAlarmScreenState extends State<MedicationAlarmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final FlutterTts _tts = FlutterTts();
  double _dragValue = 0.0;
  bool _isSpeaking = false;
  int _announcementCount = 0;
  Timer? _ttsTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _initTts();
    
    // Jouer une vibration continue
    HapticFeedback.heavyImpact();
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      HapticFeedback.vibrate();
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("fr-FR");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setErrorHandler((msg) => setState(() => _isSpeaking = false));
    _tts.setCancelHandler(() => setState(() => _isSpeaking = false));
    
    _startAnnouncements();
  }

  void _startAnnouncements() {
    if (!mounted) return;
    
    // Première annonce immédiate
    _announce();
    
    _ttsTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      if (!mounted) return;
      if (_announcementCount >= 2) {
        timer.cancel();
        return;
      }
      _announce();
    });
  }

  Future<void> _announce() async {
    if (_isSpeaking || _announcementCount >= 2) return;
    
    setState(() {
      _isSpeaking = true;
      _announcementCount++;
    });
    
    await _tts.speak("Rappel MédiNutri : Il est l'heure de prendre votre ${widget.medicationName}.");
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ttsTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _markAsTaken() async {
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    if (healthProvider.currentUser == null) return;
    
    try {
      final log = MedicationLog(
        id: '', // Supabase générera l'UUID
        medicationId: widget.medicationId,
        userId: healthProvider.currentUser!.id!,
        scheduledTime: DateTime.now().hour.toString().padLeft(2, '0') + ':' + DateTime.now().minute.toString().padLeft(2, '0'),
        status: 'taken',
        takenAt: DateTime.now(),
      );
      
      await SupabaseService.instance.logMedication(log);
      await healthProvider.refreshData();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF0D9488).withValues(alpha: 0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Pulsing Icon
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.15).animate(
                  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                ),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0D9488), width: 2),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    size: 80,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'L\'heure de votre traitement',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                widget.medicationName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              
              if (widget.dosage.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.dosage,
                  style: const TextStyle(
                    color: Color(0xFF0D9488),
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Big Take Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: _markAsTaken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.5),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 32),
                        SizedBox(width: 15),
                        Text(
                          'JE PRENDS MAINTENANT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Dismiss Slider
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        'Glisser pour ignorer',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _dragValue * (MediaQuery.of(context).size.width - 80 - 60),
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          setState(() {
                            _dragValue += details.primaryDelta! / (MediaQuery.of(context).size.width - 80 - 60);
                            _dragValue = _dragValue.clamp(0.0, 1.0);
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (_dragValue > 0.8) {
                            Navigator.of(context).pop();
                          } else {
                            setState(() {
                              _dragValue = 0.0;
                            });
                          }
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
