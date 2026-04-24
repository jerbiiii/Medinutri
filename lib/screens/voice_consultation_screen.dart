import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medinutri/models/health_models.dart';
import 'package:medinutri/services/health_provider.dart';
import 'package:medinutri/widgets/doctor_avatar_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:math' as math;

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

  // ── Mouth sync: driven by TTS prosody estimation ────────────────
  double _mouthAmplitude = 0.0;
  String _currentSpeechText = '';

  final List<Map<String, String>> _localHistory = [];

  String get _doctorPersona =>
      'Tu es ${widget.doctor.name}, spécialiste en ${widget.doctor.specialty}. '
      'Tu parles à un patient lors d\'une consultation vocale. '
      'RÈGLE CRITIQUE : Si le patient pose une question ou demande un conseil qui n\'est PAS lié à ta spécialité (${widget.doctor.specialty}), ne réponds PAS à la question. '
      'À la place, explique poliment que ce n\'est pas ton domaine d\'expertise et conseille-lui de consulter un confrère spécialisé dans le domaine approprié. '
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
    _stopMouthSync();
    super.dispose();
  }

  void _setAvatarState(AvatarState s, {String? status}) {
    if (!mounted) return;
    setState(() {
      _state = s;
      if (status != null) _statusText = status;
    });
  }

  // ── TTS Mouth Sync ───────────────────────────────────────────────
  // Estimates mouth opening based on phoneme timing from text
  // French average: ~14 phonemes/second = ~71ms per phoneme
  // We drive a sine wave at that rate, with amplitude from vowel density

  bool _mouthSyncRunning = false;

  void _startMouthSync(String text) {
    _currentSpeechText = text;
    _mouthSyncRunning = true;
    _driveMouth(text);
  }

  void _stopMouthSync() {
    _mouthSyncRunning = false;
    if (mounted) {
      setState(() => _mouthAmplitude = 0.0);
    }
  }

  Future<void> _driveMouth(String text) async {
    // Estimate speech duration: French ~3.5 chars/sec (including spaces)
    // Vowels produce bigger opening, consonants smaller
    const vowels = 'aeiouyàâäéèêëîïôùûüœæAEIOUYÀÂÄÉÈÊËÎÏÔÙÛÜŒÆ';
    final rng = math.Random();

    int charIdx = 0;
    while (_mouthSyncRunning && charIdx < text.length) {
      if (!mounted) break;

      final char = text[charIdx];
      final isVowel = vowels.contains(char);
      final isSpace = char == ' ' || char == ',' || char == '.';

      double targetAmp;
      int holdMs;

      if (isSpace || char == '.' || char == '!') {
        // Pause on punctuation / space
        targetAmp = 0.0;
        holdMs = char == '.' || char == '!'
            ? 200 + rng.nextInt(150)
            : 80 + rng.nextInt(60);
      } else if (isVowel) {
        // Vowels: wide open
        targetAmp = 0.55 + rng.nextDouble() * 0.45;
        holdMs = 75 + rng.nextInt(90); // ~75-165ms per vowel
      } else {
        // Consonants: partially open
        targetAmp = 0.1 + rng.nextDouble() * 0.35;
        holdMs = 55 + rng.nextInt(70);
      }

      // Smooth transition to target
      if (mounted) {
        setState(() => _mouthAmplitude = targetAmp);
      }

      await Future.delayed(Duration(milliseconds: holdMs));
      charIdx++;

      // Every ~8 chars add small random variation
      if (charIdx % 8 == 0) {
        await Future.delayed(Duration(milliseconds: rng.nextInt(40)));
      }
    }

    // Fade mouth closed
    if (mounted) {
      setState(() => _mouthAmplitude = 0.0);
    }
  }

  // ── Init ──────────────────────────────────────────────────────────
  Future<void> _initSpeech() async {
    _speechReady = await _stt.initialize(
      onError: (e) => debugPrint('STT error: $e'),
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') &&
            _state == AvatarState.listening) {
          _setAvatarState(AvatarState.idle);
          _micPulse.stop();
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('fr-FR');

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

    if (widget.doctor.gender == 'male') {
      await _tts.setPitch(0.55);
      await _tts.setSpeechRate(0.44);
    } else {
      await _tts.setPitch(1.2);
      await _tts.setSpeechRate(0.48);
    }

    // When TTS starts speaking, kick off mouth sync
    _tts.setStartHandler(() {
      if (mounted) {
        _setAvatarState(
          AvatarState.speaking,
          status: '${widget.doctor.name} parle...',
        );
        _startMouthSync(_currentSpeechText);
      }
    });

    _tts.setCompletionHandler(() {
      _stopMouthSync();
      if (mounted) {
        _setAvatarState(AvatarState.idle, status: 'Je vous écoute...');
        Future.delayed(500.ms, _startListening);
      }
    });

    _tts.setCancelHandler(() {
      _stopMouthSync();
      if (mounted) _setAvatarState(AvatarState.idle);
    });

    // Greeting
    await Future.delayed(1500.ms);
    final greeting =
        'Bonjour, je suis ${widget.doctor.name}, ${widget.doctor.specialty}. '
        'Je suis prêt pour votre consultation. Comment vous sentez-vous aujourd\'hui ?';

    _currentSpeechText = greeting;
    _setAvatarState(AvatarState.speaking, status: 'Présentation...');
    await _tts.speak(greeting);
    _localHistory.add({'role': 'assistant', 'content': greeting});
  }

  // ── Listening ──────────────────────────────────────────────────────
  Future<void> _startListening() async {
    if (!_speechReady) return;
    _setAvatarState(
      AvatarState.listening,
      status: 'Exprimez-vous librement...',
    );
    HapticFeedback.heavyImpact();
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
    HapticFeedback.selectionClick();
    _setAvatarState(AvatarState.idle);
    _micPulse.stop();
  }

  // ── AI Response ───────────────────────────────────────────────────
  Future<void> _handleInput(String text) async {
    if (text.isEmpty) {
      Future.delayed(1.seconds, _startListening);
      return;
    }

    _setAvatarState(
      AvatarState.thinking,
      status: '${widget.doctor.name} réfléchit...',
    );

    try {
      final hp = Provider.of<HealthProvider>(context, listen: false);
      String response = await hp.analyzeForVoiceConsultation(
        text,
        _localHistory,
        _doctorPersona,
      );
      if (!mounted) return;

      // Gérer les erreurs de l'IA proprement
      if (response == "__RATE_LIMITED__") {
        response = "Désolé, je reçois trop de demandes. Réessayez dans un instant.";
      } else if (response == "__ERROR__" || response.isEmpty) {
        response = "Je rencontre une petite difficulté technique. Pouvez-vous répéter ?";
      }

      _currentSpeechText = response;
      _setAvatarState(
        AvatarState.speaking,
        status: '${widget.doctor.name} répond...',
      );
      await _tts.speak(response);
    } catch (e) {
      if (mounted) {
        _setAvatarState(AvatarState.idle, status: 'Problème de connexion.');
      }
    }
  }

  // ── UI ───────────────────────────────────────────────────────────
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
          // Animated background gradient
          AnimatedBuilder(
            animation: _bgPulse,
            builder: (_, _) => Container(
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

          // Cyber grid
          CustomPaint(painter: _GridPainter(accent), size: Size.infinite),

          SafeArea(
            child: Column(
              children: [
                // Top bar
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
                          _stopMouthSync();
                          Navigator.pop(context);
                        },
                      ),
                      const Spacer(),
                      _buildLiveIndicator(),
                    ],
                  ),
                ),

                // Avatar area
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse rings
                            if (_state == AvatarState.speaking ||
                                _state == AvatarState.listening)
                              ...List.generate(3, (i) => _pulseRing(accent, i)),

                            // 3D Bitmoji Avatar
                            DoctorAvatarWidget(
                                  doctorId: widget.doctor.id,
                                  gender: widget.doctor.gender,
                                  avatarState: _state.name,
                                  size: 240,
                                  mouthAmplitude: _state == AvatarState.speaking
                                      ? _mouthAmplitude
                                      : null,
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

                        // Doctor name
                        Text(
                          widget.doctor.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 6),

                        // Specialty badge
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

                // Mic button
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
                          builder: (_, _) {
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
                      const SizedBox(height: 16),
                      if (_state == AvatarState.listening)
                        _buildWaveform(accent),
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
            width: 260 + i * 50.0,
            height: 260 + i * 50.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.13 - i * 0.04),
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

  Widget _buildWaveform(Color accent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        8,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleY(
              begin: 0.5,
              end: 1.5 + (math.Random().nextDouble() * 1.5),
              duration: Duration(milliseconds: 300 + (i * 50)),
              curve: Curves.easeInOut,
            ),
      ),
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
