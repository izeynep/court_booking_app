import 'dart:async';
import 'package:flutter/material.dart';

import 'package:court_booking_app/data/firebase_service.dart';

// ─────────────────────────────────────────────
//  PALETTE  (mirrors live_map_screen.dart)
// ─────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFFFFFFF);
  static const bgSoft     = Color(0xFFF8F8F8);
  static const card       = Color(0xFFFFFFFF);
  static const divider    = Color(0xFFF0F0F0);
  static const ink        = Color(0xFF141414);
  static const inkMid     = Color(0xFF606060);
  static const inkLight   = Color(0xFFAAAAAA);
  static const green      = Color(0xFF2D6A4F);
  static const greenSoft  = Color(0xFFE0F0E8);
  static const purple     = Color(0xFF5B3F7A);
  static const purpleSoft = Color(0xFFEDE8F4);
  static const orange     = Color(0xFFE07040);
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class ClubPulseScreen extends StatefulWidget {
  const ClubPulseScreen({super.key});

  @override
  State<ClubPulseScreen> createState() => _ClubPulseScreenState();
}

class _ClubPulseScreenState extends State<ClubPulseScreen> {
  late final PageController _heroCtrl;
  Timer? _heroTimer;
  int _heroPage = 0;
  int _lessonTab = 0; // 0=Tümü  1=Özel  2=Grup

  // Announcements stored in state so the auto-scroll timer can reference the count
  List<AnnouncementModel> _announcementsData = [];
  StreamSubscription<List<AnnouncementModel>>? _announcementsSub;

  // Stable stream references — created once so StreamBuilder doesn't re-subscribe
  late final Stream<List<AnnouncementModel>> _announcementsStream;
  late final Stream<List<CoachModel>>        _coachesStream;
  late final Stream<List<ClubPostModel>>     _postsStream;
  late final Stream<List<TournamentModel>>   _tournamentsStream;

