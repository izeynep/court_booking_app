import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _tips = [
  'Düzenli antrenman fark yaratır — bu hafta bir ders ayırt!',
  'Kazanma alışkanlığı korttan başlar. Rezervasyonunu yap!',
  'İyi bir maç için doğru kort, doğru saat. Hadi başlayalım!',
  'Partner ara, bul, oyna. Kulübün seni bekliyor 🎾',
];

String _greeting() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Günaydın,';
  if (h >= 12 && h < 17) return 'İyi öğleden sonralar,';
  if (h >= 17 && h < 22) return 'İyi akşamlar,';
  return 'İyi geceler,';
}

String _firstName() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return '';
  final name = user.displayName;
  if (name != null && name.isNotEmpty) return name.trim().split(' ').first;
  return (user.email ?? '').split('@').first;
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final name = _firstName();
    final tip = _tips[DateTime.now().day % _tips.length];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF606060),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name.isNotEmpty ? '$name 👋' : 'Hoş geldin 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: Color(0xFF141414),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F0E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 14,
                      color: Color(0xFF2D6A4F),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _BouncingBall(),
      ],
    );
  }
}

// ─── Animated Mascot ─────────────────────────────────────────────────────────

class _BouncingBall extends StatefulWidget {
  const _BouncingBall();

  @override
  State<_BouncingBall> createState() => _BouncingBallState();
}

class _BouncingBallState extends State<_BouncingBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounce = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _bounce,
    builder: (_, __) => CustomPaint(
      size: const Size(64, 84),
      painter: _BallPainter(t: _bounce.value),
    ),
  );
}

class _BallPainter extends CustomPainter {
  final double t; // 0 = top of arc, 1 = floor
  const _BallPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const r = 20.0;
    final cy = 20.0 + t * 34.0;

    // shadow — grows and darkens as ball descends
    final sScale = 0.3 + t * 0.7;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 5),
        width: r * sScale * 2.2,
        height: r * sScale * 0.5,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.06 + t * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // slight vertical squash near floor
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(1.0, 1.0 - t * 0.08);
    canvas.translate(-cx, -cy);

    // ball body — tennis yellow-green radial gradient
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.38),
          radius: 0.88,
          colors: const [Color(0xFFEEF660), Color(0xFFCAD600)],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
        ),
    );

    // seam lines
    final seam = Paint()
      ..color = Colors.white.withOpacity(0.76)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(cx - r * 0.44, cy - r * 0.70)
        ..cubicTo(
          cx - r * 0.80, cy - r * 0.18,
          cx - r * 0.80, cy + r * 0.18,
          cx - r * 0.44, cy + r * 0.70,
        ),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + r * 0.44, cy - r * 0.70)
        ..cubicTo(
          cx + r * 0.80, cy - r * 0.18,
          cx + r * 0.80, cy + r * 0.18,
          cx + r * 0.44, cy + r * 0.70,
        ),
      seam,
    );

    // specular highlight
    canvas.drawCircle(
      Offset(cx - 6, cy - 7),
      4.0,
      Paint()..color = Colors.white.withOpacity(0.34),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BallPainter old) => old.t != t;
}
