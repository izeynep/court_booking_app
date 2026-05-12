import 'package:flutter/material.dart';

import 'package:court_booking_app/data/firebase_service.dart';
import 'package:court_booking_app/navigation/app_router.dart';

class LiveClubSection extends StatelessWidget {
  const LiveClubSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClubStatus>(
      stream: FirebaseService.watchClubStatus(),
      builder: (context, snap) {
        final status = snap.data ?? ClubStatus.empty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => AppRouter.goHomeTab(2),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _PulseDot(),
                        const SizedBox(width: 7),
                        Text(
                          '${status.presentCount} kişi tesiste · '
                          '${status.activeCourtCount} kort aktif',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF141414),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Color(0xFF58C98D),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Canlı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 14),
                    _row(
                      Icons.local_fire_department_rounded,
                      'Akşam saatleri kalabalık',
                      const Color(0xFFE07040),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      Icons.person_search_rounded,
                      '${status.partnerSeekerCount} oyuncu partner arıyor',
                      const Color(0xFF5B3F7A),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      Icons.sports_tennis_rounded,
                      '${status.activeCourtCount} kort şu an aktif',
                      const Color(0xFF2D6A4F),
                    ),
                    const SizedBox(height: 10),
                    _row(
                      Icons.emoji_events_rounded,
                      'Yeni maç sonucu yayınlandı',
                      const Color(0xFF2B5BAD),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Haritayı gör →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _header() => const Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Club',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141414),
              ),
            ),
            Text(
              'Şu an tesiste neler oluyor',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _row(IconData icon, String text, Color color) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF141414),
          ),
        ),
      ),
    ],
  );
}

// ── Pulse dot ─────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          const Color(0xFF2D6A4F),
          const Color(0xFF68C98A),
          _c.value,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.35 + _c.value * 0.20),
            blurRadius: 7,
          ),
        ],
      ),
    ),
  );
}
