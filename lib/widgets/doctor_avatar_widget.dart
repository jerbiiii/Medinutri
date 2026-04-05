import 'package:flutter/material.dart';
import 'dart:math' as math;

class DoctorAvatarWidget extends StatefulWidget {
  final String doctorId;
  final String gender;
  final String avatarState; // idle | listening | thinking | speaking | waving
  final double size;

  const DoctorAvatarWidget({
    super.key,
    required this.doctorId,
    required this.gender,
    required this.avatarState,
    this.size = 300,
  });

  @override
  State<DoctorAvatarWidget> createState() => _DoctorAvatarWidgetState();
}

class _DoctorAvatarWidgetState extends State<DoctorAvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl; // Idle floating Y offset
  late AnimationController _breathCtrl; // Subtle body breath scale
  late AnimationController _blinkCtrl; // Eye blink
  late AnimationController _mouthCtrl; // Lip-sync speaking
  late AnimationController _waveCtrl; // Hand wave
  late AnimationController _headCtrl; // Head nod / tilt
  late AnimationController _thinkCtrl; // Thinking eye roll

  late Animation<double> _floatAnim;
  late Animation<double> _breathAnim;
  late Animation<double> _blinkAnim;
  late Animation<double> _mouthAnim;
  late Animation<double> _waveAnim;
  late Animation<double> _headAnim;
  late Animation<double> _thinkAnim;

  @override
  void initState() {
    super.initState();

    // Float: âˆ’8 â†’ +8 px, 3.8s
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    // Breath: scale 1.0 â†’ 1.018, 2.6s
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _breathAnim = CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut);

    // Blink: instant close/open
    _blinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _blinkAnim = CurvedAnimation(parent: _blinkCtrl, curve: Curves.easeInOut);

    // Mouth: opens & closes when speaking
    _mouthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _mouthAnim = CurvedAnimation(parent: _mouthCtrl, curve: Curves.easeInOut);

    // Wave arm rotation
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
    _waveAnim = CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut);

    // Head tilt for listening/nodding
    _headCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _headAnim = CurvedAnimation(parent: _headCtrl, curve: Curves.easeInOut);

    // Thinking: repeating eye-swivel
    _thinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _thinkAnim = CurvedAnimation(parent: _thinkCtrl, curve: Curves.easeInOut);

    _scheduleRandomBlink();
    _updateStateAnimations();
  }

  void _scheduleRandomBlink() async {
    while (mounted) {
      final delay = 2200 + math.Random().nextInt(2500);
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) break;
      await _blinkCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 90));
      if (mounted) await _blinkCtrl.reverse();
    }
  }

  @override
  void didUpdateWidget(DoctorAvatarWidget old) {
    super.didUpdateWidget(old);
    if (old.avatarState != widget.avatarState) {
      _updateStateAnimations();
    }
  }

  void _updateStateAnimations() {
    switch (widget.avatarState) {
      case 'speaking':
        _mouthCtrl.repeat(reverse: true);
        _waveCtrl.stop();
        _headCtrl.stop();
        break;
      case 'waving':
        _mouthCtrl.stop();
        _waveCtrl.repeat(reverse: true);
        _headCtrl.repeat(reverse: true);
        break;
      case 'listening':
        _mouthCtrl.stop();
        _mouthCtrl.value = 0;
        _waveCtrl.stop();
        _headCtrl.repeat(reverse: true);
        break;
      case 'thinking':
        _mouthCtrl.stop();
        _mouthCtrl.value = 0;
        _waveCtrl.stop();
        _headCtrl.stop();
        break;
      default: // idle
        _mouthCtrl.stop();
        _mouthCtrl.value = 0;
        _waveCtrl.stop();
        _waveCtrl.value = 0;
        _headCtrl.stop();
        _headCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _breathCtrl.dispose();
    _blinkCtrl.dispose();
    _mouthCtrl.dispose();
    _waveCtrl.dispose();
    _headCtrl.dispose();
    _thinkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = _DoctorAppearanceDB.get(widget.doctorId, widget.gender);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatAnim,
        _breathAnim,
        _blinkAnim,
        _mouthAnim,
        _waveAnim,
        _headAnim,
        _thinkAnim,
      ]),
      builder: (ctx, _) {
        final floatOffset = (_floatAnim.value - 0.5) * 16.0; // âˆ’8..+8 px
        final breathScale = 1.0 + _breathAnim.value * 0.018;

        // Head tilt angle
        double headTilt = 0;
        if (widget.avatarState == 'listening') {
          headTilt = (_headAnim.value - 0.5) * 0.12; // â‰ˆ Â±4Â°
        } else if (widget.avatarState == 'waving') {
          headTilt = math.sin(_headAnim.value * math.pi) * 0.06;
        }

        // Thinking: eyes look left-right slowly
        double eyeSwivel = 0;
        if (widget.avatarState == 'thinking') {
          eyeSwivel = (_thinkAnim.value - 0.5) * 5.0; // Â±2.5 px
        }

        // Mouth openness (speaking multi-harmonic)
        double mouthOpen = _mouthAnim.value;
        if (widget.avatarState == 'speaking') {
          final t = _mouthCtrl.value * 2 * math.pi;
          mouthOpen =
              (math.sin(t) * 0.55 +
                      math.sin(2.1 * t) * 0.28 +
                      math.sin(3.7 * t) * 0.17)
                  .abs()
                  .clamp(0.0, 1.0);
        }

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: breathScale,
            alignment: Alignment.bottomCenter,
            child: RepaintBoundary(
              child: SizedBox(
                width: widget.size,
                height: widget.size * 1.25,
                child: Stack(
                  children: [
                    // Ground shadow
                    Positioned(
                      bottom: 0,
                      left: widget.size * 0.15,
                      right: widget.size * 0.15,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Main avatar painter
                    CustomPaint(
                      size: Size(widget.size, widget.size * 1.2),
                      painter: _DoctorPainter3D(
                        appearance: appearance,
                        headTilt: headTilt,
                        eyeCloseVal: _blinkAnim.value,
                        mouthOpenVal: mouthOpen,
                        waveVal: _waveAnim.value,
                        eyeSwivelX: eyeSwivel,
                        currentState: widget.avatarState,
                        breathVal: _breathAnim.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

//  3D PAINTER

class _DoctorPainter3D extends CustomPainter {
  final _DoctorAppearance appearance;
  final double headTilt;
  final double eyeCloseVal;
  final double mouthOpenVal;
  final double waveVal;
  final double eyeSwivelX;
  final String currentState;
  final double breathVal;

  // Light direction: top-left, slightly toward viewer
  static const Alignment _kLight = Alignment(-0.38, -0.45);

  _DoctorPainter3D({
    required this.appearance,
    required this.headTilt,
    required this.eyeCloseVal,
    required this.mouthOpenVal,
    required this.waveVal,
    required this.eyeSwivelX,
    required this.currentState,
    required this.breathVal,
  });

  Paint _sphere(
    Color base,
    Rect bounds, {
    double lightStr = 0.5,
    double shadowStr = 0.38,
  }) {
    final hi = Color.lerp(base, Colors.white, lightStr)!;
    final sh = Color.lerp(base, const Color(0xFF0A0500), shadowStr)!;
    return Paint()
      ..shader = RadialGradient(
        center: _kLight,
        radius: 0.9,
        colors: [hi, base, sh],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(bounds);
  }

  void _specular(Canvas c, Offset center, double r, {double opacity = 0.55}) {
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  void _softShadow(Canvas c, Rect r, {double blur = 12, Color? color}) {
    c.drawOval(
      r,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
        ..color = color ?? Colors.black.withValues(alpha: 0.18),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final headR = size.width * 0.215;
    final headCY = size.height * 0.265;
    final headCenter = Offset(cx, headCY);

    canvas.save();
    canvas.translate(cx, headCY);
    canvas.rotate(headTilt);
    canvas.translate(-cx, -headCY);

    _drawBody(canvas, size, cx, headCY, headR);
    _drawNeck(canvas, cx, headCY, headR);
    _drawEars(canvas, cx, headCY, headR);
    _drawHead(canvas, cx, headCY, headR);
    _drawHair(canvas, cx, headCY, headR);
    _drawFace(canvas, headCenter, headR);
    if (appearance.hasBeard) _drawBeard(canvas, cx, headCY, headR);

    canvas.restore();

    // Arms drawn outside head transform
    _drawArms(canvas, size, cx, headCY, headR);
  }

  void _drawBody(
    Canvas canvas,
    Size size,
    double cx,
    double headCY,
    double headR,
  ) {
    final shoulderY = headCY + headR * 0.85;
    final bottomY = size.height * 0.98;
    final shoulderW = headR * 1.55;

    // Ambient occlusion under neck
    _softShadow(
      canvas,
      Rect.fromCenter(
        center: Offset(cx, shoulderY),
        width: headR * 1.0,
        height: headR * 0.3,
      ),
      blur: 10,
      color: Colors.black.withValues(alpha: 0.25),
    );

    // Coat body â€” trapezoidal
    final bodyRect = Rect.fromLTRB(
      cx - shoulderW,
      shoulderY,
      cx + shoulderW,
      bottomY,
    );
    final bodyPath = Path()
      ..moveTo(cx - shoulderW, shoulderY)
      ..lineTo(cx - shoulderW * 1.18, bottomY)
      ..lineTo(cx + shoulderW * 1.18, bottomY)
      ..lineTo(cx + shoulderW, shoulderY)
      ..close();

    canvas.drawPath(
      bodyPath,
      _sphere(appearance.coatColor, bodyRect, lightStr: 0.22, shadowStr: 0.28),
    );

    // Coat inner â€” shirt
    final collarPath = Path()
      ..moveTo(cx, shoulderY + 2)
      ..lineTo(cx - headR * 0.5, shoulderY + headR * 0.55)
      ..lineTo(cx - headR * 0.25, shoulderY + headR * 1.2)
      ..lineTo(cx + headR * 0.25, shoulderY + headR * 1.2)
      ..lineTo(cx + headR * 0.5, shoulderY + headR * 0.55)
      ..close();
    canvas.drawPath(
      collarPath,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Stethoscope
    final sp = Paint()
      ..color = appearance.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final stethPath = Path()
      ..moveTo(cx - headR * 0.25, shoulderY + headR * 0.35)
      ..cubicTo(
        cx - headR * 0.55,
        shoulderY + headR,
        cx + headR * 0.2,
        shoulderY + headR * 1.05,
        cx + headR * 0.05,
        shoulderY + headR * 1.42 + breathVal * 2,
      );
    canvas.drawPath(stethPath, sp);
    canvas.drawCircle(
      Offset(cx + headR * 0.05, shoulderY + headR * 1.42 + breathVal * 2),
      7,
      Paint()..color = appearance.accentColor,
    );
    // Stethoscope earpieces
    canvas.drawLine(
      Offset(cx - headR * 0.25, shoulderY + headR * 0.35),
      Offset(cx - headR * 0.5, shoulderY + headR * 0.15),
      sp,
    );
    canvas.drawLine(
      Offset(cx - headR * 0.5, shoulderY + headR * 0.15),
      Offset(cx - headR * 0.68, shoulderY + headR * 0.25),
      sp,
    );

    // Name badge
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + headR * 0.65, shoulderY + headR * 0.5),
        width: headR * 0.65,
        height: headR * 0.32,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = appearance.accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawNeck(Canvas canvas, double cx, double headCY, double headR) {
    final neckRect = Rect.fromCenter(
      center: Offset(cx, headCY + headR * 0.82),
      width: headR * 0.72,
      height: headR * 0.38,
    );
    canvas.drawOval(
      neckRect,
      _sphere(appearance.skinColor, neckRect, lightStr: 0.32, shadowStr: 0.22),
    );
  }

  void _drawEars(Canvas canvas, double cx, double headCY, double headR) {
    for (var side in [-1.0, 1.0]) {
      final ex = cx + side * headR * 0.97;
      final ey = headCY + headR * 0.1;
      final earRect = Rect.fromCenter(
        center: Offset(ex, ey),
        width: headR * 0.28,
        height: headR * 0.38,
      );
      canvas.drawOval(
        earRect,
        _sphere(appearance.skinColor, earRect, lightStr: 0.2, shadowStr: 0.3),
      );
      // Inner ear
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex + side * 1.5, ey),
          width: headR * 0.11,
          height: headR * 0.2,
        ),
        Paint()..color = Color.lerp(appearance.skinColor, Colors.black, 0.25)!,
      );
    }
  }

  void _drawHead(Canvas canvas, double cx, double headCY, double headR) {
    final headRect = Rect.fromCenter(
      center: Offset(cx, headCY),
      width: headR * 2.0,
      height: headR * 2.25,
    );

    // Subtle ambient occlusion rim (darker edge on shadow side)
    final rimPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = Colors.black.withValues(alpha: 0.2);
    canvas.drawOval(headRect.inflate(3), rimPaint);

    // The face oval â€” sphere-shaded
    canvas.drawOval(
      headRect,
      _sphere(appearance.skinColor, headRect, lightStr: 0.48, shadowStr: 0.32),
    );

    // Forehead specular highlight
    _specular(
      canvas,
      Offset(cx - headR * 0.15, headCY - headR * 0.58),
      headR * 0.22,
      opacity: 0.28,
    );
    // Nose tip specular
    _specular(
      canvas,
      Offset(cx, headCY + headR * 0.22),
      headR * 0.08,
      opacity: 0.22,
    );
    // Cheek highlights
    _specular(
      canvas,
      Offset(cx - headR * 0.4, headCY + headR * 0.15),
      headR * 0.14,
      opacity: 0.12,
    );
    _specular(
      canvas,
      Offset(cx + headR * 0.4, headCY + headR * 0.15),
      headR * 0.14,
      opacity: 0.12,
    );
  }

  void _drawHair(Canvas canvas, double cx, double headCY, double headR) {
    final hairLight = Color.lerp(appearance.hairColor, Colors.white, 0.28)!;
    final hairDark = Color.lerp(appearance.hairColor, Colors.black, 0.42)!;

    Paint hairGrad(Rect r) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [hairLight, appearance.hairColor, hairDark],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(r);

    switch (appearance.hairstyle) {
      case HairstyleType.short:
        final r = Rect.fromCenter(
          center: Offset(cx, headCY - headR * 0.32),
          width: headR * 2.12,
          height: headR * 1.5,
        );
        canvas.drawOval(r, hairGrad(r));
        // Side temples
        for (var s in [-1.0, 1.0]) {
          final tr = Rect.fromCenter(
            center: Offset(cx + s * headR * 0.92, headCY + headR * 0.05),
            width: headR * 0.45,
            height: headR * 0.55,
          );
          canvas.drawOval(tr, hairGrad(tr));
        }
        break;

      case HairstyleType.longWavy:
        final top = Rect.fromCenter(
          center: Offset(cx, headCY - headR * 0.18),
          width: headR * 2.18,
          height: headR * 1.55,
        );
        canvas.drawOval(top, hairGrad(top));
        // Long side waves
        for (var s in [-1.0, 1.0]) {
          final sidePath = Path();
          sidePath.moveTo(cx + s * headR * 0.98, headCY - headR * 0.1);
          sidePath.cubicTo(
            cx + s * headR * 1.48,
            headCY + headR * 0.4,
            cx + s * headR * 1.5,
            headCY + headR * 1.15,
            cx + s * headR * 1.15,
            headCY + headR * 1.9,
          );
          sidePath.cubicTo(
            cx + s * headR * 0.85,
            headCY + headR * 1.7,
            cx + s * headR * 0.88,
            headCY + headR * 1.2,
            cx + s * headR * 0.98,
            headCY - headR * 0.1,
          );
          canvas.drawPath(sidePath, Paint()..color = appearance.hairColor);
          // Wave strand highlight
          final wSrc = Rect.fromLTRB(
            cx + s * headR * 0.85,
            headCY - headR * 0.1,
            cx + s * headR * 1.5,
            headCY + headR * 1.9,
          );
          canvas.drawPath(
            sidePath,
            hairGrad(wSrc)..blendMode = BlendMode.srcATop,
          );
        }
        break;

      case HairstyleType.medium:
        final top = Rect.fromCenter(
          center: Offset(cx, headCY - headR * 0.22),
          width: headR * 2.14,
          height: headR * 1.52,
        );
        canvas.drawOval(top, hairGrad(top));
        for (var s in [-1.0, 1.0]) {
          final side = Rect.fromCenter(
            center: Offset(cx + s * headR * 0.96, headCY + headR * 0.2),
            width: headR * 0.55,
            height: headR * 0.8,
          );
          canvas.drawOval(side, hairGrad(side));
        }
        break;

      case HairstyleType.straight:
        final top = Rect.fromCenter(
          center: Offset(cx, headCY - headR * 0.2),
          width: headR * 2.18,
          height: headR * 1.5,
        );
        canvas.drawOval(top, hairGrad(top));
        for (var s in [-1.0, 1.0]) {
          final r = Rect.fromLTRB(
            cx + s * (headR * 0.88),
            headCY - headR * 0.05,
            cx + s * (headR * 1.14),
            headCY + headR * 1.48,
          );
          canvas.drawRect(r, hairGrad(r));
        }
        break;

      case HairstyleType.bald:
        final baldPaint = Paint()
          ..color = appearance.hairColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, headCY + headR * 0.35),
            width: headR * 2.1,
            height: headR * 1.9,
          ),
          math.pi * 0.68,
          math.pi * 1.64,
          false,
          baldPaint,
        );
        break;

      case HairstyleType.curly:
        for (int i = 0; i < 10; i++) {
          final a = (i / 10) * 2 * math.pi - math.pi / 2;
          final dx = math.cos(a) * headR * 0.82;
          final dy = math.sin(a) * headR * 0.7 - headR * 0.22;
          final pr = Rect.fromCenter(
            center: Offset(cx + dx, headCY + dy),
            width: headR * 0.58,
            height: headR * 0.58,
          );
          canvas.drawOval(pr, hairGrad(pr));
        }
        break;

      case HairstyleType.bun:
        final base = Rect.fromCenter(
          center: Offset(cx, headCY - headR * 0.2),
          width: headR * 2.18,
          height: headR * 1.5,
        );
        canvas.drawOval(base, hairGrad(base));
        // Bun top
        final bunRect = Rect.fromCenter(
          center: Offset(cx, headCY - headR * 0.98),
          width: headR * 0.72,
          height: headR * 0.72,
        );
        canvas.drawOval(bunRect, hairGrad(bunRect));
        // Bun highlight
        _specular(
          canvas,
          Offset(cx - headR * 0.06, headCY - headR * 1.08),
          headR * 0.12,
          opacity: 0.35,
        );
        break;
    }
  }

  // â”€â”€ FACE FEATURES â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawFace(Canvas canvas, Offset headCenter, double headR) {
    final cx = headCenter.dx;
    final cy = headCenter.dy;

    // â”€â”€ Eyebrows â”€â”€
    _drawEyebrows(canvas, cx, cy, headR);

    // â”€â”€ Eyes â”€â”€
    _drawEyes(canvas, cx, cy, headR);

    // â”€â”€ Nose â”€â”€
    _drawNose(canvas, cx, cy, headR);

    // â”€â”€ Mouth â”€â”€
    _drawMouth(canvas, cx, cy, headR);

    // â”€â”€ Subtle cheek blush for warmth â”€â”€
    final blushPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..color = appearance.skinColor
          .withRed((appearance.skinColor.red + 30).clamp(0, 255))
          .withValues(alpha: 0.28);
    canvas.drawCircle(
      Offset(cx - headR * 0.52, cy + headR * 0.2),
      headR * 0.28,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(cx + headR * 0.52, cy + headR * 0.2),
      headR * 0.28,
      blushPaint,
    );
  }

  void _drawEyebrows(Canvas canvas, double cx, double cy, double r) {
    final browPaint = Paint()
      ..color = appearance.hairColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.075
      ..strokeCap = StrokeCap.round;

    final eyeY = cy - r * 0.13;
    final liftL = currentState == 'thinking' ? r * 0.08 : 0.0;

    // Left brow (raised when thinking)
    final lbPath = Path()
      ..moveTo(cx - r * 0.54, eyeY - r * 0.38 - liftL)
      ..cubicTo(
        cx - r * 0.28,
        eyeY - r * 0.48 - liftL,
        cx - r * 0.04,
        eyeY - r * 0.44 - liftL,
        cx - r * 0.02,
        eyeY - r * 0.4 - liftL,
      );
    canvas.drawPath(lbPath, browPaint);

    // Right brow
    final rbPath = Path()
      ..moveTo(cx + r * 0.02, eyeY - r * 0.4)
      ..cubicTo(
        cx + r * 0.04,
        eyeY - r * 0.44,
        cx + r * 0.28,
        eyeY - r * 0.48,
        cx + r * 0.54,
        eyeY - r * 0.38,
      );
    canvas.drawPath(rbPath, browPaint);
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double r) {
    final eyeY = cy - r * 0.12;
    final lEyeX = cx - r * 0.32;
    final rEyeX = cx + r * 0.32;
    final eyeRx = r * 0.15;
    final eyeRy = r * 0.115;
    final svX = eyeSwivelX;

    for (var ex in [lEyeX, rEyeX]) {
      final center = Offset(ex + svX, eyeY);
      final scleraRect = Rect.fromCenter(
        center: center,
        width: eyeRx * 2.6,
        height: eyeRy * 2.5,
      );

      // Sclera with slight eye-socket shadow
      final scleraPaint = Paint()
        ..shader = RadialGradient(
          center: _kLight,
          radius: 1.0,
          colors: [Colors.white, const Color(0xFFF5F0EA)],
        ).createShader(scleraRect);
      canvas.drawOval(scleraRect, scleraPaint);

      // Iris 3D gradient
      final irisRect = Rect.fromCenter(
        center: center,
        width: eyeRx * 1.9,
        height: eyeRy * 1.9,
      );
      canvas.drawOval(
        irisRect,
        Paint()
          ..shader = RadialGradient(
            center: _kLight,
            radius: 0.85,
            colors: [
              Color.lerp(appearance.eyeColor, Colors.white, 0.45)!,
              appearance.eyeColor,
              Color.lerp(appearance.eyeColor, Colors.black, 0.5)!,
            ],
          ).createShader(irisRect),
      );

      // Pupil
      canvas.drawCircle(
        center,
        eyeRx * 0.62,
        Paint()..color = const Color(0xFF0D0D0D),
      );

      // Main specular highlight
      _specular(
        canvas,
        Offset(center.dx - eyeRx * 0.28, eyeY - eyeRy * 0.35),
        eyeRx * 0.28,
        opacity: 0.85,
      );
      // Secondary smaller highlight
      _specular(
        canvas,
        Offset(center.dx + eyeRx * 0.18, eyeY + eyeRy * 0.2),
        eyeRx * 0.12,
        opacity: 0.45,
      );

      // Sclera outline
      canvas.drawOval(
        scleraRect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Eyelid blink (top lid comes down)
      if (eyeCloseVal > 0.01) {
        final lidH = eyeRy * 2.5 * eyeCloseVal;
        canvas.drawRect(
          Rect.fromLTRB(
            center.dx - eyeRx * 1.3,
            center.dy - eyeRy * 1.25,
            center.dx + eyeRx * 1.3,
            center.dy - eyeRy * 1.25 + lidH,
          ),
          Paint()
            ..color = Color.lerp(appearance.skinColor, Colors.black, 0.08)!,
        );
      }

      // Upper lash line
      canvas.drawArc(
        Rect.fromCenter(
          center: center,
          width: eyeRx * 2.65,
          height: eyeRy * 2.5,
        ),
        -math.pi,
        math.pi,
        false,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawNose(Canvas canvas, double cx, double cy, double r) {
    final noseY = cy + r * 0.12;
    final nosePaint = Paint()
      ..color = Color.lerp(appearance.skinColor, Colors.black, 0.18)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Bridge
    final bridgePath = Path()
      ..moveTo(cx, cy - r * 0.06)
      ..cubicTo(
        cx - r * 0.06,
        noseY,
        cx - r * 0.08,
        noseY + r * 0.08,
        cx - r * 0.14,
        noseY + r * 0.14,
      );
    canvas.drawPath(bridgePath, nosePaint);

    // Nostrils
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - r * 0.14, noseY + r * 0.16),
        width: r * 0.22,
        height: r * 0.16,
      ),
      0,
      math.pi * 1.4,
      false,
      nosePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + r * 0.14, noseY + r * 0.16),
        width: r * 0.22,
        height: r * 0.16,
      ),
      math.pi * -0.4,
      math.pi * 1.4,
      false,
      nosePaint,
    );
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double r) {
    final mouthY = cy + r * 0.42;
    final openH = mouthOpenVal * r * 0.22;

    if (openH > 1.5) {
      // â”€â”€ Open mouth (speaking) â”€â”€
      final outerRect = Rect.fromCenter(
        center: Offset(cx, mouthY),
        width: r * 0.68,
        height: openH * 2.2,
      );

      // Inner mouth shadow
      canvas.drawOval(outerRect, Paint()..color = const Color(0xFF3A0A0A));

      // Teeth â€” upper
      canvas.drawRect(
        Rect.fromLTWH(
          cx - r * 0.28,
          mouthY - openH * 0.85,
          r * 0.56,
          openH * 0.9,
        ),
        Paint()..color = const Color(0xFFFFFAF5),
      );

      // Lips â€” upper
      final upperLipPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(appearance.skinColor, Colors.redAccent, 0.32)!,
                Color.lerp(appearance.skinColor, Colors.red, 0.22)!,
              ],
            ).createShader(
              Rect.fromLTWH(
                cx - r * 0.36,
                mouthY - openH - r * 0.06,
                r * 0.72,
                r * 0.12,
              ),
            );
      final ulPath = Path()
        ..moveTo(cx - r * 0.36, mouthY - openH)
        ..cubicTo(
          cx - r * 0.18,
          mouthY - openH - r * 0.1,
          cx + r * 0.18,
          mouthY - openH - r * 0.1,
          cx + r * 0.36,
          mouthY - openH,
        )
        ..cubicTo(
          cx + r * 0.38,
          mouthY - openH + r * 0.04,
          cx,
          mouthY - openH - r * 0.02,
          cx - r * 0.36,
          mouthY - openH,
        )
        ..close();
      canvas.drawPath(ulPath, upperLipPaint);

      // Lips â€” lower
      final lowerLipPaint = Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 0.8,
              colors: [
                Color.lerp(appearance.skinColor, Colors.pink, 0.35)!,
                Color.lerp(appearance.skinColor, Colors.redAccent, 0.22)!,
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset(cx, mouthY + openH),
                width: r * 0.72,
                height: r * 0.16,
              ),
            );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, mouthY + openH * 0.9),
          width: r * 0.66,
          height: r * 0.13 + openH * 0.15,
        ),
        lowerLipPaint,
      );

      // Lip highlight
      _specular(
        canvas,
        Offset(cx - r * 0.06, mouthY + openH * 0.9 - r * 0.02),
        r * 0.12,
        opacity: 0.22,
      );
    } else {
      // â”€â”€ Closed mouth â”€â”€
      final lipColor = Color.lerp(
        appearance.skinColor,
        appearance.gender == 'female' ? Colors.redAccent : Colors.blueGrey,
        0.25,
      )!;

      if (currentState == 'idle' || currentState == 'waving') {
        // Smile
        final smilePath = Path()
          ..moveTo(cx - r * 0.28, mouthY - r * 0.02)
          ..cubicTo(
            cx - r * 0.1,
            mouthY + r * 0.1,
            cx + r * 0.1,
            mouthY + r * 0.1,
            cx + r * 0.28,
            mouthY - r * 0.02,
          );
        canvas.drawPath(
          smilePath,
          Paint()
            ..color = lipColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        // Mouth corners dimples
        canvas.drawCircle(
          Offset(cx - r * 0.28, mouthY - r * 0.02),
          2.5,
          Paint()..color = lipColor.withValues(alpha: 0.5),
        );
        canvas.drawCircle(
          Offset(cx + r * 0.28, mouthY - r * 0.02),
          2.5,
          Paint()..color = lipColor.withValues(alpha: 0.5),
        );
      } else {
        // Neutral
        canvas.drawLine(
          Offset(cx - r * 0.24, mouthY),
          Offset(cx + r * 0.24, mouthY),
          Paint()
            ..color = lipColor
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  // â”€â”€ BEARD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawBeard(Canvas canvas, double cx, double cy, double r) {
    final beardPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          appearance.hairColor.withValues(alpha: 0.55),
          appearance.hairColor.withValues(alpha: 0.8),
          appearance.hairColor,
        ],
      ).createShader(Rect.fromLTWH(cx - r, cy + r * 0.5, r * 2, r * 0.72))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final beardPath = Path()
      ..moveTo(cx - r * 0.72, cy + r * 0.55)
      ..cubicTo(
        cx - r * 0.95,
        cy + r,
        cx - r * 0.5,
        cy + r * 1.22,
        cx,
        cy + r * 1.18,
      )
      ..cubicTo(
        cx + r * 0.5,
        cy + r * 1.22,
        cx + r * 0.95,
        cy + r,
        cx + r * 0.72,
        cy + r * 0.55,
      )
      ..cubicTo(
        cx + r * 0.45,
        cy + r * 0.6,
        cx - r * 0.45,
        cy + r * 0.6,
        cx - r * 0.72,
        cy + r * 0.55,
      )
      ..close();
    canvas.drawPath(beardPath, beardPaint);
  }

  // â”€â”€ ARMS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _drawArms(
    Canvas canvas,
    Size size,
    double cx,
    double headCY,
    double headR,
  ) {
    final shoulderY = headCY + headR * 0.85;
    final coatLt = Color.lerp(appearance.coatColor, Colors.white, 0.28)!;
    final coatDk = Color.lerp(appearance.coatColor, Colors.black, 0.28)!;

    Paint armPaint(bool isLeft) => Paint()
      ..shader = LinearGradient(
        begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        colors: [coatLt, appearance.coatColor, coatDk],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, shoulderY, size.width, headR * 1.8))
      ..strokeWidth = headR * 0.52
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final handPaint = Paint()
      ..shader = RadialGradient(
        center: _kLight,
        radius: 0.8,
        colors: [
          Color.lerp(appearance.skinColor, Colors.white, 0.4)!,
          appearance.skinColor,
          Color.lerp(appearance.skinColor, Colors.black, 0.25)!,
        ],
      ).createShader(Rect.fromLTWH(0, shoulderY, size.width, headR * 2));

    // Left arm (resting)
    final lShX = cx - headR * 1.35;
    final lHandX = lShX - headR * 0.18;
    final lHandY = shoulderY + headR * 1.65;
    canvas.drawLine(
      Offset(lShX, shoulderY),
      Offset(lHandX, lHandY),
      armPaint(true),
    );
    final lHandRect = Rect.fromCenter(
      center: Offset(lHandX, lHandY),
      width: headR * 0.42,
      height: headR * 0.42,
    );
    canvas.drawOval(lHandRect, handPaint);
    _specular(
      canvas,
      Offset(lHandX - headR * 0.06, lHandY - headR * 0.08),
      headR * 0.1,
      opacity: 0.35,
    );

    // Right arm â€” waving or resting
    final rShX = cx + headR * 1.35;

    if (currentState == 'waving') {
      // Smooth arc wave
      final armAngle = -math.pi * 0.88 + waveVal * math.pi * 0.45;
      final armLen = headR * 1.72;
      final elbowX = rShX + math.cos(-math.pi * 0.65) * armLen * 0.55;
      final elbowY = shoulderY + math.sin(-math.pi * 0.65) * armLen * 0.55;
      final handX = rShX + math.cos(armAngle) * armLen;
      final handY = shoulderY + math.sin(armAngle) * armLen;

      // Two-segment arm (elbow)
      final wavePath = Path()
        ..moveTo(rShX, shoulderY)
        ..lineTo(elbowX, elbowY)
        ..lineTo(handX, handY);
      canvas.drawPath(wavePath, armPaint(false));

      // Hand
      final hrect = Rect.fromCenter(
        center: Offset(handX, handY),
        width: headR * 0.44,
        height: headR * 0.44,
      );
      canvas.drawOval(hrect, handPaint);
      _specular(
        canvas,
        Offset(handX - headR * 0.06, handY - headR * 0.08),
        headR * 0.1,
        opacity: 0.38,
      );

      // Fingers
      final fPaint = Paint()
        ..color = appearance.skinColor
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 4; i++) {
        final fAngle = armAngle - math.pi * 0.3 + i * 0.22;
        canvas.drawLine(
          Offset(handX, handY),
          Offset(
            handX + math.cos(fAngle) * headR * 0.32,
            handY + math.sin(fAngle) * headR * 0.32,
          ),
          fPaint,
        );
      }
    } else {
      // Resting right arm
      final rHandX = rShX + headR * 0.18;
      final rHandY = shoulderY + headR * 1.65;
      canvas.drawLine(
        Offset(rShX, shoulderY),
        Offset(rHandX, rHandY),
        armPaint(false),
      );
      final rHandRect = Rect.fromCenter(
        center: Offset(rHandX, rHandY),
        width: headR * 0.42,
        height: headR * 0.42,
      );
      canvas.drawOval(rHandRect, handPaint);
      _specular(
        canvas,
        Offset(rHandX - headR * 0.06, rHandY - headR * 0.08),
        headR * 0.1,
        opacity: 0.35,
      );
    }
  }

  @override
  bool shouldRepaint(_DoctorPainter3D old) =>
      old.headTilt != headTilt ||
      old.eyeCloseVal != eyeCloseVal ||
      old.mouthOpenVal != mouthOpenVal ||
      old.waveVal != waveVal ||
      old.eyeSwivelX != eyeSwivelX ||
      old.currentState != currentState ||
      old.breathVal != breathVal;
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  APPEARANCE DATABASE â€” one unique look per doctor
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

