import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/booking.dart';

// ── JSON helper ───────────────────────────────────────────────────────────────
// Parses the backend response shape without touching the Booking model.

Booking _fromJson(Map<String, dynamic> j) => Booking(
      id: j['id'] as String,
      courtName: j['courtName'] as String,
      startAt: DateTime.parse(j['startAt'] as String),
      price: (j['price'] as num).toInt(),
    );

// ── Firebase implementation (kept for rollback) ───────────────────────────────

class FirebaseBookingRepository {
  final FirebaseFirestore _db;

  FirebaseBookingRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Booking>> watchForCourtDay({
    required String courtName,
    required DateTime day,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _db
        .collection('bookings')
        .where('courtName', isEqualTo: courtName)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('startAt')
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromDoc).toList());
  }

  Stream<List<Booking>> watchUpcoming(String uid, {int limit = 8}) {
    final now = Timestamp.fromDate(DateTime.now());

    return _db
        .collection('bookings')
        .where('uid', isEqualTo: uid)
        .where('startAt', isGreaterThanOrEqualTo: now)
        .orderBy('startAt')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Booking.fromDoc).toList());
  }

  Future<void> createBooking({
    required String uid,
    required String courtName,
    required int price,
    required DateTime startAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('NO_AUTH');

    await _db.collection('bookings').add({
      'uid': uid,
      'courtName': courtName,
      'price': price,
      'startAt': Timestamp.fromDate(startAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ── Backend implementation ────────────────────────────────────────────────────

class BackendBookingRepository {
  BackendBookingRepository({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _auth = auth; // null = use FirebaseAuth.instance lazily (safe for module-level init)

  final http.Client _client;
  final FirebaseAuth? _auth; // resolved in _token(), never at construction time

  // Broadcast to all active _periodicStream subscribers; triggers an immediate
  // tick and resets each stream's countdown so the next auto-poll is [interval]
  // from now rather than from whenever the last poll happened to fire.
  final _refreshController = StreamController<void>.broadcast();

  static const _base = 'http://10.0.2.2:3000/v1/bookings';

  Future<String> _token() async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) {
      print('[BookingRepo] _token: currentUser is null');
      throw Exception('User not authenticated');
    }
    print('[BookingRepo] _token: fetching ID token...');
    final token = await user.getIdToken().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw TimeoutException('Firebase ID token fetch timed out'),
    );
    if (token == null || token.isEmpty) {
      print('[BookingRepo] _token: token null or empty');
      throw Exception('User not authenticated');
    }
    print('[BookingRepo] _token: OK');
    return token;
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Create ────────────────────────────────────────────────────────────────

  Future<void> createBooking({
    required String uid, // kept for interface compatibility; backend uses token
    required String courtName,
    required int price,
    required DateTime startAt,
  }) async {
    final token = await _token();
    final response = await _client.post(
      Uri.parse(_base),
      headers: _authHeaders(token),
      body: jsonEncode({
        'courtName': courtName,
        'price': price,
        'startAt': startAt.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 409) throw Exception('SLOT_TAKEN');
    if (response.statusCode != 201) {
      throw Exception('Booking failed (${response.statusCode})');
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelBooking(String id) async {
    final token = await _token();
    final response = await _client.delete(
      Uri.parse('$_base/${Uri.encodeComponent(id)}'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 404) throw Exception('BOOKING_NOT_FOUND');
    if (response.statusCode == 403) throw Exception('BOOKING_NOT_OWNER');
    if (response.statusCode != 200) {
      throw Exception('Cancel failed (${response.statusCode})');
    }
  }

  // ── Upcoming stream ───────────────────────────────────────────────────────

  Stream<List<Booking>> watchUpcoming(String uid, {int limit = 8}) {
    return _periodicStream(
      const Duration(seconds: 5),
      () async {
        final token = await _token();
        print('[BookingRepo] watchUpcoming: GET $_base/my');
        final response = await _client
            .get(Uri.parse('$_base/my'), headers: _authHeaders(token))
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('GET /my timed out'),
            );
        print('[BookingRepo] watchUpcoming: status ${response.statusCode}');
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final list = jsonDecode(response.body) as List<dynamic>;
        // /my returns all confirmed bookings (past + upcoming) DESC.
        // Filter to upcoming only and sort nearest-first for the home widget.
        final now = DateTime.now();
        final bookings = list
            .map((j) => _fromJson(j as Map<String, dynamic>))
            .where((b) => !b.startAt.isBefore(now))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
        print('[BookingRepo] watchUpcoming: ${bookings.length} upcoming');
        return bookings;
      },
    );
  }

  // All confirmed bookings (upcoming + past), sorted by start_at DESC.
  // Use this for the full "my bookings" screen to avoid multiple-stream issues.
  Stream<List<Booking>> watchAll(String uid) {
    return _periodicStream(
      const Duration(seconds: 5),
      () async {
        final token = await _token();
        print('[BookingRepo] watchAll: GET $_base/my');
        final response = await _client
            .get(Uri.parse('$_base/my'), headers: _authHeaders(token))
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () => throw TimeoutException('GET /my timed out'),
            );
        print('[BookingRepo] watchAll: status ${response.statusCode}');
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final list = jsonDecode(response.body) as List<dynamic>;
        final bookings = list
            .map((j) => _fromJson(j as Map<String, dynamic>))
            .toList();
        print('[BookingRepo] watchAll: parsed ${bookings.length} bookings');
        return bookings;
      },
    );
  }

  // ── Court/day availability stream ─────────────────────────────────────────

  Stream<List<Booking>> watchForCourtDay({
    required String courtName,
    required DateTime day,
  }) {
    final dateStr = '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final encodedName = Uri.encodeComponent(courtName);

    return _periodicStream(
      const Duration(seconds: 5),
      () async {
        final token = await _token();
        final response = await _client.get(
          Uri.parse('$_base/court/$encodedName/day/$dateStr'),
          headers: _authHeaders(token),
        );
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((j) => _fromJson(j as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ── Force refresh ─────────────────────────────────────────────────────────
  // Call after any mutation (createBooking, cancelBooking) to make every
  // active stream fetch immediately and reset its countdown timer.

  void forceRefresh() {
    if (!_refreshController.isClosed) _refreshController.add(null);
  }

  // ── Periodic stream helper ────────────────────────────────────────────────
  // Fetches immediately on subscribe, then every [interval].
  // Errors are forwarded to the stream (so StreamBuilder can show them)
  // without terminating it — the next tick will retry automatically.
  // Responds to forceRefresh() by fetching immediately and resetting the timer.

  Stream<T> _periodicStream<T>(
    Duration interval,
    Future<T> Function() fetch,
  ) {
    late StreamController<T> controller;
    Timer? timer;
    StreamSubscription<void>? refreshSub;

    Future<void> tick() async {
      print('[BookingRepo] tick: starting fetch');
      try {
        final value = await fetch();
        print('[BookingRepo] tick: fetch succeeded');
        if (!controller.isClosed) controller.add(value);
      } catch (e, st) {
        print('[BookingRepo] tick: fetch error — $e');
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    void resetTimer() {
      timer?.cancel();
      timer = Timer.periodic(interval, (_) => tick());
    }

    controller = StreamController<T>(
      onListen: () {
        tick();
        timer = Timer.periodic(interval, (_) => tick());
        refreshSub = _refreshController.stream.listen((_) {
          resetTimer(); // restart countdown from now so next auto-poll isn't doubled up
          tick();
        });
      },
      onCancel: () {
        timer?.cancel();
        refreshSub?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  void close() {
    _refreshController.close();
    _client.close();
  }
}

// ── Active implementation — change this line to switch backends ───────────────

class BookingRepository extends BackendBookingRepository {
  BookingRepository() : super();
}
