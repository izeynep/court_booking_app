import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AssistantCompanionCard extends StatelessWidget {
  const AssistantCompanionCard({
    super.key,
    required this.onChatTap,
  });

  final VoidCallback onChatTap;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Günaydın';
    if (h >= 12 && h < 17) return 'İyi öğleden sonralar';
    if (h >= 17 && h < 22) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  String _firstName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final name = user.displayName;
    if (name != null && name.isNotEmpty) return name.trim().split(' ').first;
    return (user.email ?? '').split('@').first;
  }

  String _message() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return 'Giris yapinca kort ritmi ve etkinlikleri beraber takip ederiz.';
    }
    final h = DateTime.now().hour;
    if (h < 12) return 'Sabah enerjisi iyi! Erken saat kortlari hizli doluyor.';
    if (h < 18) return 'Kulup hareketleniyordur. Bos kort varmis mi bakalim!';
    return 'Aksam maci zamani! Uygun kort ve partner bulalim.';
  }

  String _bubbleText() {
    final greeting = _greeting();
    final name = _firstName();
    final msg = _message();
    if (name.isNotEmpty) return '$greeting, $name!\n$msg';
    return '$greeting!\n$msg';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChatTap,
      child: Semantics(
        button: true,
        label: 'Asistani ac',
        child: _SpeechBubble(text: _bubbleText()),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _SpeechBubblePainter(),
      child: Padding(
        // Left padding = triangle width (13) + inner gap (9)
        padding: const EdgeInsets.fromLTRB(22, 12, 14, 12),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A3828),
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter();

  static const _triW = 13.0;   // horizontal extent of triangle
  static const _triH = 16.0;   // vertical span of triangle base
  static const _triOffY = 30.0; // distance from top to triangle tip
  static const _r = 12.0;       // corner radius of bubble body

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Clockwise path: bubble body + left-pointing triangle
    final path = Path()
      ..moveTo(_triW + _r, 0)
      ..lineTo(w - _r, 0)
      ..quadraticBezierTo(w, 0, w, _r)
      ..lineTo(w, h - _r)
      ..quadraticBezierTo(w, h, w - _r, h)
      ..lineTo(_triW + _r, h)
      ..quadraticBezierTo(_triW, h, _triW, h - _r)
      ..lineTo(_triW, _triOffY + _triH / 2)
      ..lineTo(0, _triOffY)          // triangle tip pointing left
      ..lineTo(_triW, _triOffY - _triH / 2)
      ..lineTo(_triW, _r)
      ..quadraticBezierTo(_triW, 0, _triW + _r, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFF0FAF4));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCBE8D5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
