import 'package:flutter/material.dart';
import 'package:court_booking_app/core/theme/app_styles.dart';

class PrimaryCTA extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const PrimaryCTA({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
