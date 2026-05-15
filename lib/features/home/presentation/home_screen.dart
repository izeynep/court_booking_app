import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/navigation/app_router.dart';
import 'package:court_booking_app/features/assistant/presentation/assistant_companion_card.dart';
import 'package:court_booking_app/features/assistant/presentation/assistant_chat_sheet.dart';
import 'package:court_booking_app/features/assistant/presentation/assistant_mascot.dart';
import 'package:court_booking_app/shared/widgets/primary_cta.dart';
import 'package:court_booking_app/features/home/widgets/next_booking_section.dart';
import 'package:court_booking_app/features/home/widgets/live_club_section.dart';
import 'package:court_booking_app/features/home/widgets/coming_up_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAssistantSheetOpen = false;

  void _openAssistant() {
    if (_isAssistantSheetOpen) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _isAssistantSheetOpen = true;

    _showAssistantSheet();
  }

  Future<void> _showAssistantSheet() async {
    if (!mounted) {
      _isAssistantSheetOpen = false;
      return;
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const AssistantChatSheet(),
      );
    } finally {
      if (mounted) {
        _isAssistantSheetOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'KortSaha',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF141414),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF141414),
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => AppRouter.goProfileGuarded(context),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE0F0E8),
                child: Icon(Icons.person, color: Color(0xFF2D6A4F), size: 18),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _MascotHeroSection(onTap: _openAssistant),
          const SizedBox(height: 20),

          if (uid == null)
            _LoginPrompt(onTap: () => AppRouter.goWelcome(context))
          else
            NextBookingSection(uid: uid),

          const SizedBox(height: 16),

          PrimaryCTA(
            text: 'Kort Ayır',
            onTap: () => AppRouter.goBookGuarded(context),
          ),

          const SizedBox(height: 28),
          const LiveClubSection(),

          const SizedBox(height: 28),
          const ComingUpSection(),
        ],
      ),
    );
  }
}

class _MascotHeroSection extends StatelessWidget {
  const _MascotHeroSection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AssistantMascot(
          size: const Size(120, 120),
          onTap: onTap,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AssistantCompanionCard(onChatTap: onTap),
        ),
      ],
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _LoginPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.login_rounded, color: Color(0xFF2D6A4F), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rezervasyonlarını görmek için giriş yapmalısın',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF606060),
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0xFFAAAAAA), size: 20),
        ],
      ),
    ),
  );
}