enum HairstyleType { short, medium, longWavy, straight, bald, curly, bun }

class _DoctorAppearance {
  final Color skinColor;
  final Color hairColor;
  final Color coatColor;
  final Color accentColor;
  final HairstyleType hairstyle;
  final bool hasBeard;
  final Color eyeColor;
  final String gender;

  const _DoctorAppearance({
    required this.skinColor,
    required this.hairColor,
    required this.coatColor,
    required this.accentColor,
    required this.hairstyle,
    required this.hasBeard,
    required this.eyeColor,
    required this.gender,
  });
}

class _DoctorAppearanceDB {
  static const _db = <String, _DoctorAppearance>{
    '1': _DoctorAppearance(
      skinColor: Color(0xFFCB9065),
      hairColor: Color(0xFF191919),
      coatColor: Color(0xFF1565C0),
      accentColor: Color(0xFF42A5F5),
      hairstyle: HairstyleType.short,
      hasBeard: true,
      eyeColor: Color(0xFF4E342E),
      gender: 'male',
    ),
    '2': _DoctorAppearance(
      skinColor: Color(0xFFECC59F),
      hairColor: Color(0xFF4A2800),
      coatColor: Color(0xFFFFFFFF),
      accentColor: Color(0xFF66BB6A),
      hairstyle: HairstyleType.longWavy,
      hasBeard: false,
      eyeColor: Color(0xFF388E3C),
      gender: 'female',
    ),
    '3': _DoctorAppearance(
      skinColor: Color(0xFFF5D5B2),
      hairColor: Color(0xFF795548),
      coatColor: Color(0xFF00838F),
      accentColor: Color(0xFF4DD0E1),
      hairstyle: HairstyleType.medium,
      hasBeard: false,
      eyeColor: Color(0xFF0277BD),
      gender: 'male',
    ),
    '4': _DoctorAppearance(
      skinColor: Color(0xFFC18A5E),
      hairColor: Color(0xFF1C1C1C),
      coatColor: Color(0xFF4527A0),
      accentColor: Color(0xFF7C4DFF),
      hairstyle: HairstyleType.short,
      hasBeard: true,
      eyeColor: Color(0xFF6A1B9A),
      gender: 'male',
    ),
    '5': _DoctorAppearance(
      skinColor: Color(0xFFE8BC9A),
      hairColor: Color(0xFF050505),
      coatColor: Color(0xFFC2185B),
      accentColor: Color(0xFFF48FB1),
      hairstyle: HairstyleType.straight,
      hasBeard: false,
      eyeColor: Color(0xFF880E4F),
      gender: 'female',
    ),
    '6': _DoctorAppearance(
      skinColor: Color(0xFFF5C9A0),
      hairColor: Color(0xFF9E9E9E),
      coatColor: Color(0xFF00600F),
      accentColor: Color(0xFF00C853),
      hairstyle: HairstyleType.bald,
      hasBeard: true,
      eyeColor: Color(0xFF00695C),
      gender: 'male',
    ),
    '7': _DoctorAppearance(
      skinColor: Color(0xFFFADFC8),
      hairColor: Color(0xFFBF360C),
      coatColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFCA28),
      hairstyle: HairstyleType.curly,
      hasBeard: false,
      eyeColor: Color(0xFFBF360C),
      gender: 'female',
    ),
    '8': _DoctorAppearance(
      skinColor: Color(0xFFDAA888),
      hairColor: Color(0xFF151515),
      coatColor: Color(0xFF37474F),
      accentColor: Color(0xFF78909C),
      hairstyle: HairstyleType.bun,
      hasBeard: false,
      eyeColor: Color(0xFF263238),
      gender: 'female',
    ),
  };

  static _DoctorAppearance get(String id, String gender) {
    return _db[id] ??
        _DoctorAppearance(
          skinColor: const Color(0xFFD4A574),
          hairColor: const Color(0xFF333333),
          coatColor: const Color(0xFF1565C0),
          accentColor: Colors.blue,
          hairstyle: gender == 'male'
              ? HairstyleType.short
              : HairstyleType.longWavy,
          hasBeard: false,
          eyeColor: Colors.brown,
          gender: gender,
        );
  }
}
