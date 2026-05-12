import 'package:flutter/material.dart';
import 'package:court_booking_app/core/theme/app_styles.dart';

class EmptyStateCard extends StatelessWidget {
  final String text;

  const EmptyStateCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppStyles.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
