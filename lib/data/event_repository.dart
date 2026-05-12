import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:court_booking_app/models/event.dart';

class EventRepository {
  final FirebaseFirestore _db;

  EventRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Stream<List<EventModel>> watchPublishedEvents() {
    return _db
        .collection('events')
        .orderBy('startsAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(EventModel.fromDoc)
              .where((event) => event.isPublished)
              .toList(),
        );
  }

  Stream<List<EventModel>> watchUpcomingEvents({int limit = 6}) {
    return watchPublishedEvents().map((events) {
      final upcoming = events.where((event) => !event.isPast).toList();
      upcoming.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      return upcoming.take(limit).toList();
    });
  }
}
