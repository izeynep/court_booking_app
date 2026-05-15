import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AssistantMascot extends StatefulWidget {
  const AssistantMascot({
    super.key,
    this.onTap,
    this.size = const Size(120, 120),
  });

  final VoidCallback? onTap;
  final Size size;

  @override
  State<AssistantMascot> createState() => _AssistantMascotState();
}

class _AssistantMascotState extends State<AssistantMascot>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _blinkController;
  late final Animation<double> _bounce;
  late final Animation<double> _blink;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Hover at peak → easeIn fall → squash pause → easeOut rise
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 8),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 42,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 6),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 44,
      ),
    ]).animate(_bounceController);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _blink = Tween(begin: 0.0, end: 1.0).animate(_blinkController);

    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2500 + math.Random().nextInt(1500)),
      _runBlink,
    );
  }

  Future<void> _runBlink() async {
    if (!mounted) return;
    _blinkController.reset();
    await _blinkController.forward();
    if (!mounted) return;
    await _blinkController.reverse();
    if (!mounted) return;
    _scheduleBlink();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _bounceController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: 'KortSaha asistani',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounceController, _blinkController]),
          builder: (context, _) => CustomPaint(
            size: widget.size,
            painter: _BallPainter(t: _bounce.value, blinkT: _blink.value),
          ),
        ),
      ),
    );
  }
}

class _BallPainter extends CustomPainter {
  const _BallPainter({required this.t, required this.blinkT});

  // t: 0.0 = top of bounce, 1.0 = bottom (ground)
  final double t;
  // blinkT: 0.0 = eyes open, 1.0 = eyes fully closed
  final double blinkT;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 120, size.height / 120);
    final cx = size.width / 2;
    final r = 32.0 * scale;
    final cy = 36.0 * scale + t * 44.0 * scale;

    // Squash/stretch: activates near ground (bottom ~24% of travel)
    final squashFactor = Curves.easeIn.transform(
      ((t - 0.76) / 0.24).clamp(0.0, 1.0),
    );
    final scaleX = 1.0 + squashFactor * 0.18;
    final scaleY = 1.0 - squashFactor * 0.14;

    // Shadow grows and darkens as ball nears the ground
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 5 * scale),
        width: r * (0.7 + t * 0.65) * scaleX * 2,
        height: r * (0.20 + t * 0.12),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05 + t * 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Apply squash/stretch transform around ball center
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-cx, -cy);

    // Ball body
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.38),
          radius: 0.88,
          colors: const [Color(0xFFEEF660), Color(0xFFCAD600)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // Seams
    final seam = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1.8 * scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.44, cy - r * 0.70)
        ..cubicTo(
          cx - r * 0.80,
          cy - r * 0.18,
          cx - r * 0.80,
          cy + r * 0.18,
          cx - r * 0.44,
          cy + r * 0.70,
        ),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + r * 0.44, cy - r * 0.70)
        ..cubicTo(
          cx + r * 0.80,
          cy - r * 0.18,
          cx + r * 0.80,
          cy + r * 0.18,
          cx + r * 0.44,
          cy + r * 0.70,
        ),
      seam,
    );

    // Specular highlight (drawn before face so face sits on top)
    canvas.drawCircle(
      Offset(cx - r * 0.22, cy - r * 0.36),
      r * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.36),
    );

    // --- Face ---

    // Eyebrows: rise at bounce peak (t ≈ 0), settle at impact (t ≈ 1)
    final browLift = (1.0 - t) * 4.5 * scale;
    final browY = cy - r * 0.50 - browLift;
    final browPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = math.max(1.8 * scale, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.50, browY + 2.5 * scale)
        ..quadraticBezierTo(
          cx - r * 0.28,
          browY - 1.5 * scale,
          cx - r * 0.06,
          browY + 2.5 * scale,
        ),
      browPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + r * 0.06, browY + 2.5 * scale)
        ..quadraticBezierTo(
          cx + r * 0.28,
          browY - 1.5 * scale,
          cx + r * 0.50,
          browY + 2.5 * scale,
        ),
      browPaint,
    );

    // Eyes: close vertically when blinkT → 1
    final eyeY = cy - r * 0.15;
    final eyeRx = r * 0.12;
    final eyeRy = math.max(r * 0.14 * (1.0 - blinkT), 0.8 * scale);
    final eyePaint = Paint()..color = const Color(0xFF2A2A2A);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.28, eyeY),
        width: eyeRx * 2,
        height: eyeRy * 2,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + r * 0.28, eyeY),
        width: eyeRx * 2,
        height: eyeRy * 2,
      ),
      eyePaint,
    );

    // Smile
    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.34, cy + r * 0.14)
        ..quadraticBezierTo(cx, cy + r * 0.36, cx + r * 0.34, cy + r * 0.14),
      Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = math.max(1.8 * scale, 1.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) =>
      old.t != t || old.blinkT != blinkT;
}
