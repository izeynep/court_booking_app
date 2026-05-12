import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../navigation/app_router.dart';
import 'admin_screen.dart';

// ─────────────────────────────────────────────
//  DATA MODEL + HELPERS
// ─────────────────────────────────────────────

class _ProfileData {
  final int streak;
  final int totalBookings;
  final String favoriteCourt;

  const _ProfileData({
    required this.streak,
    required this.totalBookings,
    required this.favoriteCourt,
  });
}

String _initials(User user) {
  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
  final email = user.email ?? '';
  return email.isNotEmpty ? email[0].toUpperCase() : '?';
}

String _memberSince(DateTime? dt) {
  if (dt == null) return '—';
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

Future<_ProfileData> _loadProfileData(String uid) async {
  final snap = await FirebaseFirestore.instance
      .collection('bookings')
      .where('uid', isEqualTo: uid)
      .get();

  final docs = snap.docs;

  // total bookings
  final total = docs.length;

  // favourite court — most frequently booked courtName
  final courtCounts = <String, int>{};
  for (final doc in docs) {
    final name = (doc.data()['courtName'] as String?) ?? 'Bilinmiyor';
    courtCounts[name] = (courtCounts[name] ?? 0) + 1;
  }
  final favCourt = courtCounts.isEmpty
      ? '—'
      : courtCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  // streak — consecutive days ending at today or yesterday
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final dates =
      docs
          .map((d) {
            final ts = d.data()['startAt'] as Timestamp;
            final dt = ts.toDate();
            return DateTime(dt.year, dt.month, dt.day);
          })
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  int streak = 0;
  if (dates.isNotEmpty) {
    final yesterday = today.subtract(const Duration(days: 1));
    DateTime? start;
    if (dates.contains(today)) {
      start = today;
    } else if (dates.contains(yesterday)) {
      start = yesterday;
    }
    if (start != null) {
      for (DateTime d = start; ; d = d.subtract(const Duration(days: 1))) {
        if (dates.contains(d)) {
          streak++;
        } else {
          break;
        }
      }
    }
  }

  return _ProfileData(
    streak: streak,
    totalBookings: total,
    favoriteCourt: favCourt,
  );
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfileData>? _dataFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) _dataFuture = _loadProfileData(uid);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) AppRouter.goWelcome(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Giriş yapılmamış')),
      );
    }

    final isAdmin = user.email == 'admin@gmail.com';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF141414),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 24),

            FutureBuilder<_ProfileData>(
              future: _dataFuture,
              builder: (ctx, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const _LoadingCards();
                }
                if (snap.hasError || !snap.hasData) {
                  return const _ErrorCard();
                }
                final data = snap.data!;
                return Column(
                  children: [
                    _StreakCard(streak: data.streak),
                    const SizedBox(height: 14),
                    _StatsRow(data: data),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            _MenuSection(isAdmin: isAdmin),
            const SizedBox(height: 20),
            _LogoutButton(onTap: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PROFILE HEADER
// ─────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
      children: [
        // avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF1B4D38), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A4F).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials(user),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          user.email ?? '',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF141414),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),

        // badge + member since
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F0E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 12,
                    color: Color(0xFF2D6A4F),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Aktif Üye',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D6A4F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Üye: ${_memberSince(user.metadata.creationTime)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  STREAK CARD
// ─────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFF1B4D38), Color(0xFF2D6A4F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.transparent : const Color(0xFFF0F0F0),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(0xFF2D6A4F).withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? '$streak Günlük Seri!' : 'Seri Yok',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: active ? Colors.white : const Color(0xFF141414),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active
                      ? 'Harika gidiyorsun, devam et!'
                      : 'Bugün bir maç ayarla, seriyi başlat!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active
                        ? Colors.white.withOpacity(0.80)
                        : const Color(0xFF606060),
                  ),
                ),
              ],
            ),
          ),
          if (active) ...[
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATS ROW
// ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final _ProfileData data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _StatCard(
          icon: Icons.event_available_rounded,
          color: const Color(0xFF2D6A4F),
          bgColor: const Color(0xFFE0F0E8),
          value: '${data.totalBookings}',
          label: 'Toplam Rez.',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          icon: Icons.sports_tennis_rounded,
          color: const Color(0xFF5B3F7A),
          bgColor: const Color(0xFFEDE8F4),
          value: data.favoriteCourt,
          label: 'Fav. Kort',
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFE07040),
          bgColor: const Color(0xFFFAEDE8),
          value: '0',
          label: 'Maç',
        ),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color, bgColor;
  final String value, label;
  const _StatCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 86,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF0F0F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const Spacer(),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFF141414),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFFAAAAAA),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────
//  MENU SECTION
// ─────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final bool isAdmin;
  const _MenuSection({required this.isAdmin});

  @override
  Widget build(BuildContext context) => Container(
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
      children: [
        _MenuItem(
          icon: Icons.calendar_month_rounded,
          label: 'Rezervasyonlarım',
          color: const Color(0xFF2D6A4F),
          bgColor: const Color(0xFFE0F0E8),
          isFirst: true,
          onTap: () => AppRouter.goMyBookingsGuarded(context),
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.notifications_rounded,
          label: 'Bildirimler',
          color: const Color(0xFF5B3F7A),
          bgColor: const Color(0xFFEDE8F4),
          onTap: () {},
        ),
        const _MenuDivider(),
        _MenuItem(
          icon: Icons.settings_rounded,
          label: 'Ayarlar',
          color: const Color(0xFF606060),
          bgColor: const Color(0xFFF0F0F0),
          isLast: !isAdmin,
          onTap: () {},
        ),
        if (isAdmin) ...[
          const _MenuDivider(),
          _MenuItem(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Portal',
            color: const Color(0xFFE07040),
            bgColor: const Color(0xFFFAEDE8),
            isLast: true,
            onTap: () => AppRouter.push(context, const AdminScreen()),
          ),
        ],
      ],
    ),
  );
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Divider(height: 1, color: Color(0xFFF0F0F0)),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final VoidCallback onTap;
  final bool isFirst, isLast;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 16 : 0),
      topRight: Radius.circular(isFirst ? 16 : 0),
      bottomLeft: Radius.circular(isLast ? 16 : 0),
      bottomRight: Radius.circular(isLast ? 16 : 0),
    );
    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141414),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFFAAAAAA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  LOGOUT BUTTON
// ─────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text(
        'Çıkış Yap',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD93025),
        side: const BorderSide(color: Color(0xFFD93025), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  LOADING / ERROR STATES
// ─────────────────────────────────────────────

class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 86,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF0F0F0)),
    ),
    child: const Row(
      children: [
        Icon(Icons.error_outline_rounded, color: Color(0xFFE07040), size: 18),
        SizedBox(width: 10),
        Text(
          'İstatistikler yüklenemedi',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF606060),
          ),
        ),
      ],
    ),
  );
}
