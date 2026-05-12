import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/navigation/app_router.dart';
import 'package:court_booking_app/data/booking_repository.dart';
import 'package:court_booking_app/data/firebase_service.dart';
import 'package:court_booking_app/models/booking.dart';

final _bookingRepo = BookingRepository();

class CourtsScreen extends StatefulWidget {
  const CourtsScreen({super.key});

  @override
  State<CourtsScreen> createState() => _CourtsScreenState();
}

class _CourtsScreenState extends State<CourtsScreen> {
  // ── Court selection state ───────────────────────────────────────────────────
  int selectedCourtIndex = 0;
  late DateTime selectedDate;
  String? selectedTime;

  // ── Courts from Firestore ───────────────────────────────────────────────────
  List<CourtModel> _courts = [];
  bool _courtsLoading = true;
  StreamSubscription<List<CourtModel>>? _courtsSub;

  // ── Availability stream ─────────────────────────────────────────────────────
  late Stream<List<Booking>> _availabilityStream;
  Timer? _loadingDelay;
  bool _showQueryLoading = false;

  DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── Slot builder ────────────────────────────────────────────────────────────
  List<String> _buildTimeSlots() {
    final slots = <String>[];
    for (int i = 9; i <= 22; i++) {
      slots.add('${i.toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  // ── Availability stream refresh ─────────────────────────────────────────────
  void _refreshAvailabilityStream() {
    if (_courts.isEmpty) return;
    final courtName = _courts[selectedCourtIndex].name;

    _availabilityStream = _bookingRepo.watchForCourtDay(
      courtName: courtName,
      day: selectedDate,
    );

    _loadingDelay?.cancel();
    _showQueryLoading = false;
    _loadingDelay = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _showQueryLoading = true);
    });
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    selectedDate = _onlyDate(DateTime.now());

    _courtsSub = FirebaseService.watchCourts().listen((courts) {
      if (!mounted) return;
      setState(() {
        _courts = courts;
        _courtsLoading = false;
        if (courts.isNotEmpty && selectedCourtIndex >= courts.length) {
          selectedCourtIndex = courts.length - 1;
        }
      });
      _refreshAvailabilityStream();
    });
  }

  @override
  void dispose() {
    _courtsSub?.cancel();
    _loadingDelay?.cancel();
    super.dispose();
  }

  // ── Selection handlers ──────────────────────────────────────────────────────
  void _selectCourt(int index) {
    setState(() {
      selectedCourtIndex = index;
      selectedTime = null;
    });
    _refreshAvailabilityStream();
  }

  void _selectDate(DateTime d) {
    setState(() {
      selectedDate = _onlyDate(d);
      selectedTime = null;
    });
    _refreshAvailabilityStream();
  }

