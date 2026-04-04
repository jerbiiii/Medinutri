import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/widgets/doctor_avatar_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum AvatarState { idle, listening, thinking, speaking, waving }

class VoiceConsultationScreen extends StatefulWidget {
  final Doctor doctor;

  const VoiceConsultationScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<VoiceConsultationScreen> createState() =>
      _VoiceConsultationScreenState();
}

class _VoiceConsultationScreenState extends State<VoiceConsultationScreen>
    with TickerProviderStateMixin {
  AvatarState _currentState = AvatarState.waving;
  String _statusText = "Préparation de la consultation...";
  late AnimationController _micPulseController;
  late AnimationController _backgroundPulse;

  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isAutoListening = true;

  String get _avatarStateString => _currentState.name;

  @override
  void initState() {
    super.initState();
    _micPulseController =
        AnimationController(vsync: this, duration: 1500.ms);
    _backgroundPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _initSpeech();
    _initTts();
  }

  void _setAvatarState(AvatarState state, {String? statusText}) {
    if (!mounted) return;
    setState(() {
      _currentState = state;
      if (statusText != null) _statusText = statusText;
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => debugPrint('Speech Error: $val'),
      onStatus: (val) => _handleSpeechStatus(val),
    );
    if (mounted) setState(() {});
  }

  void _handleSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (_currentState == AvatarState.listening) {
        _setAvatarState(AvatarState.idle);
        _micPulseController.stop();
      }
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("fr-FR");

    try {
      List<dynamic> voices = await _flutterTts.getVoices;
      var frenchVoices =
          voices.where((v) => v["locale"].toString().contains("fr")).toList();

      if (frenchVoices.isNotEmpty) {
        String genderKey = widget.doctor.gender == 'male' ? 'male' : 'female';
        var selectedVoice = frenchVoices.firstWhere(
          (v) => v["name"].toString().toLowerCase().contains(genderKey),
          orElse: () => frenchVoices.firstWhere(
            (v) => v["gender"] == genderKey,
            orElse: () => frenchVoices.first,
          ),
        );
        await _flutterTts.setVoice(
            {"name": selectedVoice["name"], "locale": selectedVoice["locale"]});
      }
    } catch (e) {
      debugPrint("Error setting voice: $e");
    }

    await _flutterTts.setPitch(widget.doctor.gender == 'male' ? 0.85 : 1.15);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        _setAvatarState(AvatarState.idle, statusText: "Je vous écoute...");
        if (_isAutoListening) {
          Future.delayed(500.ms, () => _startListening());
        }
      }
    });

    _initialWaving();
  }

  void _initialWaving() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final greeting =
        "Bonjour, ici le ${widget.doctor.name}, spécialiste en ${widget.doctor.specialty}. "
        "Je suis prêt pour votre consultation. Comment vous sentez-vous aujourd'hui ?";

    if (mounted) {
      _setAvatarState(AvatarState.speaking, statusText: "Présentation...");
      await _flutterTts.speak(greeting);
    }
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _backgroundPulse.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    if (mounted) {
      _setAvatarState(AvatarState.listening,
          statusText: "Exprimez-vous librement...");
      _micPulseController.repeat(reverse: true);
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleCommand(result.recognizedWords);
        }
      },
      localeId: "fr-FR",
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) {
      _setAvatarState(AvatarState.idle);
      _micPulseController.stop();
    }
  }

  void _handleCommand(String text) async {
    if (text.isEmpty) {
      if (_isAutoListening) {
        Future.delayed(1000.ms, () => _startListening());
      }
      return;
    }

    if (mounted) {
      _setAvatarState(AvatarState.thinking,
          statusText: "${widget.doctor.name} réfléchit...");
    }

    try {
      final healthProvider = Provider.of<HealthProvider>(context, listen: false);

      final systemPersona =
          "Tu es le ${widget.doctor.name}, un expert en ${widget.doctor.specialty}. "
          "Tu parles à un patient lors d'une consultation vocale. "
          "Réponds concisément (max 2-3 phrases) pour garder la fluidité. "
          "Sois professionnel, empathique et rassurant.";

      await healthProvider.analyzeSymptoms(
        "Message du patient : $text",
        systemContext: systemPersona,
      );

      if (!mounted) return;

      final lastMsg = healthProvider.messages.last['content'] ??
          "Je n'ai pas pu analyser cela. Pouvez-vous répéter ?";

      _setAvatarState(AvatarState.speaking,
          statusText: "${widget.doctor.name} répond...");
      await _flutterTts.speak(lastMsg);
    } catch (e) {
      if (mounted) {
        _setAvatarState(AvatarState.idle,
            statusText: "Problème de connexion.");
      }
    }
  }

  Color _getDoctorAccentColor() {
    final Map<String, Color> colors = {
      '1': const Color(0xFF42A5F5), // Cardiologue - bleu
      '2': const Color(0xFF66BB6A), // Généraliste - vert
      '3': const Color(0xFF4DD0E1), // Nutritionniste - cyan
      '4': const Color(0xFF7C4DFF), // Psychiatre - violet
      '5': const Color(0xFFF48FB1), // Dermatologue - rose
      '6': const Color(0xFF00ACC1), // Endocrinologue - teal
      '7': const Color(0xFFFFD54F), // Psychologue - jaune
      '8': const Color(0xFF78909C), // Ophtalmologue - bleu-gris
    };
    return colors[widget.doctor.id] ?? Theme.of(context).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getDoctorAccentColor();

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundPulse,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.5,
                  colors: [
                    accentColor.withOpacity(0.08 + _backgroundPulse.value * 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Grid lines background (tech feel)
          CustomPaint(
            painter: _GridPainter(accentColor),
            size: Size.infinite,
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      // Live indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.6),
                                      blurRadius: 6,
                                      spreadRadius: 2)
                                ],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.5, 1.5),
                                    duration: 800.ms),
                            const SizedBox(width: 6),
                            const Text(
                              "EN LIGNE",
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Doctor avatar (main focus)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pulsing rings behind avatar
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_currentState == AvatarState.speaking ||
                                _currentState == AvatarState.listening)
                              ...List.generate(3, (i) => AnimatedBuilder(
                                animation: _backgroundPulse,
                                builder: (_, __) => Container(
                                  width: 260 + i * 50.0,
                                  height: 260 + i * 50.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentColor.withOpacity(
                                          0.15 - i * 0.04),
                                      width: 1.5,
                                    ),
                                  ),
                                ).animate(onPlay: (c) => c.repeat())
                                    .scale(
                                        begin: const Offset(0.85, 0.85),
                                        end: const Offset(1.2, 1.2),
                                        duration: (1800 + i * 300).ms,
                                        curve: Curves.easeInOut)
                                    .fadeOut(duration: 1.5.seconds),
                              )),

                            // THE AVATAR
                            DoctorAvatarWidget(
                              doctorId: widget.doctor.id,
                              gender: widget.doctor.gender,
                              avatarState: _avatarStateString,
                              size: 240,
                            ).animate().fadeIn(delay: 200.ms).scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 600.ms,
                                curve: Curves.elasticOut),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Doctor info
                        Text(
                          widget.doctor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: accentColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            widget.doctor.specialty.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 28),

                        // Status pill
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                      scale: animation, child: child)),
                          child: Container(
                            key: ValueKey(_statusText),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(30),
                              border:
                                  Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStateIndicator(accentColor),
                                const SizedBox(width: 10),
                                Text(
                                  _statusText,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom action area
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildActionArea(accentColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateIndicator(Color accent) {
    Color color = Colors.greenAccent;
    if (_currentState == AvatarState.thinking) color = Colors.orange;
    if (_currentState == AvatarState.listening) color = Colors.redAccent;
    if (_currentState == AvatarState.speaking) color = accent;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.6, 1.6),
            duration: 700.ms);
  }

  Widget _buildActionArea(Color accentColor) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_currentState == AvatarState.listening) {
              _stopListening();
            } else if (_currentState == AvatarState.idle) {
              _startListening();
            }
          },
          child: AnimatedBuilder(
            animation: _micPulseController,
            builder: (context, child) {
              final isListening = _currentState == AvatarState.listening;
              final scale = isListening
                  ? 1.0 + _micPulseController.value * 0.12
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening
                        ? Colors.redAccent.withOpacity(0.2)
                        : accentColor.withOpacity(0.1),
                    border: Border.all(
                      color: isListening ? Colors.redAccent : accentColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isListening
                            ? Colors.redAccent.withOpacity(0.3)
                            : accentColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic : Icons.mic_none,
                    color: isListening ? Colors.redAccent : accentColor,
                    size: 35,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isAutoListening ? "MODE MAINS-LIBRES" : "APPUYEZ POUR PARLER",
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Background grid painter for cyberpunk feel
class _GridPainter extends CustomPainter {
  final Color accentColor;
  _GridPainter(this.accentColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withOpacity(0.04)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
