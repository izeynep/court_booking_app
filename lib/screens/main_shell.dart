import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/features/home/presentation/home_screen.dart';
import 'courts_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'live_map_screen.dart';

class MainShellTabs extends ChangeNotifier {
  int _requestedIndex = 0;

  int get requestedIndex => _requestedIndex;

  void switchTab(int index) {
    _requestedIndex = index;
    notifyListeners();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final tabs = MainShellTabs();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    CourtsScreen(),
    LiveMapScreen(),
    EventsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    MainShell.tabs.addListener(_handleExternalTabRequest);
  }

  @override
  void dispose() {
    MainShell.tabs.removeListener(_handleExternalTabRequest);
    super.dispose();
  }

  void _handleExternalTabRequest() {
    switchTab(MainShell.tabs.requestedIndex);
  }

  void switchTab(int index) {
    if (!mounted) return;
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  bool _tabNeedsAuth(int index) => index == 1;

  void _handleTabTap(int index) {
    final user = FirebaseAuth.instance.currentUser;

    if (_tabNeedsAuth(index) && user == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
