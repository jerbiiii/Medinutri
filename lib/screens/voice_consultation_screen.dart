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
  const VoiceConsultationScreen({super.key, required this.doctor});

  @override
  State<VoiceConsultationScreen> createState() =>
      _VoiceConsultationScreenState();
}

class _VoiceConsultationScreenState extends State<VoiceConsultationScreen>
    with TickerProviderStateMixin {
  AvatarState _state = AvatarState.waving;
  String _statusText = 'Préparation de la consultation...';

  late AnimationController _micPulse;
  late AnimationController _bgPulse;

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _speechReady = false;

  // ── Historique LOCAL de cette consultation ──────────────
  // Ne pollue PAS le chat principal de HealthProvider
  final List<Map<String, String>> _localHistory = [];

  // Persona du médecin injectée dans chaque appel IA
  String get _doctorPersona =>
      'Tu es ${widget.doctor.name}, spécialiste en ${widget.doctor.specialty}. '
      'Tu parles à un patient lors d\'une consultation vocale. '
      'Réponds en maximum 2-3 phrases courtes pour garder la fluidité. '
      'Sois professionnel, empathique et rassurant. Réponds en français.';

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(vsync: this, duration: 1500.ms);
    _bgPulse = AnimationController(vsync: this, duration: 3.seconds)
      ..repeat(reverse: true);

    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _micPulse.dispose();
    _bgPulse.dispose();
    _tts.stop();
    _stt.stop();
    super.dispose();
  }

  void _setState2(AvatarState s, {String? status}) {
    if (!mounted) return;
    setState(() {
      _state = s;
      if (status != null) _statusText = status;
    });
  }

  // ─────────────────────────────────────────────────────
  //  INITIALISATION
  // ─────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    _speechReady = await _stt.initialize(
      onError: (e) => debugPrint('STT error: $e'),
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') &&
            _state == AvatarState.listening) {
          _setState2(AvatarState.idle);
          _micPulse.stop();
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');

    // Sélection de voix selon le genre
    try {
      final voices = await _tts.getVoices as List?;
      if (voices != null) {
        final frVoices = voices
            .where((v) => (v['locale'] as String? ?? '').contains('fr'))
            .toList();
        if (frVoices.isNotEmpty) {
          final genderKey = widget.doctor.gender == 'male' ? 'male' : 'female';
          final voice = frVoices.firstWhere(
            (v) => (v['name'] as String).toLowerCase().contains(genderKey),
            orElse: () => frVoices.first,
          );
          await _tts.setVoice({
            'name': voice['name'],
            'locale': voice['locale'],
          });
        }
      }
    } catch (_) {}

    // ── FIX VOIX MASCULINE : pitch plus grave ──────────────
    // Avant : male=0.85 (sonnait comme une femme)
    // Après : male=0.55 (voix grave/masculine), female=1.2 (voix féminine nette)
    if (widget.doctor.gender == 'male') {
      await _tts.setPitch(0.55); // ← voix grave
      await _tts.setSpeechRate(
        0.44,
      ); // ← débit légèrement plus lent = plus naturel
    } else {
      await _tts.setPitch(1.2);
      await _tts.setSpeechRate(0.5);
    }

    _tts.setCompletionHandler(() {
      if (mounted) {
        _setState2(AvatarState.idle, status: 'Je vous écoute...');
        Future.delayed(500.ms, _startListening);
      }
    });

    // Salutation d'accueil
    await Future.delayed(1500.ms);
    final greeting =
        'Bonjour, je suis ${widget.doctor.name}, ${widget.doctor.specialty}. '
        'Je suis prêt pour votre consultation. Comment vous sentez-vous aujourd\'hui ?';
    _setState2(AvatarState.speaking, status: 'Présentation...');
    await _tts.speak(greeting);
    _localHistory.add({'role': 'assistant', 'content': greeting});
  }

  // ─────────────────────────────────────────────────────
  //  ÉCOUTE VOCALE
  // ─────────────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_speechReady) return;
    _setState2(AvatarState.listening, status: 'Exprimez-vous librement...');
    _micPulse.repeat(reverse: true);

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) _handleInput(result.recognizedWords);
      },
      localeId: 'fr-FR',
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    _setState2(AvatarState.idle);
    _micPulse.stop();
  }

  // ─────────────────────────────────────────────────────
  //  TRAITEMENT DE LA RÉPONSE IA (ISOLÉ)
  // ─────────────────────────────────────────────────────
  Future<void> _handleInput(String text) async {
    if (text.isEmpty) {
      Future.delayed(1.seconds, _startListening);
      return;
    }

    _setState2(
      AvatarState.thinking,
      status: '${widget.doctor.name} réfléchit...',
    );

    try {
      final hp = Provider.of<HealthProvider>(context, listen: false);

      // ── Appel IA isolé — n'affecte PAS le chat principal ──
      final response = await hp.analyzeForVoiceConsultation(
        text,
        _localHistory,
        _doctorPersona,
      );

      if (!mounted) return;
      _setState2(
        AvatarState.speaking,
        status: '${widget.doctor.name} répond...',
      );
      await _tts.speak(response);
    } catch (e) {
      if (mounted) {
        _setState2(AvatarState.idle, status: 'Problème de connexion.');
      }
    }
  }

  // ─────────────────────────────────────────────────────
  //  UI
  // ─────────────────────────────────────────────────────
  Color get _accent {
    const colors = {
      '1': Color(0xFF42A5F5),
      '2': Color(0xFF66BB6A),
      '3': Color(0xFF4DD0E1),
      '4': Color(0xFF7C4DFF),
      '5': Color(0xFFF48FB1),
      '6': Color(0xFF00ACC1),
      '7': Color(0xFFFFD54F),
      '8': Color(0xFF78909C),
    };
    return colors[widget.doctor.id] ?? Colors.blueAccent;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          // Fond animé
          AnimatedBuilder(
            animation: _bgPulse,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.5,
                  colors: [
                    accent.withValues(alpha: 0.07 + _bgPulse.value * 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Grille cyberpunk
          CustomPaint(painter: _GridPainter(accent), size: Size.infinite),

          SafeArea(
            child: Column(
              children: [
                // Barre top
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 26,
                        ),
                        onPressed: () {
                          _tts.stop();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      _buildLiveIndicator(),
                    ],
                  ),
                ),

                // Avatar
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anneaux de pulsation
                            if (_state == AvatarState.speaking ||
                                _state == AvatarState.listening)
                              ...List.generate(3, (i) => _pulseRing(accent, i)),
                            // Avatar 3D
                            DoctorAvatarWidget(
                                  doctorId: widget.doctor.id,
                                  gender: widget.doctor.gender,
                                  avatarState: _state.name,
                                  size: 230,
                                )
                                .animate()
                                .fadeIn(delay: 200.ms)
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1, 1),
                                  duration: 600.ms,
                                  curve: Curves.elasticOut,
                                ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          widget.doctor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            widget.doctor.specialty.toUpperCase(),
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 24),
                        // Status pill
                        AnimatedSwitcher(
                          duration: 300.ms,
                          child: Container(
                            key: ValueKey(_statusText),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statusDot(accent),
                                const SizedBox(width: 10),
                                Text(
                                  _statusText,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bouton micro
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_state == AvatarState.listening) {
                            _stopListening();
                          } else if (_state == AvatarState.idle) {
                            _startListening();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _micPulse,
                          builder: (_, __) {
                            final listening = _state == AvatarState.listening;
                            final scale = listening
                                ? 1.0 + _micPulse.value * 0.12
                                : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: listening
                                      ? Colors.redAccent.withValues(alpha: 0.2)
                                      : accent.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: listening
                                        ? Colors.redAccent
                                        : accent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (listening
                                                  ? Colors.redAccent
                                                  : accent)
                                              .withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  listening ? Icons.mic : Icons.mic_none,
                                  color: listening ? Colors.redAccent : accent,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MODE MAINS-LIBRES',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
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
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.5, 1.5),
              duration: 800.ms,
            ),
        const SizedBox(width: 6),
        const Text(
          'EN LIGNE',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    ),
  );

  Widget _pulseRing(Color accent, int i) =>
      Container(
            width: 250 + i * 48.0,
            height: 250 + i * 48.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.14 - i * 0.04),
                width: 1.5,
              ),
            ),
          )
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.2, 1.2),
            duration: Duration(milliseconds: 1800 + i * 300),
            curve: Curves.easeInOut,
          )
          .fadeOut(duration: 1500.ms);

  Widget _statusDot(Color accent) {
    Color color = Colors.greenAccent;
    if (_state == AvatarState.thinking) color = Colors.orange;
    if (_state == AvatarState.listening) color = Colors.redAccent;
    if (_state == AvatarState.speaking) color = accent;
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.6, 1.6),
          duration: 700.ms,
        );
  }
}

class _GridPainter extends CustomPainter {
  final Color accent;
  _GridPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
