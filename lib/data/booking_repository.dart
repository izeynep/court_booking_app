import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';

class BookingRepository {
  final FirebaseFirestore _db;

  BookingRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  // ✅ Kort + Gün doluluk (CourtsScreen bunu kullanıyor)
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

  // ✅ Home HERO (yaklaşan rezervasyonlar)
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

  // ✅ Rez oluşturma
  Future<void> createBooking({
    required String uid,
    required String courtName,
    required int price,
    required DateTime startAt,
  }) async {
    // (opsiyonel) login yoksa patlamasın diye:
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
