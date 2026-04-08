import 'package:flutter/material.dart';
import 'dart:math' as math;

// ══════════════════════════════════════════════════════════════════
//  DOCTOR AVATAR — True 3D Snapchat Bitmoji Style
//  Proportions: head ~30% height, chibi ratio, 3D lighting
// ══════════════════════════════════════════════════════════════════

class DoctorAvatarWidget extends StatefulWidget {
  final String doctorId;
  final String gender;
  final String avatarState; // idle | listening | thinking | speaking | waving
  final double size;
  final double? mouthAmplitude; // 0.0–1.0, driven externally by TTS

  const DoctorAvatarWidget({
    super.key,
    required this.doctorId,
    required this.gender,
    required this.avatarState,
    this.size = 280,
    this.mouthAmplitude,
  });

  @override
  State<DoctorAvatarWidget> createState() => _DoctorAvatarWidgetState();
}

class _DoctorAvatarWidgetState extends State<DoctorAvatarWidget>
    with TickerProviderStateMixin {
  // Float / breathe
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _breathCtrl;
  late Animation<double> _breathAnim;

  // Blink
  late AnimationController _blinkCtrl;
  late Animation<double> _blinkAnim;

  // Mouth (natural speech rate ~280ms/syllable)
  late AnimationController _mouthCtrl;
  late Animation<double> _mouthAnim;

  // Wave arm
  late AnimationController _waveCtrl;
  late Animation<double> _waveAnim;

  // Head bob when speaking/listening
  late AnimationController _bobCtrl;
  late Animation<double> _bobAnim;

  // Thinking eye dart
  late AnimationController _thinkCtrl;
  late Animation<double> _thinkAnim;

  // Leg idle sway
  late AnimationController _legCtrl;
  late Animation<double> _legAnim;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _blinkAnim = CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut);

    // Mouth: natural phoneme pace (~320ms), NOT a simple repeat
    _mouthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _mouthAnim = CurvedAnimation(parent: _mouthCtrl, curve: Curves.easeInOut);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);

    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..repeat(reverse: true);
    _bobAnim = CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut);

    _thinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _thinkAnim = CurvedAnimation(parent: _thinkCtrl, curve: Curves.easeInOut);

    _legCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _legAnim = CurvedAnimation(parent: _legCtrl, curve: Curves.easeInOut);

    _scheduleBlink();
    _applyState();
  }

  void _scheduleBlink() async {
    while (mounted) {
      final delay = 1800 + math.Random().nextInt(3500);
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 90));
      if (mounted) _blinkCtrl.reverse();
    }
  }

  /// Mouth driven like natural phonemes — random phoneme durations 150–420ms
  void _startNaturalMouth() async {
    while (mounted && widget.avatarState == 'speaking') {
      final phonemeDuration = 150 + math.Random().nextInt(270); // 150-420ms
      _mouthCtrl.duration = Duration(milliseconds: phonemeDuration);
      await _mouthCtrl.forward();
      await Future.delayed(
        Duration(milliseconds: (phonemeDuration * 0.15).round()),
      );
      if (!mounted || widget.avatarState != 'speaking') break;
      await _mouthCtrl.reverse();
      // Brief pause between phonemes
      await Future.delayed(
        Duration(milliseconds: 30 + math.Random().nextInt(80)),
      );
    }
    if (mounted) _mouthCtrl.value = 0;
  }

  @override
  void didUpdateWidget(DoctorAvatarWidget old) {
    super.didUpdateWidget(old);
    if (old.avatarState != widget.avatarState) _applyState();
  }

  void _applyState() {
    _bobCtrl.stop();
    _mouthCtrl.stop();
    _mouthCtrl.value = 0;

    switch (widget.avatarState) {
      case 'speaking':
        _bobCtrl.repeat(reverse: true);
        _startNaturalMouth();
        break;
      case 'waving':
        _bobCtrl.repeat(reverse: true);
        break;
      case 'listening':
        _bobCtrl.repeat(reverse: true);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _floatCtrl,
      _breathCtrl,
      _blinkCtrl,
      _mouthCtrl,
      _waveCtrl,
      _bobCtrl,
      _thinkCtrl,
      _legCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = BitmojiDB.get(widget.doctorId, widget.gender);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatAnim,
        _blinkAnim,
        _mouthAnim,
        _waveAnim,
        _bobAnim,
        _breathAnim,
        _thinkAnim,
        _legAnim,
      ]),
      builder: (_, __) {
        // Smooth floating
        final floatY = math.sin(_floatAnim.value * math.pi) * 9.0;

        // Mouth amplitude: external (TTS-driven) overrides internal animation
        final mouthVal = widget.mouthAmplitude ?? _mouthAnim.value;

        // Head tilt
        double headTilt = 0;
        if (widget.avatarState == 'listening') {
          headTilt = (_bobAnim.value - 0.5) * 0.07;
        } else if (widget.avatarState == 'speaking') {
          headTilt = math.sin(_bobAnim.value * math.pi * 2) * 0.028;
        } else if (widget.avatarState == 'waving') {
          headTilt = math.sin(_bobAnim.value * math.pi) * 0.055;
        }

        return Transform.translate(
          offset: Offset(0, floatY),
          child: SizedBox(
            width: widget.size,
            height: widget.size * 1.52,
            child: CustomPaint(
              painter: _Bitmoji3DPainter(
                profile: profile,
                state: widget.avatarState,
                blinkVal: _blinkAnim.value,
                mouthVal: mouthVal,
                waveVal: _waveAnim.value,
                headTilt: headTilt,
                breathVal: _breathAnim.value,
                thinkVal: _thinkAnim.value,
                legVal: _legAnim.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  3D BITMOJI PAINTER — Snapchat proportions & lighting
// ══════════════════════════════════════════════════════════════════
//
//  Layout (% of canvas height):
//    Head center : 19%    Head radius: ~24% of width
//    Shoulder    : 39%
//    Waist       : 58%
//    Hip         : 64%
//    Knee        : 80%
//    Ankle       : 92%
//    Ground      : 98%
//
//  Key light: top-left at (-0.4, -0.45)
//  Fill light: top-right at (0.3, -0.2), weaker
//  Rim light: bottom-right, very weak warm

class _Bitmoji3DPainter extends CustomPainter {
  final BitmojiProfile profile;
  final String state;
  final double blinkVal, mouthVal, waveVal, headTilt;
  final double breathVal, thinkVal, legVal;

  static const _kLight = Alignment(-0.42, -0.45);

  _Bitmoji3DPainter({
    required this.profile,
    required this.state,
    required this.blinkVal,
    required this.mouthVal,
    required this.waveVal,
    required this.headTilt,
    required this.breathVal,
    required this.thinkVal,
    required this.legVal,
  });

  // ── Core shading helpers ──────────────────────────────────────

  /// Sphere-shaded paint: light top-left, shadow bottom-right
  Paint _sphere(Color base, Rect r, {double hi = 0.45, double sh = 0.38}) {
    return Paint()
      ..shader = RadialGradient(
        center: _kLight,
        radius: 0.88,
        colors: [
          Color.lerp(base, Colors.white, hi)!,
          base,
          Color.lerp(base, const Color(0xFF0A0500), sh)!,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(r);
  }

  /// Cylinder (left-to-right or top-to-bottom) for limbs
  Paint _cyl(Color base, Rect r, {bool vertical = false}) {
    final light = Color.lerp(base, Colors.white, 0.32)!;
    final dark = Color.lerp(base, Colors.black, 0.36)!;
    return Paint()
      ..shader = LinearGradient(
        begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
        end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [dark, light, base, dark],
        stops: const [0.0, 0.18, 0.58, 1.0],
      ).createShader(r);
  }

  /// Specular highlight — small white oval
  void _spec(
    Canvas c,
    Offset center,
    double rx,
    double ry, {
    double opacity = 0.7,
  }) {
    c.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: opacity),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
            ),
    );
  }

  /// Soft ambient occlusion shadow
  void _ao(Canvas c, Rect r, {double blur = 8, double opacity = 0.22}) {
    c.drawOval(
      r,
      Paint()
        ..color = Colors.black.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final headR = w * 0.238;
    final headCY = h * 0.198;
    final shoulderY = h * 0.385;
    final waistY = h * 0.575;
    final hipY = h * 0.635;
    final kneeY = h * 0.790;
    final ankleY = h * 0.910;
    final groundY = h * 0.972;
    final sw = w * 0.418; // shoulder half-width

    // Ground shadow
    _ao(
      canvas,
      Rect.fromCenter(
        center: Offset(cx, groundY + 4),
        width: w * 0.7,
        height: w * 0.075,
      ),
      blur: 16,
      opacity: 0.2,
    );

    // ── Draw back-layer (legs behind torso) ─────────────────────
    _drawLegs(canvas, cx, w, hipY, kneeY, ankleY, groundY);

    // ── Torso ───────────────────────────────────────────────────
    _drawTorso(canvas, cx, w, shoulderY, waistY, hipY, sw);

    // ── Arms (behind = left, front = right waving) ──────────────
    _drawLeftArm(canvas, cx, w, shoulderY, waistY, sw);
    _drawRightArm(canvas, cx, w, shoulderY, waistY, sw);

    // ── Head (with tilt pivot) ───────────────────────────────────
    canvas.save();
    canvas.translate(cx, headCY);
    canvas.rotate(headTilt);
    canvas.translate(-cx, -headCY);

    _drawNeck(canvas, cx, w, headCY, headR, shoulderY);
    _drawHead(canvas, cx, w, headCY, headR);
    _drawHair(canvas, cx, w, headCY, headR);
    _drawEars(canvas, cx, w, headCY, headR);
    _drawFace(canvas, cx, w, headCY, headR);
    if (profile.hasGlasses) _drawGlasses(canvas, cx, w, headCY, headR);

    canvas.restore();

    if (state == 'thinking') _drawThinkBubbles(canvas, cx, w, headCY, headR);
  }

  // ════════════════════════════════════════════════════════════════
  //  NECK
  // ════════════════════════════════════════════════════════════════
  void _drawNeck(
    Canvas c,
    double cx,
    double w,
    double hcy,
    double r,
    double sy,
  ) {
    final nw = r * 0.52;
    final nh = sy - hcy - r * 0.68;
    final ny = hcy + r * 0.76;
    final rect = Rect.fromCenter(
      center: Offset(cx, ny + nh / 2),
      width: nw,
      height: nh,
    );
    c.drawRect(rect, _sphere(profile.skinColor, rect, hi: 0.28, sh: 0.22));
    // Neck shadow under chin
    _ao(
      c,
      Rect.fromCenter(
        center: Offset(cx, hcy + r * 0.88),
        width: nw * 1.4,
        height: r * 0.18,
      ),
      blur: 6,
      opacity: 0.28,
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  HEAD — Snapchat bitmoji: large, slightly wide at cheeks
  // ════════════════════════════════════════════════════════════════
  void _drawHead(Canvas c, double cx, double w, double hcy, double r) {
    // Outer ambient occlusion (rim shadow)
    c.drawOval(
      Rect.fromCenter(
        center: Offset(cx + r * 0.05, hcy + r * 0.06),
        width: r * 2.18,
        height: r * 2.38,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main head — slightly taller than wide like Snapchat
    final headRect = Rect.fromCenter(
      center: Offset(cx, hcy),
      width: r * 2.08,
      height: r * 2.35,
    );
    c.drawOval(
      headRect,
      _sphere(profile.skinColor, headRect, hi: 0.44, sh: 0.30),
    );

    // Cheek volume — slightly wider midface
    for (final s in [-1.0, 1.0]) {
      final chRect = Rect.fromCenter(
        center: Offset(cx + s * r * 0.88, hcy + r * 0.18),
        width: r * 0.55,
        height: r * 0.62,
      );
      c.drawOval(
        chRect,
        Paint()
          ..color = profile.skinColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Forehead specular
    _spec(
      c,
      Offset(cx - r * 0.18, hcy - r * 0.62),
      r * 0.28,
      r * 0.16,
      opacity: 0.22,
    );

    // Cheek blush (soft)
    for (final s in [-1.0, 1.0]) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx + s * r * 0.66, hcy + r * 0.26),
          width: r * 0.55,
          height: r * 0.34,
        ),
        Paint()
          ..color = profile.blushColor.withValues(alpha: 0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11),
      );
    }

    // Chin definition
    final chinR = Rect.fromCenter(
      center: Offset(cx, hcy + r * 0.82),
      width: r * 1.42,
      height: r * 0.78,
    );
    c.drawOval(
      chinR,
      Paint()
        ..color = Color.lerp(
          profile.skinColor,
          Colors.black,
          0.06,
        )!.withValues(alpha: 0.5),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  EARS
  // ════════════════════════════════════════════════════════════════
  void _drawEars(Canvas c, double cx, double w, double hcy, double r) {
    for (final s in [-1.0, 1.0]) {
      final ex = cx + s * r * 1.0;
      final ey = hcy + r * 0.08;
      final earR = Rect.fromCenter(
        center: Offset(ex, ey),
        width: r * 0.32,
        height: r * 0.44,
      );
      c.drawOval(earR, _sphere(profile.skinColor, earR, hi: 0.2, sh: 0.28));
      // Inner ear
      c.drawOval(
        Rect.fromCenter(
          center: Offset(ex + s * 1.5, ey + r * 0.03),
          width: r * 0.14,
          height: r * 0.24,
        ),
        Paint()
          ..color = Color.lerp(
            profile.skinColor,
            const Color(0xFF8B2020),
            0.22,
          )!,
      );
      // Ear shadow (where ear meets head)
      _ao(
        c,
        Rect.fromCenter(
          center: Offset(ex - s * r * 0.06, ey),
          width: r * 0.18,
          height: r * 0.42,
        ),
        blur: 4,
        opacity: 0.2,
      );

      // Earring
      if (profile.gender == 'female' &&
          profile.earringColor != Colors.transparent) {
        final eRing = profile.earringColor;
        c.drawCircle(
          Offset(ex, ey + r * 0.3),
          r * 0.075,
          Paint()..color = eRing,
        );
        _spec(
          c,
          Offset(ex - r * 0.024, ey + r * 0.27),
          r * 0.022,
          r * 0.016,
          opacity: 0.8,
        );
        c.drawCircle(
          Offset(ex, ey + r * 0.3),
          r * 0.075,
          Paint()
            ..color = Color.lerp(eRing, Colors.black, 0.2)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.025,
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  HAIR — 3D volumetric
  // ════════════════════════════════════════════════════════════════
  void _drawHair(Canvas c, double cx, double w, double hcy, double r) {
    final h = profile.hairColor;
    final hDark = Color.lerp(h, Colors.black, 0.48)!;
    final hLight = Color.lerp(h, Colors.white, 0.38)!;
    final hMid = Color.lerp(h, Colors.white, 0.08)!;

    Paint hairPaint(Rect rect) => Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.28, -0.52),
        radius: 0.9,
        colors: [hLight, hMid, h, hDark],
        stops: const [0.0, 0.22, 0.55, 1.0],
      ).createShader(rect);

    Paint hairSide(Rect rect, bool leftSide) =>
        Paint()
          ..shader = RadialGradient(
            center: Alignment(leftSide ? -0.6 : 0.6, -0.4),
            radius: 0.85,
            colors: [Color.lerp(h, Colors.white, 0.28)!, h, hDark],
          ).createShader(rect);

    switch (profile.hairstyle) {
      case BitHair.shortSide:
        // ── Short side-parted (male) ─────────────────────────────
        // Base cap
        c.save();
        c.clipRect(Rect.fromLTRB(0, 0, w, hcy + r * 0.12));
        final capR = Rect.fromCenter(
          center: Offset(cx, hcy - r * 0.38),
          width: r * 2.2,
          height: r * 1.5,
        );
        c.drawOval(capR, hairPaint(capR));
        c.restore();
        // Temples
        for (final s in [-1.0, 1.0]) {
          final tR = Rect.fromCenter(
            center: Offset(cx + s * r * 0.9, hcy + r * 0.3),
            width: r * 0.28,
            height: r * 0.38,
          );
          c.drawOval(tR, hairSide(tR, s < 0));
        }
        // Side part
        c.drawLine(
          Offset(cx - r * 0.18, hcy - r * 0.9),
          Offset(cx - r * 0.28, hcy - r * 0.44),
          Paint()
            ..color = hDark
            ..strokeWidth = r * 0.04
            ..strokeCap = StrokeCap.round,
        );
        // Hair strand lines
        for (int i = 0; i < 3; i++) {
          c.drawLine(
            Offset(cx - r * 0.05 + i * r * 0.18, hcy - r * 0.85),
            Offset(cx + r * 0.08 + i * r * 0.22, hcy - r * 0.42),
            Paint()
              ..color = hDark.withValues(alpha: 0.22)
              ..strokeWidth = r * 0.026,
          );
        }
        _spec(
          c,
          Offset(cx + r * 0.12, hcy - r * 0.82),
          r * 0.2,
          r * 0.1,
          opacity: 0.35,
        );
        break;

      case BitHair.longWavy:
        // ── Long wavy (female) ────────────────────────────────────
        final topR = Rect.fromCenter(
          center: Offset(cx, hcy - r * 0.3),
          width: r * 2.22,
          height: r * 1.58,
        );
        c.drawOval(topR, hairPaint(topR));
        for (final s in [-1.0, 1.0]) {
          // Main lock
          final lkPath = Path()
            ..moveTo(cx + s * r * 0.93, hcy - r * 0.18)
            ..cubicTo(
              cx + s * r * 1.44,
              hcy + r * 0.32,
              cx + s * r * 1.52,
              hcy + r * 0.92,
              cx + s * r * 1.3,
              hcy + r * 1.58,
            )
            ..cubicTo(
              cx + s * r * 1.06,
              hcy + r * 1.32,
              cx + s * r * 0.94,
              hcy + r * 0.72,
              cx + s * r * 0.88,
              hcy - r * 0.18,
            )
            ..close();
          final lkB = Rect.fromLTWH(
            cx + (s < 0 ? -r * 1.52 : r * 0.88),
            hcy - r * 0.18,
            r * 0.64,
            r * 1.76,
          );
          c.drawPath(lkPath, hairSide(lkB, s < 0));
          // Wave highlight strand
          final wPath = Path()
            ..moveTo(cx + s * r * 1.1, hcy + r * 0.22)
            ..cubicTo(
              cx + s * r * 1.32,
              hcy + r * 0.52,
              cx + s * r * 1.18,
              hcy + r * 0.82,
              cx + s * r * 1.28,
              hcy + r * 1.1,
            );
          c.drawPath(
            wPath,
            Paint()
              ..color = hLight.withValues(alpha: 0.38)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.045
              ..strokeCap = StrokeCap.round,
          );
          // Dark strand depth
          final dPath = Path()
            ..moveTo(cx + s * r * 0.96, hcy + r * 0.12)
            ..cubicTo(
              cx + s * r * 1.28,
              hcy + r * 0.55,
              cx + s * r * 1.35,
              hcy + r * 0.95,
              cx + s * r * 1.18,
              hcy + r * 1.38,
            );
          c.drawPath(
            dPath,
            Paint()
              ..color = hDark.withValues(alpha: 0.28)
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.035
              ..strokeCap = StrokeCap.round,
          );
        }
        _spec(
          c,
          Offset(cx - r * 0.15, hcy - r * 0.85),
          r * 0.24,
          r * 0.12,
          opacity: 0.38,
        );
        break;

      case BitHair.curly:
        // ── Curly afro style ─────────────────────────────────────
        // Dense base
        final baseR = Rect.fromCenter(
          center: Offset(cx, hcy - r * 0.35),
          width: r * 2.38,
          height: r * 1.78,
        );
        c.drawOval(baseR, hairPaint(baseR));
        // Perimeter curls
        for (int i = 0; i < 14; i++) {
          final a = (i / 14) * 2 * math.pi - math.pi / 2;
          final bx = cx + math.cos(a) * r * 1.0;
          final by = hcy - r * 0.32 + math.sin(a) * r * 0.76;
          final cr2 = r * (0.25 + (i % 3) * 0.04);
          final bR = Rect.fromCenter(
            center: Offset(bx, by),
            width: cr2 * 2,
            height: cr2 * 2,
          );
          c.drawOval(bR, hairPaint(bR));
        }
        _spec(
          c,
          Offset(cx - r * 0.2, hcy - r * 1.0),
          r * 0.22,
          r * 0.12,
          opacity: 0.32,
        );
        break;

      case BitHair.bun:
        // ── High bun ─────────────────────────────────────────────
        c.save();
        c.clipRect(Rect.fromLTRB(0, 0, w, hcy + r * 0.04));
        final topR2 = Rect.fromCenter(
          center: Offset(cx, hcy - r * 0.22),
          width: r * 2.18,
          height: r * 1.5,
        );
        c.drawOval(topR2, hairPaint(topR2));
        c.restore();
        // Bun sphere
        final bunR = Rect.fromCenter(
          center: Offset(cx, hcy - r * 1.08),
          width: r * 0.76,
          height: r * 0.76,
        );
        c.drawOval(bunR, _sphere(h, bunR, hi: 0.42, sh: 0.38));
        _spec(
          c,
          Offset(cx - r * 0.12, hcy - r * 1.18),
          r * 0.14,
          r * 0.08,
          opacity: 0.45,
        );
        // Hair tie
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, hcy - r * 0.72),
            width: r * 0.52,
            height: r * 0.17,
          ),
          Paint()..color = profile.accessoryColor.withValues(alpha: 0.88),
        );
        break;

      case BitHair.straight:
        // ── Straight shoulder-length ─────────────────────────────
        c.save();
        c.clipRect(Rect.fromLTRB(0, 0, w, hcy + r * 1.12));
        final topR3 = Rect.fromCenter(
          center: Offset(cx, hcy - r * 0.22),
          width: r * 2.22,
          height: r * 1.54,
        );
        c.drawOval(topR3, hairPaint(topR3));
        for (final s in [-1.0, 1.0]) {
          final pR = Rect.fromLTRB(
            cx + s * r * 0.86,
            hcy - r * 0.12,
            cx + s * r * 1.2,
            hcy + r * 1.12,
          );
          c.drawRect(pR, hairSide(pR, s < 0));
          // Strand lines
          for (int i = 0; i < 4; i++) {
            final lx = cx + s * (r * 0.95 + i * r * 0.06);
            c.drawLine(
              Offset(lx, hcy - r * 0.1),
              Offset(lx + s * r * 0.05, hcy + r * 1.1),
              Paint()
                ..color = hDark.withValues(alpha: 0.2)
                ..strokeWidth = r * 0.028,
            );
          }
        }
        c.restore();
        _spec(
          c,
          Offset(cx - r * 0.1, hcy - r * 0.9),
          r * 0.22,
          r * 0.12,
          opacity: 0.36,
        );
        break;

      case BitHair.medium:
        // ── Medium length ────────────────────────────────────────
        c.save();
        c.clipRect(Rect.fromLTRB(0, 0, w, hcy + r * 0.7));
        final topR4 = Rect.fromCenter(
          center: Offset(cx, hcy - r * 0.22),
          width: r * 2.22,
          height: r * 1.54,
        );
        c.drawOval(topR4, hairPaint(topR4));
        for (final s in [-1.0, 1.0]) {
          final sbR = Rect.fromCenter(
            center: Offset(cx + s * r * 0.94, hcy + r * 0.3),
            width: r * 0.52,
            height: r * 0.76,
          );
          c.drawOval(sbR, hairSide(sbR, s < 0));
        }
        c.restore();
        _spec(
          c,
          Offset(cx - r * 0.12, hcy - r * 0.88),
          r * 0.22,
          r * 0.12,
          opacity: 0.36,
        );
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  FACE
  // ════════════════════════════════════════════════════════════════
  void _drawFace(Canvas c, double cx, double w, double hcy, double r) {
    _drawEyebrows(c, cx, hcy, r);
    _drawEyes(c, cx, hcy, r);
    _drawNose(c, cx, hcy, r);
    _drawMouth(c, cx, hcy, r);
  }

  void _drawEyebrows(Canvas c, double cx, double hcy, double r) {
    final by = hcy - r * 0.27;
    final bc = Color.lerp(profile.hairColor, const Color(0xFF1A1A1A), 0.35)!;
    final bp = Paint()
      ..color = bc
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.088
      ..strokeCap = StrokeCap.round;
    final lift = state == 'thinking' ? r * 0.09 : 0.0;

    // Left — arched, thicker at arch
    final lbPath = Path()
      ..moveTo(cx - r * 0.56, by + r * 0.04 - lift)
      ..cubicTo(
        cx - r * 0.4,
        by - r * 0.1 - lift,
        cx - r * 0.2,
        by - r * 0.155 - lift,
        cx - r * 0.05,
        by - r * 0.045 - lift,
      );
    c.drawPath(lbPath, bp);
    // Brow tail (slightly thinner)
    c.drawPath(
      lbPath,
      Paint()
        ..color = Color.lerp(bc, Colors.black, 0.15)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..strokeCap = StrokeCap.round,
    );

    // Right
    final rbPath = Path()
      ..moveTo(cx + r * 0.05, by - r * 0.045 - lift)
      ..cubicTo(
        cx + r * 0.2,
        by - r * 0.155 - lift,
        cx + r * 0.4,
        by - r * 0.1 - lift,
        cx + r * 0.56,
        by + r * 0.04 - lift,
      );
    c.drawPath(rbPath, bp);
    c.drawPath(
      rbPath,
      Paint()
        ..color = Color.lerp(bc, Colors.black, 0.15)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEyes(Canvas c, double cx, double hcy, double r) {
    final ey = hcy - r * 0.09;
    final esp = r * 0.365;

    for (final s in [-1.0, 1.0]) {
      final ex = cx + s * esp;
      final erx = r * 0.192; // large Bitmoji eyes
      final ery = r * 0.168;

      // ── Eye socket shadow ─────────────────────────────────────
      c.drawOval(
        Rect.fromCenter(
          center: Offset(ex + r * 0.015, ey + r * 0.025),
          width: erx * 2.9,
          height: ery * 2.6,
        ),
        Paint()..color = Color.lerp(profile.skinColor, Colors.black, 0.14)!,
      );

      final scleraR = Rect.fromCenter(
        center: Offset(ex, ey),
        width: erx * 2.55,
        height: ery * 2.28,
      );

      // ── Sclera ───────────────────────────────────────────────
      c.drawOval(
        scleraR,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.22, -0.28),
            radius: 0.82,
            colors: [Colors.white, const Color(0xFFF2EDE8)],
          ).createShader(scleraR),
      );

      if (blinkVal < 0.62) {
        // ── Iris (big, Snapchat style) ────────────────────────
        final eyeSwivel = state == 'thinking'
            ? (thinkVal - 0.5) * erx * 1.4
            : 0.0;
        final irisC = Offset(ex + eyeSwivel, ey);
        final irisR = Rect.fromCenter(
          center: irisC,
          width: erx * 1.82,
          height: ery * 1.82,
        );
        c.drawOval(
          irisR,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.28, -0.38),
              radius: 0.88,
              colors: [
                Color.lerp(profile.eyeColor, Colors.white, 0.55)!,
                profile.eyeColor,
                Color.lerp(profile.eyeColor, Colors.black, 0.58)!,
              ],
              stops: const [0.0, 0.42, 1.0],
            ).createShader(irisR),
        );

        // Limbal ring (dark edge of iris)
        c.drawOval(
          irisR,
          Paint()
            ..color = Color.lerp(
              profile.eyeColor,
              Colors.black,
              0.65,
            )!.withValues(alpha: 0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.032,
        );

        // Pupil
        c.drawCircle(
          irisC,
          erx * 0.64,
          Paint()..color = const Color(0xFF080808),
        );

        // Main catch-light (large)
        c.drawCircle(
          Offset(irisC.dx - erx * 0.32, ey - ery * 0.34),
          erx * 0.3,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
        // Secondary small highlight
        c.drawCircle(
          Offset(irisC.dx + erx * 0.16, ey + ery * 0.18),
          erx * 0.13,
          Paint()..color = Colors.white.withValues(alpha: 0.52),
        );

        // Lower lid pinkish line
        c.drawArc(
          scleraR,
          0,
          math.pi,
          false,
          Paint()
            ..color = Color.lerp(
              profile.skinColor,
              const Color(0xFFFF8888),
              0.18,
            )!
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.028,
        );
      } else {
        // ── Blink ──────────────────────────────────────────────
        final lid = Path()
          ..moveTo(ex - erx * 1.27, ey)
          ..quadraticBezierTo(
            ex,
            ey + ery * blinkVal * 1.7,
            ex + erx * 1.27,
            ey,
          );
        c.drawPath(lid, Paint()..color = profile.skinColor);
        // Lash line when closed
        c.drawPath(
          lid,
          Paint()
            ..color = const Color(0xFF1A1A1A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.062
            ..strokeCap = StrokeCap.round,
        );
      }

      // ── Upper lash line (always visible) ─────────────────────
      c.drawArc(
        scleraR,
        -math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF181818)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.068
          ..strokeCap = StrokeCap.round,
      );

      // ── Eyelid crease ─────────────────────────────────────────
      c.drawArc(
        Rect.fromCenter(
          center: Offset(ex, ey - ery * 0.22),
          width: erx * 2.38,
          height: ery * 1.45,
        ),
        -math.pi * 0.84,
        math.pi * 0.84,
        false,
        Paint()
          ..color = Color.lerp(profile.skinColor, Colors.black, 0.17)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.03,
      );

      // Outer eye corner highlight
      _spec(
        c,
        Offset(ex - erx * 0.9, ey - ery * 0.45),
        erx * 0.22,
        ery * 0.14,
        opacity: 0.18,
      );
    }
  }

  void _drawNose(Canvas c, double cx, double hcy, double r) {
    final ny = hcy + r * 0.2;
    final np = Color.lerp(profile.skinColor, Colors.black, 0.22)!;
    final nosePaint = Paint()
      ..color = np
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055
      ..strokeCap = StrokeCap.round;

    // Bridge (subtle)
    final bridge = Path()
      ..moveTo(cx + r * 0.04, hcy - r * 0.04)
      ..cubicTo(
        cx - r * 0.035,
        ny,
        cx - r * 0.1,
        ny + r * 0.04,
        cx - r * 0.155,
        ny + r * 0.135,
      );
    c.drawPath(bridge, nosePaint);

    // Nose tip 3D sphere
    final tipR = Rect.fromCenter(
      center: Offset(cx, ny + r * 0.1),
      width: r * 0.26,
      height: r * 0.2,
    );
    c.drawOval(tipR, _sphere(profile.skinColor, tipR, hi: 0.28, sh: 0.18));
    _spec(
      c,
      Offset(cx - r * 0.04, ny + r * 0.06),
      r * 0.07,
      r * 0.05,
      opacity: 0.55,
    );

    // Nostrils
    c.drawArc(
      Rect.fromCenter(
        center: Offset(cx - r * 0.16, ny + r * 0.16),
        width: r * 0.26,
        height: r * 0.19,
      ),
      0,
      math.pi * 1.4,
      false,
      nosePaint,
    );
    c.drawArc(
      Rect.fromCenter(
        center: Offset(cx + r * 0.16, ny + r * 0.16),
        width: r * 0.26,
        height: r * 0.19,
      ),
      -math.pi * 0.4,
      math.pi * 1.4,
      false,
      nosePaint,
    );
  }

  void _drawMouth(Canvas c, double cx, double hcy, double r) {
    final my = hcy + r * 0.565;
    final lipUpper = Color.lerp(profile.skinColor, profile.lipColor, 0.72)!;
    final lipLower = profile.lipColor;
    final lipLight = Color.lerp(lipLower, Colors.white, 0.32)!;

    if (mouthVal > 0.04) {
      // ══ OPEN MOUTH (speaking) ═══════════════════════════════
      final openH = mouthVal * r * 0.32;

      // Outer mouth path (rounded)
      final mPath = Path()
        ..moveTo(cx - r * 0.33, my)
        ..cubicTo(
          cx - r * 0.37,
          my + openH * 2.8,
          cx + r * 0.37,
          my + openH * 2.8,
          cx + r * 0.33,
          my,
        );
      c.drawPath(mPath, Paint()..color = const Color(0xFF2A0606));

      // Tongue (visible when open enough)
      if (openH > r * 0.07) {
        final tongueR = Rect.fromCenter(
          center: Offset(cx, my + openH * 2.0),
          width: r * 0.36,
          height: openH * 0.72,
        );
        c.drawOval(
          tongueR,
          _sphere(const Color(0xFFE05060), tongueR, hi: 0.28, sh: 0.22),
        );
        // Tongue crease
        c.drawLine(
          Offset(cx, my + openH * 1.72),
          Offset(cx, my + openH * 2.28),
          Paint()
            ..color = const Color(0xFFBB3044)
            ..strokeWidth = r * 0.04
            ..strokeCap = StrokeCap.round,
        );
      }

      // Teeth
      c.save();
      c.clipPath(mPath);
      c.drawRect(
        Rect.fromLTWH(
          cx - r * 0.3,
          my - r * 0.02,
          r * 0.6,
          openH * 1.25 + r * 0.02,
        ),
        Paint()..color = const Color(0xFFF8F6F2),
      );
      // Tooth lines
      for (int i = -2; i <= 2; i++) {
        if (i == 0) continue;
        c.drawLine(
          Offset(cx + i * r * 0.1, my),
          Offset(cx + i * r * 0.1, my + openH * 1.1),
          Paint()
            ..color = const Color(0xFFE8E0D8)
            ..strokeWidth = r * 0.032,
        );
      }
      c.restore();

      // Upper lip (Cupid's bow)
      final ulPath = Path()
        ..moveTo(cx - r * 0.33, my)
        ..cubicTo(
          cx - r * 0.22,
          my - r * 0.125,
          cx - r * 0.06,
          my - r * 0.15,
          cx,
          my - r * 0.07,
        )
        ..cubicTo(
          cx + r * 0.06,
          my - r * 0.15,
          cx + r * 0.22,
          my - r * 0.125,
          cx + r * 0.33,
          my,
        )
        ..cubicTo(
          cx + r * 0.22,
          my + r * 0.02,
          cx - r * 0.22,
          my + r * 0.02,
          cx - r * 0.33,
          my,
        )
        ..close();
      c.drawPath(
        ulPath,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lipLight, lipUpper, lipLower],
              ).createShader(
                Rect.fromLTWH(cx - r * 0.35, my - r * 0.16, r * 0.7, r * 0.2),
              ),
      );

      // Lower lip
      final llR = Rect.fromCenter(
        center: Offset(cx, my + openH * 1.0),
        width: r * 0.64,
        height: r * 0.16 + openH * 0.25,
      );
      c.drawOval(llR, _sphere(lipLower, llR, hi: 0.28, sh: 0.22));
      _spec(
        c,
        Offset(cx - r * 0.06, my + openH * 0.98 - r * 0.02),
        r * 0.12,
        r * 0.055,
        opacity: 0.38,
      );
    } else if (state == 'idle' || state == 'waving') {
      // ══ SMILE ════════════════════════════════════════════════
      final sd = r * 0.155; // smile depth

      // Upper lip shape
      final ulPath = Path()
        ..moveTo(cx - r * 0.33, my + r * 0.02)
        ..cubicTo(
          cx - r * 0.22,
          my - r * 0.105,
          cx - r * 0.07,
          my - r * 0.148,
          cx,
          my - r * 0.065,
        )
        ..cubicTo(
          cx + r * 0.07,
          my - r * 0.148,
          cx + r * 0.22,
          my - r * 0.105,
          cx + r * 0.33,
          my + r * 0.02,
        )
        ..lineTo(cx + r * 0.33, my + sd * 0.55)
        ..cubicTo(
          cx + r * 0.18,
          my + sd * 0.32,
          cx - r * 0.18,
          my + sd * 0.32,
          cx - r * 0.33,
          my + sd * 0.55,
        )
        ..close();
      c.drawPath(
        ulPath,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lipLight, lipUpper],
              ).createShader(
                Rect.fromLTWH(cx - r * 0.34, my - r * 0.15, r * 0.68, sd),
              ),
      );

      // Smile opening (dark inside)
      final smilePath = Path()
        ..moveTo(cx - r * 0.33, my + r * 0.02)
        ..cubicTo(
          cx - r * 0.18,
          my + sd * 1.1,
          cx + r * 0.18,
          my + sd * 1.1,
          cx + r * 0.33,
          my + r * 0.02,
        )
        ..lineTo(cx + r * 0.33, my + sd * 1.72)
        ..cubicTo(
          cx + r * 0.18,
          my + sd * 2.35,
          cx - r * 0.18,
          my + sd * 2.35,
          cx - r * 0.33,
          my + sd * 1.72,
        )
        ..close();
      c.drawPath(smilePath, Paint()..color = const Color(0xFF250606));

      // Teeth
      c.save();
      c.clipPath(smilePath);
      c.drawRect(
        Rect.fromLTWH(cx - r * 0.29, my, r * 0.58, sd * 1.28),
        Paint()..color = const Color(0xFFF8F5F0),
      );
      for (int i = -2; i <= 2; i++) {
        if (i == 0) continue;
        c.drawLine(
          Offset(cx + i * r * 0.1, my),
          Offset(cx + i * r * 0.1, my + sd * 1.1),
          Paint()
            ..color = const Color(0xFFEAE2D8)
            ..strokeWidth = r * 0.03,
        );
      }
      c.restore();

      // Lower lip
      final llR2 = Rect.fromCenter(
        center: Offset(cx, my + sd * 1.98),
        width: r * 0.56,
        height: r * 0.145,
      );
      c.drawOval(llR2, _sphere(lipLower, llR2, hi: 0.28, sh: 0.18));
      _spec(
        c,
        Offset(cx - r * 0.04, my + sd * 1.96 - r * 0.018),
        r * 0.1,
        r * 0.046,
        opacity: 0.36,
      );

      // Smile dimples
      for (final s in [-1.0, 1.0]) {
        c.drawCircle(
          Offset(cx + s * r * 0.36, my + sd * 0.5),
          r * 0.045,
          Paint()
            ..color = Color.lerp(
              profile.skinColor,
              profile.blushColor,
              0.45,
            )!.withValues(alpha: 0.7),
        );
      }
    } else {
      // ══ NEUTRAL ══════════════════════════════════════════════
      final ulPath = Path()
        ..moveTo(cx - r * 0.29, my)
        ..cubicTo(
          cx - r * 0.2,
          my - r * 0.085,
          cx + r * 0.2,
          my - r * 0.085,
          cx + r * 0.29,
          my,
        )
        ..lineTo(cx + r * 0.29, my + r * 0.09)
        ..cubicTo(
          cx + r * 0.2,
          my + r * 0.068,
          cx - r * 0.2,
          my + r * 0.068,
          cx - r * 0.29,
          my + r * 0.09,
        )
        ..close();
      c.drawPath(ulPath, Paint()..color = lipUpper);
      final llR3 = Rect.fromCenter(
        center: Offset(cx, my + r * 0.128),
        width: r * 0.44,
        height: r * 0.108,
      );
      c.drawOval(llR3, _sphere(lipLower, llR3, hi: 0.24, sh: 0.18));
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  GLASSES
  // ════════════════════════════════════════════════════════════════
  void _drawGlasses(Canvas c, double cx, double w, double hcy, double r) {
    final ey = hcy - r * 0.09;
    final esp = r * 0.365;
    final fc = profile.accessoryColor;
    final fp = Paint()
      ..color = fc
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.058;
    final fr = r * 0.215;
    for (final s in [-1.0, 1.0]) {
      // Frame
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + s * esp, ey),
            width: fr * 2.35,
            height: fr * 2.05,
          ),
          Radius.circular(fr * 0.48),
        ),
        fp,
      );
      // Lens tint
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + s * esp, ey),
            width: fr * 2.35,
            height: fr * 2.05,
          ),
          Radius.circular(fr * 0.48),
        ),
        Paint()..color = fc.withValues(alpha: 0.07),
      );
      // Frame highlight
      _spec(
        c,
        Offset(cx + s * esp - fr * 0.5, ey - fr * 0.52),
        fr * 0.55,
        fr * 0.1,
        opacity: 0.22,
      );
    }
    c.drawLine(
      Offset(cx - esp + fr * 1.17, ey),
      Offset(cx + esp - fr * 1.17, ey),
      fp,
    );
    c.drawLine(
      Offset(cx - esp - fr * 1.17, ey),
      Offset(cx - esp - fr * 1.65, ey + r * 0.15),
      fp,
    );
    c.drawLine(
      Offset(cx + esp + fr * 1.17, ey),
      Offset(cx + esp + fr * 1.65, ey + r * 0.15),
      fp,
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TORSO — 3D medical coat
  // ════════════════════════════════════════════════════════════════
  void _drawTorso(
    Canvas c,
    double cx,
    double w,
    double sy,
    double wy,
    double hy,
    double sw,
  ) {
    final cm = profile.coatColor;
    final cd = Color.lerp(cm, Colors.black, 0.35)!;
    final cl = Color.lerp(cm, Colors.white, 0.25)!;
    final hw = w * 0.32;

    // ── Main coat body ────────────────────────────────────────
    final torsoPath = Path()
      ..moveTo(cx - sw, sy)
      ..cubicTo(
        cx - sw * 1.06,
        sy + (wy - sy) * 0.48,
        cx - hw * 1.06,
        wy - (hy - wy) * 0.28,
        cx - hw,
        hy,
      )
      ..lineTo(cx + hw, hy)
      ..cubicTo(
        cx + hw * 1.06,
        wy - (hy - wy) * 0.28,
        cx + sw * 1.06,
        sy + (wy - sy) * 0.48,
        cx + sw,
        sy,
      )
      ..close();

    c.drawPath(
      torsoPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cd, cl, Color.lerp(cm, Colors.white, 0.12)!, cm, cd],
          stops: const [0.0, 0.14, 0.42, 0.66, 1.0],
        ).createShader(Rect.fromLTRB(cx - sw, sy, cx + sw, hy)),
    );

    // AO under shoulder crease
    _ao(
      c,
      Rect.fromCenter(
        center: Offset(cx - sw * 0.7, sy + w * 0.04),
        width: sw * 0.5,
        height: w * 0.04,
      ),
      blur: 4,
      opacity: 0.18,
    );
    _ao(
      c,
      Rect.fromCenter(
        center: Offset(cx + sw * 0.7, sy + w * 0.04),
        width: sw * 0.5,
        height: w * 0.04,
      ),
      blur: 4,
      opacity: 0.18,
    );

    // ── White shirt / collar underneath ──────────────────────
    final collarPath = Path()
      ..moveTo(cx - w * 0.125, sy + w * 0.02)
      ..lineTo(cx - w * 0.052, wy * 0.92 + hy * 0.08)
      ..lineTo(cx + w * 0.052, wy * 0.92 + hy * 0.08)
      ..lineTo(cx + w * 0.125, sy + w * 0.02)
      ..close();
    c.drawPath(
      collarPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, const Color(0xFFEEEEEE)],
        ).createShader(Rect.fromLTWH(cx - w * 0.13, sy, w * 0.26, hy - sy)),
    );
    c.drawPath(
      collarPath,
      Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.01,
    );

    // ── Lapels ────────────────────────────────────────────────
    for (final s in [-1.0, 1.0]) {
      final lapel = Path()
        ..moveTo(cx + s * w * 0.125, sy + w * 0.02)
        ..lineTo(cx + s * sw * 0.77, sy + w * 0.01)
        ..cubicTo(
          cx + s * sw * 0.7,
          sy + w * 0.08,
          cx + s * sw * 0.6,
          sy + w * 0.12,
          cx + s * w * 0.062,
          sy + w * 0.19,
        )
        ..close();
      c.drawPath(
        lapel,
        Paint()
          ..shader = LinearGradient(
            begin: s < 0 ? Alignment.centerLeft : Alignment.centerRight,
            end: s < 0 ? Alignment.centerRight : Alignment.centerLeft,
            colors: [cd, cm, cl],
          ).createShader(Rect.fromLTRB(cx - sw, sy, cx + sw, sy + w * 0.2)),
      );
      c.drawPath(
        lapel,
        Paint()
          ..color = cd.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.01,
      );
    }

    // ── Coat buttons ──────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final by = sy + w * 0.135 + i * w * 0.082;
      c.drawCircle(Offset(cx, by), w * 0.016, Paint()..color = cd);
      c.drawCircle(Offset(cx, by), w * 0.011, Paint()..color = cl);
      _spec(
        c,
        Offset(cx - w * 0.005, by - w * 0.005),
        w * 0.005,
        w * 0.004,
        opacity: 0.6,
      );
    }

    // ── Chest pocket ─────────────────────────────────────────
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.14, sy + w * 0.125, w * 0.145, w * 0.1),
        const Radius.circular(3),
      ),
      Paint()..color = cd.withValues(alpha: 0.38),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.14, sy + w * 0.125, w * 0.145, w * 0.1),
        const Radius.circular(3),
      ),
      Paint()
        ..color = cd
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.014,
    );
    // Pen clip
    c.drawLine(
      Offset(cx + w * 0.225, sy + w * 0.125),
      Offset(cx + w * 0.225, sy + w * 0.022),
      Paint()
        ..color = profile.accentColor
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round,
    );
    _spec(
      c,
      Offset(cx + w * 0.218, sy + w * 0.055),
      w * 0.008,
      w * 0.028,
      opacity: 0.45,
    );

    // ── Stethoscope ───────────────────────────────────────────
    final stethC = profile.accentColor;
    final stethP = Paint()
      ..color = stethC
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    final stethPath = Path()
      ..moveTo(cx - w * 0.12, sy + w * 0.12)
      ..cubicTo(
        cx - w * 0.22,
        sy + w * 0.31,
        cx + w * 0.12,
        sy + w * 0.33,
        cx + w * 0.062,
        sy + w * 0.54,
      );
    c.drawPath(stethPath, stethP);
    // Diaphragm disc
    c.drawCircle(
      Offset(cx + w * 0.062, sy + w * 0.58),
      w * 0.042,
      Paint()..color = stethC,
    );
    c.drawCircle(
      Offset(cx + w * 0.062, sy + w * 0.58),
      w * 0.028,
      Paint()..color = Color.lerp(stethC, Colors.white, 0.3)!,
    );
    _spec(
      c,
      Offset(cx + w * 0.052, sy + w * 0.572),
      w * 0.012,
      w * 0.009,
      opacity: 0.55,
    );
    // Ear tubes
    c.drawLine(
      Offset(cx - w * 0.12, sy + w * 0.12),
      Offset(cx - w * 0.22, sy + w * 0.04),
      stethP,
    );
    c.drawLine(
      Offset(cx - w * 0.22, sy + w * 0.04),
      Offset(cx - w * 0.3, sy + w * 0.09),
      stethP,
    );

    // ── Coat fold lines (depth) ───────────────────────────────
    for (final s in [-1.0, 1.0]) {
      c.drawLine(
        Offset(cx + s * sw * 0.6, sy + w * 0.07),
        Offset(cx + s * hw * 0.72, wy - w * 0.04),
        Paint()
          ..color = cd.withValues(alpha: 0.22)
          ..strokeWidth = w * 0.016
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  LEFT ARM (resting)
  // ════════════════════════════════════════════════════════════════
  void _drawLeftArm(
    Canvas c,
    double cx,
    double w,
    double sy,
    double wy,
    double sw,
  ) {
    final lSx = cx - sw * 0.94;
    final lEx = lSx - w * 0.1;
    final lEy = sy + w * 0.252;
    final lHx = lEx - w * 0.048;
    final lHy = wy + w * 0.05;
    _drawArmSegment(
      c,
      Offset(lSx, sy + w * 0.02),
      Offset(lEx, lEy),
      w * 0.116,
      profile.coatColor,
    );
    _drawArmSegment(
      c,
      Offset(lEx, lEy),
      Offset(lHx, lHy),
      w * 0.102,
      profile.coatColor,
    );
    _drawHand3D(c, Offset(lHx, lHy), w, false, 0.0);
  }

  // ════════════════════════════════════════════════════════════════
  //  RIGHT ARM (waving or resting)
  // ════════════════════════════════════════════════════════════════
  void _drawRightArm(
    Canvas c,
    double cx,
    double w,
    double sy,
    double wy,
    double sw,
  ) {
    final rSx = cx + sw * 0.94;

    if (state == 'waving') {
      final armAngle = -math.pi * 0.78 + waveVal * math.pi * 0.44;
      final armLen = w * 0.3;
      final rEx = rSx + math.cos(-math.pi * 0.56) * armLen;
      final rEy = sy + math.sin(-math.pi * 0.56) * armLen;
      final rHx = rSx + math.cos(armAngle) * armLen * 1.88;
      final rHy = sy + math.sin(armAngle) * armLen * 1.88;
      _drawArmSegment(
        c,
        Offset(rSx, sy + w * 0.02),
        Offset(rEx, rEy),
        w * 0.116,
        profile.coatColor,
      );
      _drawArmSegment(
        c,
        Offset(rEx, rEy),
        Offset(rHx, rHy),
        w * 0.102,
        profile.coatColor,
      );
      _drawHand3D(c, Offset(rHx, rHy), w, true, armAngle);
    } else {
      final rEx = rSx + w * 0.1;
      final rEy = sy + w * 0.252;
      final rHx = rEx + w * 0.048;
      final rHy = wy + w * 0.05;
      _drawArmSegment(
        c,
        Offset(rSx, sy + w * 0.02),
        Offset(rEx, rEy),
        w * 0.116,
        profile.coatColor,
      );
      _drawArmSegment(
        c,
        Offset(rEx, rEy),
        Offset(rHx, rHy),
        w * 0.102,
        profile.coatColor,
      );
      _drawHand3D(c, Offset(rHx, rHy), w, false, 0.0);
    }
  }

  void _drawArmSegment(
    Canvas c,
    Offset a,
    Offset b,
    double thickness,
    Color col,
  ) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final angle = math.atan2(dy, dx);
    final perp = angle + math.pi / 2;

    final path = Path()
      ..moveTo(
        a.dx + math.cos(perp) * thickness * 0.56,
        a.dy + math.sin(perp) * thickness * 0.56,
      )
      ..lineTo(
        b.dx + math.cos(perp) * thickness * 0.5,
        b.dy + math.sin(perp) * thickness * 0.5,
      )
      ..lineTo(
        b.dx - math.cos(perp) * thickness * 0.5,
        b.dy - math.sin(perp) * thickness * 0.5,
      )
      ..lineTo(
        a.dx - math.cos(perp) * thickness * 0.56,
        a.dy - math.sin(perp) * thickness * 0.56,
      )
      ..close();

    final bounds = path.getBounds();
    final cd = Color.lerp(col, Colors.black, 0.35)!;
    final cl = Color.lerp(col, Colors.white, 0.26)!;
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [cd, cl, col, cd],
          stops: const [0.0, 0.18, 0.6, 1.0],
        ).createShader(bounds),
    );

    // Elbow/joint cap
    final jointR = Rect.fromCircle(center: b, radius: thickness * 0.52);
    c.drawOval(jointR, _sphere(col, jointR, hi: 0.38, sh: 0.32));
  }

  void _drawHand3D(Canvas c, Offset center, double w, bool open, double angle) {
    final hr = w * 0.056;
    final palmR = Rect.fromCenter(
      center: center,
      width: hr * 2.12,
      height: hr * 2.4,
    );
    c.drawOval(palmR, _sphere(profile.skinColor, palmR, hi: 0.38, sh: 0.25));
    _spec(
      c,
      Offset(center.dx - hr * 0.3, center.dy - hr * 0.35),
      hr * 0.28,
      hr * 0.18,
      opacity: 0.42,
    );

    final fc = profile.skinColor;
    final fd = Color.lerp(fc, Colors.black, 0.28)!;
    final fp = Paint()
      ..color = fc
      ..strokeWidth = hr * 0.76
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fs = Paint()
      ..color = fd
      ..strokeWidth = hr * 0.88
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (open) {
      for (int i = 0; i < 4; i++) {
        final fa = angle - math.pi * 0.26 + i * 0.31;
        final ft = Offset(
          center.dx + math.cos(fa) * hr * 2.5,
          center.dy + math.sin(fa) * hr * 2.5,
        );
        final fm = Offset(
          center.dx + math.cos(fa) * hr * 1.35,
          center.dy + math.sin(fa) * hr * 1.35,
        );
        c.drawLine(center, ft, fs);
        c.drawLine(center, ft, fp);
        // Knuckle
        c.drawCircle(
          fm,
          hr * 0.19,
          Paint()..color = Color.lerp(fc, Colors.black, 0.14)!,
        );
      }
      // Thumb
      final ta = angle + math.pi * 0.44;
      final tt = Offset(
        center.dx + math.cos(ta) * hr * 1.92,
        center.dy + math.sin(ta) * hr * 1.92,
      );
      c.drawLine(center, tt, fs..strokeWidth = hr * 0.96);
      c.drawLine(center, tt, fp..strokeWidth = hr * 0.84);
    } else {
      for (int i = 0; i < 4; i++) {
        final fa = -math.pi * 0.52 + i * 0.24;
        final ft = Offset(
          center.dx + math.cos(fa) * hr * 1.95,
          center.dy + math.sin(fa) * hr * 1.95,
        );
        c.drawLine(center, ft, fs..strokeWidth = hr * 0.84);
        c.drawLine(center, ft, fp..strokeWidth = hr * 0.68);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  LEGS — 3D trousers + shoes
  // ════════════════════════════════════════════════════════════════
  void _drawLegs(
    Canvas c,
    double cx,
    double w,
    double hy,
    double ky,
    double ay,
    double gy,
  ) {
    final lw = w * 0.118;
    final lsp = w * 0.182;
    final lShift = math.sin(legVal * math.pi) * w * 0.011;
    final pc = profile.pantsColor;
    final pd = Color.lerp(pc, Colors.black, 0.36)!;
    final pl = Color.lerp(pc, Colors.white, 0.2)!;

    for (final s in [-1.0, 1.0]) {
      final lx = cx + s * lsp;
      final sh = s == -1 ? lShift : -lShift;

      // ── Upper leg ────────────────────────────────────────────
      final ulPath = Path()
        ..moveTo(lx - lw * 0.96 + sh, hy)
        ..cubicTo(
          lx - lw * 1.02 + sh,
          hy + (ky - hy) * 0.38,
          lx - lw * 0.88 + sh,
          ky - w * 0.04,
          lx - lw * 0.82 + sh,
          ky,
        )
        ..lineTo(lx + lw * 0.82 + sh, ky)
        ..cubicTo(
          lx + lw * 0.88 + sh,
          ky - w * 0.04,
          lx + lw * 1.02 + sh,
          hy + (ky - hy) * 0.38,
          lx + lw * 0.96 + sh,
          hy,
        )
        ..close();
      c.drawPath(
        ulPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [pd, pl, pc, pc, pd],
            stops: const [0.0, 0.18, 0.42, 0.65, 1.0],
          ).createShader(Rect.fromLTRB(lx - lw, hy, lx + lw, ky)),
      );

      // Knee cap (3D)
      final kneeR = Rect.fromCircle(
        center: Offset(lx + sh, ky),
        radius: lw * 0.74,
      );
      c.drawOval(kneeR, _sphere(pc, kneeR, hi: 0.28, sh: 0.32));
      _spec(
        c,
        Offset(lx + sh - lw * 0.22, ky - lw * 0.28),
        lw * 0.18,
        lw * 0.1,
        opacity: 0.32,
      );

      // ── Lower leg ─────────────────────────────────────────────
      final llPath = Path()
        ..moveTo(lx - lw * 0.82 + sh, ky)
        ..cubicTo(
          lx - lw * 0.78 + sh,
          ky + (ay - ky) * 0.38,
          lx - lw * 0.62 + sh,
          ay - w * 0.03,
          lx - lw * 0.58 + sh,
          ay,
        )
        ..lineTo(lx + lw * 0.58 + sh, ay)
        ..cubicTo(
          lx + lw * 0.62 + sh,
          ay - w * 0.03,
          lx + lw * 0.78 + sh,
          ky + (ay - ky) * 0.38,
          lx + lw * 0.82 + sh,
          ky,
        )
        ..close();
      c.drawPath(
        llPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [pd, pl, pc, pd],
            stops: const [0.0, 0.2, 0.62, 1.0],
          ).createShader(Rect.fromLTRB(lx - lw, ky, lx + lw, ay)),
      );

      // Pant crease
      c.drawLine(
        Offset(lx + sh, hy + w * 0.04),
        Offset(lx + sh, ky - w * 0.04),
        Paint()
          ..color = pd.withValues(alpha: 0.24)
          ..strokeWidth = w * 0.012
          ..strokeCap = StrokeCap.round,
      );

      // Ankle / sock
      c.drawOval(
        Rect.fromCenter(
          center: Offset(lx + sh, ay + w * 0.025),
          width: lw * 1.32,
          height: w * 0.062,
        ),
        Paint()..color = pc,
      );

      // ── Shoe ───────────────────────────────────────────────
      _drawShoe3D(c, lx + sh, ay, gy, w, lw, s);
    }
  }

  void _drawShoe3D(
    Canvas c,
    double sx,
    double ay,
    double gy,
    double w,
    double lw,
    double side,
  ) {
    final sc = profile.shoeColor;
    final sd = Color.lerp(sc, Colors.black, 0.48)!;
    final sl = Color.lerp(sc, Colors.white, 0.25)!;
    final shLen = w * 0.24;
    final shH = w * 0.095;
    final sox = w * 0.038 * side;

    final shoeRect = Rect.fromCenter(
      center: Offset(sx + sox, gy - shH * 0.45),
      width: shLen,
      height: shH,
    );

    // Main shoe body
    final shoePath = Path()
      ..moveTo(sx - shLen * 0.28, gy - shH * 1.02)
      ..cubicTo(
        sx - shLen * 0.3,
        gy - shH * 1.28,
        sx + sox + shLen * 0.2,
        gy - shH * 1.28,
        sx + sox + shLen * 0.5,
        gy - shH * 0.58,
      )
      ..cubicTo(
        sx + sox + shLen * 0.53,
        gy - shH * 0.22,
        sx + sox + shLen * 0.49,
        gy,
        sx + sox + shLen * 0.42,
        gy,
      )
      ..lineTo(sx - shLen * 0.25, gy)
      ..cubicTo(
        sx - shLen * 0.36,
        gy,
        sx - shLen * 0.38,
        gy - shH * 0.36,
        sx - shLen * 0.28,
        gy - shH * 1.02,
      )
      ..close();

    c.drawPath(
      shoePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sl, sc, sd],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(shoeRect),
    );

    // Shoe sole
    c.drawPath(
      shoePath,
      Paint()
        ..color = const Color(0xFF333333).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // Toe cap highlight
    _spec(
      c,
      Offset(sx + sox + shLen * 0.12, gy - shH * 0.85),
      shLen * 0.18,
      shH * 0.16,
      opacity: 0.38,
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  THINKING BUBBLES
  // ════════════════════════════════════════════════════════════════
  void _drawThinkBubbles(Canvas c, double cx, double w, double hcy, double r) {
    final bx = cx + r * 1.1;
    final by0 = hcy - r * 0.88;
    final alpha = (0.5 + thinkVal * 0.45).clamp(0.0, 1.0);
    final bubbles = [
      [bx, by0 + r * 0.46, r * 0.082],
      [bx + r * 0.14, by0 + r * 0.26, r * 0.132],
      [bx + r * 0.25, by0 + r * 0.02, r * 0.198],
      [bx + r * 0.3, by0 - r * 0.34, r * 0.305],
    ];
    for (final b in bubbles) {
      c.drawCircle(
        Offset(b[0], b[1]),
        b[2],
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.92),
      );
      c.drawCircle(
        Offset(b[0], b[1]),
        b[2],
        Paint()
          ..color = Colors.blue.withValues(alpha: alpha * 0.68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.03,
      );
      _spec(
        c,
        Offset(b[0] - b[2] * 0.3, b[1] - b[2] * 0.3),
        b[2] * 0.28,
        b[2] * 0.18,
        opacity: alpha * 0.45,
      );
    }
    final last = bubbles.last;
    for (int d = -1; d <= 1; d++) {
      c.drawCircle(
        Offset(last[0] + d * last[2] * 0.38, last[1]),
        last[2] * 0.17,
        Paint()..color = const Color(0xFF1565C0).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_Bitmoji3DPainter old) => true;
}

// ══════════════════════════════════════════════════════════════════
//  PROFILE DATABASE — 8 unique doctors
// ══════════════════════════════════════════════════════════════════

enum BitHair { shortSide, longWavy, curly, bun, straight, medium }

class BitmojiProfile {
  final Color skinColor, hairColor, coatColor, accentColor, eyeColor;
  final Color blushColor, lipColor, pantsColor, shoeColor;
  final Color earringColor, accessoryColor;
  final BitHair hairstyle;
  final bool hasGlasses;
  final String gender;

  const BitmojiProfile({
    required this.skinColor,
    required this.hairColor,
    required this.coatColor,
    required this.accentColor,
    required this.eyeColor,
    required this.blushColor,
    required this.lipColor,
    required this.pantsColor,
    required this.shoeColor,
    required this.earringColor,
    required this.accessoryColor,
    required this.hairstyle,
    required this.hasGlasses,
    required this.gender,
  });
}

class BitmojiDB {
  static const _db = <String, BitmojiProfile>{
    // ── 1: Homme maghrébin, court, blouse bleu marine ─────────────
    '1': BitmojiProfile(
      skinColor: Color(0xFFCF9B6E),
      hairColor: Color(0xFF1C1A18),
      coatColor: Color(0xFF1B3D6E),
      accentColor: Color(0xFF5BB8F5),
      eyeColor: Color(0xFF5C3010),
      blushColor: Color(0xFFD07050),
      lipColor: Color(0xFFB06040),
      pantsColor: Color(0xFF283448),
      shoeColor: Color(0xFF181818),
      earringColor: Colors.transparent,
      accessoryColor: Colors.transparent,
      hairstyle: BitHair.shortSide,
      hasGlasses: false,
      gender: 'male',
    ),
    // ── 2: Femme peau claire, cheveux longs ondulés, blouse blanche
    '2': BitmojiProfile(
      skinColor: Color(0xFFF5C9A5),
      hairColor: Color(0xFF7A3E0A),
      coatColor: Color(0xFFF0F0F0),
      accentColor: Color(0xFF4DB86A),
      eyeColor: Color(0xFF2E7D32),
      blushColor: Color(0xFFFF9A8A),
      lipColor: Color(0xFFD44060),
      pantsColor: Color(0xFF445A66),
      shoeColor: Color(0xFF2A2A2A),
      earringColor: Color(0xFFFFCC00),
      accessoryColor: Color(0xFFFFCC00),
      hairstyle: BitHair.longWavy,
      hasGlasses: false,
      gender: 'female',
    ),
    // ── 3: Homme peau médium, lunettes, blouse sarcelle ──────────
    '3': BitmojiProfile(
      skinColor: Color(0xFFE8B888),
      hairColor: Color(0xFF3E1E00),
      coatColor: Color(0xFF00697A),
      accentColor: Color(0xFF00C4D4),
      eyeColor: Color(0xFF0277BD),
      blushColor: Color(0xFFFF8A65),
      lipColor: Color(0xFF9A5038),
      pantsColor: Color(0xFF1A2070),
      shoeColor: Color(0xFF1A1A1A),
      earringColor: Colors.transparent,
      accessoryColor: Color(0xFF37474F),
      hairstyle: BitHair.medium,
      hasGlasses: true,
      gender: 'male',
    ),
    // ── 4: Homme peau foncée, blouse violette ─────────────────────
    '4': BitmojiProfile(
      skinColor: Color(0xFF8B5322),
      hairColor: Color(0xFF0A0A0A),
      coatColor: Color(0xFF3A0E6E),
      accentColor: Color(0xFF9C27B0),
      eyeColor: Color(0xFF4A148C),
      blushColor: Color(0xFFBF5A3A),
      lipColor: Color(0xFF7A2A18),
      pantsColor: Color(0xFF1A1A1A),
      shoeColor: Color(0xFF4A148C),
      earringColor: Colors.transparent,
      accessoryColor: Colors.transparent,
      hairstyle: BitHair.shortSide,
      hasGlasses: false,
      gender: 'male',
    ),
    // ── 5: Femme cheveux noirs droits, blouse rose ────────────────
    '5': BitmojiProfile(
      skinColor: Color(0xFFFADFC8),
      hairColor: Color(0xFF151515),
      coatColor: Color(0xFFBE1058),
      accentColor: Color(0xFFF06292),
      eyeColor: Color(0xFF880E4F),
      blushColor: Color(0xFFFF80AB),
      lipColor: Color(0xFFE91E63),
      pantsColor: Color(0xFF353535),
      shoeColor: Color(0xFF101010),
      earringColor: Color(0xFFE91E63),
      accessoryColor: Color(0xFFE91E63),
      hairstyle: BitHair.straight,
      hasGlasses: false,
      gender: 'female',
    ),
    // ── 6: Homme cheveux gris, lunettes, blouse verte ─────────────
    '6': BitmojiProfile(
      skinColor: Color(0xFFF0C89A),
      hairColor: Color(0xFF9A9A9A),
      coatColor: Color(0xFF2A6E28),
      accentColor: Color(0xFF4CAF50),
      eyeColor: Color(0xFF004D35),
      blushColor: Color(0xFFFFCCBC),
      lipColor: Color(0xFF8A4A28),
      pantsColor: Color(0xFF3A2018),
      shoeColor: Color(0xFF3A2018),
      earringColor: Colors.transparent,
      accessoryColor: Color(0xFF6D4C41),
      hairstyle: BitHair.medium,
      hasGlasses: true,
      gender: 'male',
    ),
    // ── 7: Femme cheveux bouclés roux, blouse orange ──────────────
    '7': BitmojiProfile(
      skinColor: Color(0xFFE0AB72),
      hairColor: Color(0xFFBF3806),
      coatColor: Color(0xFFBD3000),
      accentColor: Color(0xFFFF9800),
      eyeColor: Color(0xFF6D1800),
      blushColor: Color(0xFFFF8A55),
      lipColor: Color(0xFFD54212),
      pantsColor: Color(0xFF1A5820),
      shoeColor: Color(0xFF4E3428),
      earringColor: Color(0xFFFF9800),
      accessoryColor: Color(0xFFFF9800),
      hairstyle: BitHair.curly,
      hasGlasses: false,
      gender: 'female',
    ),
    // ── 8: Femme chignon, lunettes, blouse grise ──────────────────
    '8': BitmojiProfile(
      skinColor: Color(0xFFD4A278),
      hairColor: Color(0xFF14141E),
      coatColor: Color(0xFF354050),
      accentColor: Color(0xFF80DEEA),
      eyeColor: Color(0xFF1A237E),
      blushColor: Color(0xFFEF9A9A),
      lipColor: Color(0xFFBF5A68),
      pantsColor: Color(0xFF1A1A1A),
      shoeColor: Color(0xFF000000),
      earringColor: Color(0xFF80DEEA),
      accessoryColor: Color(0xFF263238),
      hairstyle: BitHair.bun,
      hasGlasses: true,
      gender: 'female',
    ),
  };

  static BitmojiProfile get(String id, String gender) =>
      _db[id] ??
      BitmojiProfile(
        skinColor: const Color(0xFFD4A574),
        hairColor: const Color(0xFF303030),
        coatColor: const Color(0xFF1565C0),
        accentColor: Colors.blue,
        eyeColor: Colors.brown,
        blushColor: const Color(0xFFFFAB91),
        lipColor: const Color(0xFFAA5540),
        pantsColor: const Color(0xFF37474F),
        shoeColor: const Color(0xFF212121),
        earringColor: Colors.transparent,
        accessoryColor: Colors.grey,
        hairstyle: BitHair.shortSide,
        hasGlasses: false,
        gender: gender,
      );
}
