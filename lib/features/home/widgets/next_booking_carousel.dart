import 'package:flutter/material.dart';

import 'package:court_booking_app/models/booking.dart';
import 'package:court_booking_app/shared/widgets/info_pill.dart';

import 'next_booking_card.dart';

class NextBookingCarousel extends StatefulWidget {
  final List<Booking> bookings;
  const NextBookingCarousel({super.key, required this.bookings});

  @override
  State<NextBookingCarousel> createState() => _NextBookingCarouselState();
}

class _NextBookingCarouselState extends State<NextBookingCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookings.isEmpty) {
      return const InfoPill(
        icon: Icons.calendar_month_rounded,
        text: 'Sonraki rezervasyonun yok',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 108,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.bookings.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: NextBookingCard(booking: widget.bookings[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.bookings.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: active ? 20 : 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
