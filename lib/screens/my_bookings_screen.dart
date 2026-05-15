import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/data/booking_repository.dart';
import 'package:court_booking_app/models/booking.dart';
import 'package:court_booking_app/navigation/app_router.dart';
import 'package:court_booking_app/ui/app_state_widgets.dart';

final _repo = BookingRepository();

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  static const _brandGreen = Color(0xFF0B6B3A);
  static const _bg = Color(0xFFF6F7F9);

  Stream<List<Booking>>? _stream;
  StreamSubscription<User?>? _authSub;

  Stream<List<Booking>> _withTimeout(Stream<List<Booking>> source) {
    return source.timeout(
      const Duration(seconds: 10),
      onTimeout: (sink) => sink.addError(
        TimeoutException('10 saniye içinde yanıt alınamadı'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _stream = _withTimeout(_repo.watchAll(uid));
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user != null && _stream == null) {
        setState(() {
          _stream = _withTimeout(_repo.watchAll(user.uid));
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  String _formatDateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy • $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) AppRouter.goWelcome(context);
      });
      return const Scaffold(
        backgroundColor: _bg,
        body: AppLoading(message: 'Yönlendiriliyor...'),
      );
    }

    if (_stream == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: AppLoading(message: 'Rezervasyonlar yükleniyor...'),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rezervasyonlarım',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _stream!,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Rezervasyonlar yükleniyor...');
          }
          if (snapshot.hasError) {
            final isTimeout = snapshot.error is TimeoutException;
            return AppError(
              message: isTimeout
                  ? 'Bağlantı zaman aşımına uğradı. Ağ bağlantınızı kontrol edin.'
                  : 'Bir hata oluştu. Lütfen tekrar dene.',
            );
          }

          final bookings = snapshot.data ?? [];
          final upcoming = bookings.where((b) => !b.isPast).toList();
          final past = bookings.where((b) => b.isPast).toList();

          if (upcoming.isEmpty && past.isEmpty) {
            return const AppEmpty(message: 'Henüz rezervasyonun yok');
          }

          return _BookingsList(
            upcoming: upcoming,
            past: past,
            formatDateTime: _formatDateTime,
          );
        },
      ),
    );
  }
}

// ── List with upcoming + optional past section ────────────────────────────────

class _BookingsList extends StatelessWidget {
  final List<Booking> upcoming;
  final List<Booking> past;
  final String Function(DateTime) formatDateTime;

  const _BookingsList({
    required this.upcoming,
    required this.past,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_ListItem>[
      if (upcoming.isNotEmpty) const _HeaderItem('Yaklaşan Rezervasyonlar'),
      for (final b in upcoming) _CardItem(b, canCancel: true),
      const _HeaderItem('Geçmiş Rezervasyonlar'),
      if (past.isEmpty) const _EmptyPastItem(),
      for (final b in past) _CardItem(b, canCancel: false),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];

        if (item is _HeaderItem) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 16, 0, 10),
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
            ),
          );
        }

        if (item is _EmptyPastItem) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 0, 10),
            child: Text(
              'Geçmiş rezervasyon yok',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          );
        }

        final cardItem = item as _CardItem;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _BookingCard(
            booking: cardItem.booking,
            canCancel: cardItem.canCancel,
            formatDateTime: formatDateTime,
          ),
        );
      },
    );
  }
}

// ── Internal item types ───────────────────────────────────────────────────────

abstract class _ListItem {
  const _ListItem();
}

class _CardItem extends _ListItem {
  final Booking booking;
  final bool canCancel;
  const _CardItem(this.booking, {required this.canCancel});
}

class _HeaderItem extends _ListItem {
  final String title;
  const _HeaderItem(this.title);
}

class _EmptyPastItem extends _ListItem {
  const _EmptyPastItem();
}

// ── Single booking card ───────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool canCancel;
  final String Function(DateTime) formatDateTime;

  const _BookingCard({
    required this.booking,
    required this.canCancel,
    required this.formatDateTime,
  });

  Future<bool> _confirmCancel(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Rezervasyonu iptal et?'),
        content: const Text('Bu işlem geri alınamaz. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Past cards use a muted background and 60%-opacity text; upcoming stay white.
    final cardBg = canCancel ? Colors.white : const Color(0xFFF8F8F8);
    final nameColor = canCancel
        ? const Color(0xFF141414)
        : const Color(0xFF141414).withValues(alpha: 0.6);
    final metaColor = canCancel
        ? Colors.grey.shade600
        : Colors.grey.shade600.withValues(alpha: 0.6);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: canCancel
                    ? const Color(0xFFE8F3EC)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.sports_tennis,
                color: canCancel
                    ? _MyBookingsScreenState._brandGreen
                    : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.courtName,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: nameColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDateTime(booking.startAt)} • ${booking.price}₺',
                    style: TextStyle(color: metaColor, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (canCancel)
              TextButton(
                onPressed: () async {
                  final ok = await _confirmCancel(context);
                  if (!ok) return;

                  try {
                    await _repo.cancelBooking(booking.id);
                    _repo.forceRefresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rezervasyon iptal edildi'),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('İptal başarısız. Tekrar dene.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'İptal',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBEBEB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Tamamlandı',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
