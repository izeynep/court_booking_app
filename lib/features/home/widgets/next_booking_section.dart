import 'package:flutter/material.dart';

import 'package:court_booking_app/data/booking_repository.dart';
import 'package:court_booking_app/models/booking.dart';
import 'package:court_booking_app/navigation/app_router.dart';
import 'package:court_booking_app/shared/widgets/info_pill.dart';

import 'next_booking_card.dart';
import 'package:court_booking_app/features/home/widgets/next_booking_carousel.dart';

final _bookingRepo = BookingRepository();

class NextBookingSection extends StatelessWidget {
  final String uid;

  const NextBookingSection({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: _bookingRepo.watchUpcoming(uid),
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
