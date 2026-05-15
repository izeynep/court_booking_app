import 'package:flutter/material.dart';

import 'package:court_booking_app/data/booking_repository.dart';
import 'package:court_booking_app/models/booking.dart';
import 'package:court_booking_app/navigation/app_router.dart';
import 'package:court_booking_app/shared/widgets/info_pill.dart';

import 'next_booking_card.dart';
import 'package:court_booking_app/features/home/widgets/next_booking_carousel.dart';

final _bookingRepo = BookingRepository();

class NextBookingSection extends StatefulWidget {
  final String uid;
  const NextBookingSection({super.key, required this.uid});

  @override
  State<NextBookingSection> createState() => _NextBookingSectionState();
}

class _NextBookingSectionState extends State<NextBookingSection>
    with WidgetsBindingObserver {
  late Stream<List<Booking>> _stream;

  // Guards the first didChangeDependencies call (fires before StreamBuilder
  // subscribes, so forceRefresh would be a no-op and we'd double-fetch anyway).
  bool _initialized = false;
  // Tracks whether the home route was current on the last dependency change,
  // so we only refresh on the transition inactive→active (not on every build).
  bool _routeWasActive = false;

  @override
  void initState() {
    super.initState();
    _stream = _bookingRepo.watchUpcoming(widget.uid);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(NextBookingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _stream = _bookingRepo.watchUpcoming(widget.uid);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isActive = ModalRoute.of(context)?.isCurrent ?? false;

    if (!_initialized) {
      // Skip first call — stream handles the initial fetch via onListen.
      _initialized = true;
      _routeWasActive = isActive;
      return;
    }

    // Refresh only when transitioning from inactive → active (route revealed
    // after another screen is popped, e.g. returning from the booking screen).
    if (isActive && !_routeWasActive) {
      _bookingRepo.forceRefresh();
    }
    _routeWasActive = isActive;
  }

  // Refresh when the app returns to the foreground (e.g. user switched away
  // and came back while a booking was completing in the background).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bookingRepo.forceRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InfoPill(
            icon: Icons.hourglass_top_rounded,
            text: 'Rezervasyonlar yükleniyor...',
          );
        }

        if (snapshot.hasError) {
          return const InfoPill(
            icon: Icons.error_outline,
            text: 'Rezervasyonlar yüklenemedi',
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return InfoPill(
            icon: Icons.calendar_month_rounded,
            text: 'Sonraki rezervasyonun yok',
            onTap: () => AppRouter.goBookGuarded(context),
          );
        }

        if (bookings.length == 1) {
          return NextBookingCard(booking: bookings.first);
        }

        return NextBookingCarousel(bookings: bookings);
      },
    );
  }
}