  // ── Confirm dialog ──────────────────────────────────────────────────────────
  Future<bool> _showConfirmDialog({
    required String courtName,
    required int price,
    required DateTime date,
    required String time,
  }) async {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final startAt = DateTime(date.year, date.month, date.day, h, m);

    final dd = startAt.day.toString().padLeft(2, '0');
    final mm = startAt.month.toString().padLeft(2, '0');
    final yyyy = startAt.year.toString();
    final hh = startAt.hour.toString().padLeft(2, '0');
    final min = startAt.minute.toString().padLeft(2, '0');

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Rezervasyonu Onayla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kort: $courtName'),
            const SizedBox(height: 6),
            Text('Tarih/Saat: $dd/$mm/$yyyy • $hh:$min'),
            const SizedBox(height: 6),
            Text('Ücret: $price₺ / saat'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  // ── Create booking ──────────────────────────────────────────────────────────
  Future<bool> _createBooking({
    required String courtName,
    required int price,
    required DateTime date,
    required String time,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) AppRouter.goWelcome(context);
      return false;
    }

    final parts = time.split(':');
    if (parts.length != 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saat formatı hatalı')),
        );
      }
      return false;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saat formatı hatalı')),
        );
      }
      return false;
    }

    final startAt = DateTime(date.year, date.month, date.day, hour, minute);

    try {
      await _bookingRepo.createBooking(
        uid: user.uid,
        courtName: courtName,
        price: price,
        startAt: startAt,
      );

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervasyon kaydedildi ✅')),
      );
      setState(() => selectedTime = null);
      AppRouter.goHomeTab(0);
      return true;
    } catch (e) {
      final msg =
          e.toString().contains('SLOT_TAKEN') ? 'Bu saat dolu ❌' : 'Hata: $e';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return false;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppRouter.goWelcome(context);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (_courtsLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_courts.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Henüz aktif kort yok')),
      );
    }

    final selectedCourt = _courts[selectedCourtIndex];
    final times = _buildTimeSlots();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.sports_tennis),
        title: const Text('KortSaha'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Court picker ────────────────────────────────────────────────
            const Text(
              'Kort Seçimi',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _courts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final court = _courts[index];
                  final isSelected = index == selectedCourtIndex;

                  return GestureDetector(
                    onTap: () => _selectCourt(index),
                    child: Container(
                      width: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 10,
                            offset: Offset(0, 4),
                            color: Colors.black12,
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.image, size: 40),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    court.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Ücret: ${court.price}₺ / saat'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Date picker ─────────────────────────────────────────────────
            const Text(
              'Tarih Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 7) {
                    return ChoiceChip(
                      label: const Text('Takvim'),
                      selected: false,
                      onSelected: (_) async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: _onlyDate(DateTime.now()),
                          lastDate: _onlyDate(
                            DateTime.now().add(const Duration(days: 365)),
                          ),
                        );
                        if (picked != null) _selectDate(picked);
                      },
                    );
                  }

                  final d = _onlyDate(
                    DateTime.now().add(Duration(days: i)),
                  );
                  final isSelected =
                      d.year == selectedDate.year &&
                      d.month == selectedDate.month &&
                      d.day == selectedDate.day;

                  final label = i == 0
                      ? 'Bugün'
                      : i == 1
                      ? 'Yarın'
                      : '${d.day}/${d.month}';

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => _selectDate(d),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Time picker ─────────────────────────────────────────────────
            const Text(
              'Saat Seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_showQueryLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),

            StreamBuilder<List<Booking>>(
              stream: _availabilityStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active ||
                    snapshot.hasData) {
                  if (_showQueryLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _loadingDelay?.cancel();
                      setState(() => _showQueryLoading = false);
                    });
                  } else {
                    _loadingDelay?.cancel();
                  }
                }

                final bookedTimes = <String>{};
                if (snapshot.hasData) {
                  for (final b in snapshot.data!) {
                    final dt = b.startAt;
                    if (_onlyDate(dt) != selectedDate) continue;
                    final t =
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    bookedTimes.add(t);
                  }
                }

                if (selectedTime != null &&
                    bookedTimes.contains(selectedTime)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => selectedTime = null);
                  });
                }

                final now = DateTime.now();
                final isToday =
                    selectedDate.year == now.year &&
                    selectedDate.month == now.month &&
                    selectedDate.day == now.day;

                final showErrorText = snapshot.hasError && !snapshot.hasData;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showErrorText)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Saatler şu an okunamadı (yeniden dene).',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    _buildGrid(times, bookedTimes, isToday, now),
                  ],
                );
              },
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),

      // ── Bottom action bar ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, -4),
              color: Colors.black12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seçim: ${selectedCourt.name} • '
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} • '
              '${selectedTime ?? 'Saat seçilmedi'}',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedTime == null
                    ? null
                    : () async {
                        final ok = await _showConfirmDialog(
                          courtName: selectedCourt.name,
                          price: selectedCourt.price,
                          date: selectedDate,
                          time: selectedTime!,
                        );
                        if (!ok) return;
                        await _createBooking(
                          courtName: selectedCourt.name,
                          price: selectedCourt.price,
                          date: selectedDate,
                          time: selectedTime!,
                        );
                      },
                child: const Text('Rezervasyonu Tamamla'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Time slot grid ──────────────────────────────────────────────────────────
  Widget _buildGrid(
    List<String> times,
    Set<String> bookedTimes,
    bool isToday,
    DateTime now,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((t) {
        final isBooked = bookedTimes.contains(t);
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final slotDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          h,
          m,
        );
        final isPast = isToday && slotDateTime.isBefore(now);
        final isDisabled = isBooked || isPast;
        final isSelected = (selectedTime == t) && !isDisabled;

        return _TimeSlotChip(
          time: t,
          isBooked: isBooked,
          isPast: isPast,
          isSelected: isSelected,
          onTap: isDisabled ? null : () => setState(() => selectedTime = t),
        );
      }).toList(),
    );
  }
}

// ── Time slot chip ────────────────────────────────────────────────────────────

class _TimeSlotChip extends StatelessWidget {
  final String time;
  final bool isBooked, isPast, isSelected;
  final VoidCallback? onTap;

  const _TimeSlotChip({
    required this.time,
    required this.isBooked,
    required this.isPast,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = isBooked || isPast;
    final bg = isDisabled
        ? Colors.grey.shade200
        : (isSelected ? Colors.black : Colors.white);
    final fg = isDisabled
        ? Colors.grey.shade600
        : (isSelected ? Colors.white : Colors.black87);

    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                time,
                style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              ),
              if (isBooked)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DiagonalStrikePainter(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              if (isPast && !isBooked)
                Positioned(
                  bottom: 2,
                  child: Text(
                    'Geçti',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagonalStrikePainter extends CustomPainter {
  final Color color;
  const _DiagonalStrikePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(6, size.height - 6),
      Offset(size.width - 6, 6),
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagonalStrikePainter old) =>
      old.color != color;
}
