import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'welcome_screen.dart';
import 'package:court_booking_app/features/home/presentation/home_screen.dart';
import 'courts_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'live_map_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  // ✅ private type yok: MainShellState
  static final GlobalKey<MainShellState> shellKey = GlobalKey<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

// ✅ underscore yok artık
class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    CourtsScreen(),
    LiveMapScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  void switchTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  bool _tabNeedsAuth(int index) => index == 1;

  void _handleTabTap(int index) {
    final user = FirebaseAuth.instance.currentUser;

    if (_tabNeedsAuth(index) && user == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
      return;
    }

    switchTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _handleTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green.shade800,
        unselectedItemColor: Colors.grey.shade500,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_rounded),
            label: 'Book',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_rounded),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
