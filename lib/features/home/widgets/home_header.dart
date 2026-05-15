import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/features/assistant/presentation/assistant_mascot.dart';

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
  const HomeHeader({
    super.key,
    this.onMascotTap,
  });

  final VoidCallback? onMascotTap;

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
        AssistantMascot(
          onTap: onMascotTap,
        ),
      ],
    );
  }
}
