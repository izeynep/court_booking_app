import 'dart:async';
import 'package:flutter/material.dart';

import 'package:court_booking_app/data/firebase_service.dart';
import 'package:court_booking_app/navigation/app_router.dart';

class ComingUpSection extends StatefulWidget {
  const ComingUpSection({super.key});

  @override
  State<ComingUpSection> createState() => _ComingUpSectionState();
}

class _ComingUpSectionState extends State<ComingUpSection> {
  List<CoachModel> _coaches = [];
  List<TournamentModel> _tournaments = [];
  StreamSubscription<List<CoachModel>>? _coachesSub;
  StreamSubscription<List<TournamentModel>>? _tournamentsSub;

  @override
  void initState() {
    super.initState();
    _coachesSub = FirebaseService.watchCoaches().listen((data) {
      if (mounted) setState(() => _coaches = data);
    });
    _tournamentsSub = FirebaseService.watchTournaments().listen((data) {
      if (mounted) setState(() => _tournaments = data);
    });
  }

  @override
  void dispose() {
    _coachesSub?.cancel();
    _tournamentsSub?.cancel();
    super.dispose();
  }

  CoachModel? get _nextGroupLesson =>
      _coaches.where((c) => c.lessonType == 'group').firstOrNull;

  CoachModel? get _nextPrivateCoach =>
      _coaches.where((c) => c.lessonType == 'private').firstOrNull;

  TournamentModel? get _nextTournament =>
      _tournaments.isNotEmpty ? _tournaments.first : null;

  @override
  Widget build(BuildContext context) {
    final groupLesson  = _nextGroupLesson;
    final privateCoach = _nextPrivateCoach;
    final tournament   = _nextTournament;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming Up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141414),
              ),
            ),
            Text(
              'Yaklaşan etkinlikler',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _ComingUpCard(
                title: groupLesson?.name ?? 'Grup Dersi',
                subtitle: groupLesson?.schedule ?? 'Yakında',
                icon: Icons.groups_rounded,
                color: const Color(0xFF2D6A4F),
                bgColor: const Color(0xFFE0F0E8),
                onTap: () => AppRouter.goHomeTab(2),
              ),
              const SizedBox(width: 12),
              _ComingUpCard(
                title: privateCoach?.name ?? 'Özel Ders',
                subtitle: privateCoach?.spots ?? 'Yakında',
                icon: Icons.school_rounded,
                color: const Color(0xFF5B3F7A),
                bgColor: const Color(0xFFEDE8F4),
                onTap: () => AppRouter.goHomeTab(2),
              ),
              const SizedBox(width: 12),
              _ComingUpCard(
                title: tournament?.name ?? 'Turnuva',
                subtitle: tournament?.date ?? 'Yakında',
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFE07040),
                bgColor: const Color(0xFFFAEDE8),
                onTap: () => AppRouter.goHomeTab(2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingUpCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color, bgColor;
  final VoidCallback onTap;

  const _ComingUpCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141414),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF606060),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