  @override
  void initState() {
    super.initState();
    _heroCtrl = PageController();

    _announcementsStream = FirebaseService.watchAnnouncements();
    _coachesStream       = FirebaseService.watchCoaches();
    _postsStream         = FirebaseService.watchClubPosts();
    _tournamentsStream   = FirebaseService.watchTournaments();

    // Keep a local copy so the timer always knows the current item count
    _announcementsSub = _announcementsStream.listen((data) {
      if (!mounted) return;
      setState(() => _announcementsData = data);
    });

    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _announcementsData.isEmpty) return;
      final next = (_heroPage + 1) % _announcementsData.length;
      _heroCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _heroTimer?.cancel();
    _announcementsSub?.cancel();
    super.dispose();
  }

  List<CoachModel> _filteredCoaches(List<CoachModel> all) {
    if (_lessonTab == 1) return all.where((c) => c.lessonType == 'private').toList();
    if (_lessonTab == 2) return all.where((c) => c.lessonType == 'group').toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _heroSlider(),
                    const SizedBox(height: 28),
                    _lessonsSection(),
                    const SizedBox(height: 28),
                    _feedSection(),
                    _tournamentsStreamSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.bgSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.star_rounded, color: _C.green, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kulüp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                  color: _C.ink,
                ),
              ),
              Text(
                'Dersler · Duyurular · Turnuvalar',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.inkMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Hero slider ───────────────────────────────────────────────────────────────
  // Uses _announcementsData (state field fed by subscription) rather than a nested
  // StreamBuilder so the auto-scroll timer always sees the current item count.
  Widget _heroSlider() {
    if (_announcementsData.isEmpty) {
      // Reserve space while loading to prevent layout jump
      return const SizedBox(height: 176);
    }
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _heroCtrl,
            onPageChanged: (i) => setState(() => _heroPage = i),
            itemCount: _announcementsData.length,
            itemBuilder: (_, i) => _HeroCard(a: _announcementsData[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _announcementsData.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _heroPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _heroPage == i ? _C.ink : _C.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Lessons section ───────────────────────────────────────────────────────────
  Widget _lessonsSection() {
    final tabs = ['Tümü', 'Özel', 'Grup'];
    return StreamBuilder<List<CoachModel>>(
      stream: _coachesStream,
      builder: (ctx, snap) {
        final coaches = _filteredCoaches(snap.data ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                title: 'Dersler',
                subtitle: 'Antrenörlerimizle gelişin',
                action: 'Tümü',
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final on = _lessonTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _lessonTab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: on ? _C.ink : _C.bgSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : _C.inkMid,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            if (coaches.isEmpty)
              const SizedBox(height: 192)
            else
              SizedBox(
                height: 192,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: coaches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _CoachCard(coach: coaches[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Club feed ─────────────────────────────────────────────────────────────────
  Widget _feedSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _SectionHeader(
          title: 'Kulüp Duvarı',
          subtitle: 'Yönetim duyuruları',
          action: 'Tümü',
        ),
      ),
      const SizedBox(height: 10),
      StreamBuilder<List<ClubPostModel>>(
        stream: _postsStream,
        builder: (ctx, snap) {
          final posts = snap.data ?? [];
          if (posts.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: posts.map((p) => _PostCard(post: p)).toList(),
            ),
          );
        },
      ),
    ],
  );

  // ── Tournaments (conditional) ─────────────────────────────────────────────────
  Widget _tournamentsStreamSection() => StreamBuilder<List<TournamentModel>>(
    stream: _tournamentsStream,
    builder: (ctx, snap) {
      final tournaments = snap.data ?? [];
      if (tournaments.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          const SizedBox(height: 28),
          _tournamentsSection(tournaments),
        ],
      );
    },
  );

  Widget _tournamentsSection(List<TournamentModel> tournaments) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _SectionHeader(
          title: 'Turnuvalar',
          subtitle: 'Kayıt ol, yarış, kazan',
          action: 'Geçmiş',
        ),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: tournaments.map((t) => _TournamentCard(t: t)).toList(),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final AnnouncementModel a;
  const _HeroCard({required this.a});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [a.colorA, a.colorB],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: a.colorB.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    a.tag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  a.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.80),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(a.icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    ),
  );
}

class _CoachCard extends StatelessWidget {
  final CoachModel coach;
  const _CoachCard({required this.coach});

  @override
  Widget build(BuildContext context) {
    final isPrivate = coach.lessonType == 'private';
    return Container(
      width: 168,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: coach.color.withOpacity(0.12),
                child: Text(
                  coach.initials,
                  style: TextStyle(
                    color: coach.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPrivate ? _C.greenSoft : _C.purpleSoft,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  isPrivate ? 'Özel' : 'Grup',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPrivate ? _C.green : _C.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            coach.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            coach.specialty,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _C.inkLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            coach.price,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: coach.color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            coach.schedule,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: _C.inkMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: coach.color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: coach.color.withOpacity(0.20),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Kayıt Ol',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ClubPostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.divider),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _C.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KortSaha',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _C.ink,
                    ),
                  ),
                  Text(
                    'Yönetim',
                    style: TextStyle(
                      fontSize: 10,
                      color: _C.inkLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _Tag(label: post.tag, color: post.tagColor),
            const SizedBox(width: 8),
            Text(
              post.timeAgo,
              style: const TextStyle(
                fontSize: 10,
                color: _C.inkLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          post.content,
          style: const TextStyle(
            fontSize: 13,
            color: _C.inkMid,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 14,
              color: _C.inkLight,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.likes}',
              style: const TextStyle(
                fontSize: 11,
                color: _C.inkLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TournamentCard extends StatelessWidget {
  final TournamentModel t;
  const _TournamentCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final fillPct = (t.totalSpots - t.spotsLeft) / t.totalSpots;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.lerp(t.color, Colors.black, 0.22)!, t.color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.format,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: t.date,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.monetization_on_rounded,
                      label: t.prize,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.totalSpots - t.spotsLeft}/${t.totalSpots} kayıt',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _C.inkMid,
                            ),
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fillPct,
                              minHeight: 5,
                              backgroundColor: _C.divider,
                              valueColor: AlwaysStoppedAnimation(t.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: t.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: t.color.withOpacity(0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Katıl',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL SHARED WIDGETS
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, subtitle, action;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.ink,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: _C.inkLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      Text(
        action,
        style: const TextStyle(
          fontSize: 12,
          color: _C.purple,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: _C.inkMid),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _C.inkMid,
        ),
      ),
    ],
  );
}
