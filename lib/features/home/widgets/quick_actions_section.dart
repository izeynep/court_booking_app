import 'package:flutter/material.dart';

import 'package:court_booking_app/core/theme/app_styles.dart';
import 'package:court_booking_app/navigation/app_router.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppStyles.spaceMd,
      crossAxisSpacing: AppStyles.spaceMd,
      childAspectRatio: 1.2,
      children: [
        _QuickActionCard(
          icon: Icons.event_note_rounded,
          label: 'Rezervasyonlarım',
          onTap: () => AppRouter.goMyBookingsGuarded(context),
        ),
        const _QuickActionCard(icon: Icons.school_rounded, label: 'Derslerim'),
        const _QuickActionCard(
          icon: Icons.emoji_events_rounded,
          label: 'Turnuvalar',
        ),
        _QuickActionCard(
          icon: Icons.person_rounded,
          label: 'Profil',
          onTap: () => AppRouter.goProfileGuarded(context),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionCard({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppStyles.white,
      borderRadius: BorderRadius.circular(AppStyles.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppStyles.radiusLg),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppStyles.softPurple,
                borderRadius: BorderRadius.circular(AppStyles.radiusMd),
              ),
              child: Icon(icon, color: AppStyles.navy),
            ),
            const SizedBox(height: AppStyles.spaceSm),
            Text(label, style: AppStyles.smallStrong),
          ],
        ),
      ),
    );
  }
}
