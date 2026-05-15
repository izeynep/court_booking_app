import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/screens/login_screen.dart';
import 'package:court_booking_app/screens/register_screen.dart';
import 'package:court_booking_app/screens/main_shell.dart';
import 'package:court_booking_app/screens/my_bookings_screen.dart';

class AppRouter {
  // ---------------------------
  // CORE NAV METHODS
  // ---------------------------

  static void goHomeTab([int index = 0]) {
    MainShell.tabs.switchTab(index);
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  static Future<T?> replace<T>(BuildContext context, Widget page) {
    return Navigator.of(
      context,
    ).pushReplacement<T, T>(MaterialPageRoute(builder: (_) => page));
  }

  static void back(BuildContext context, [Object? result]) {
    Navigator.of(context).pop(result);
  }

  static void clearAndPush(BuildContext context, Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  static bool _isLoggedIn() => FirebaseAuth.instance.currentUser != null;

  // ---------------------------
  // AUTH FLOW
  // ---------------------------

  static void goWelcome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static Future<void> goLogin(BuildContext context) {
    return push(context, const LoginScreen());
  }

  static Future<void> goRegister(BuildContext context) {
    return push(context, const RegisterScreen());
  }

  static void goHomeClear(BuildContext context) {
    MainShell.tabs.switchTab(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ---------------------------
  // GUARDED NAVIGATION
  // ---------------------------

  // ✅ Bu sayfa bottom-nav dışı → push normal
  static Future<void> goMyBookingsGuarded(BuildContext context) async {
    if (!_isLoggedIn()) {
      goWelcome(context);
      return;
    }
    await push(context, const MyBookingsScreen());
  }

  // ✅ TAB: Book (index 1) → push YOK
  static void goBookGuarded(BuildContext context) {
    if (!_isLoggedIn()) {
      goWelcome(context);
      return;
    }
    MainShell.tabs.switchTab(1);
  }

  // ✅ TAB: Profile (index 3) → push YOK
  static void goProfileGuarded(BuildContext context) {
    if (!_isLoggedIn()) {
      goWelcome(context);
      return;
    }
    MainShell.tabs.switchTab(3);
  }
}
