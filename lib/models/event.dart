import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? imageUrl;
  final bool isFeatured;
  final bool isPublished;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.startsAt,
    required this.endsAt,
    required this.imageUrl,
    required this.isFeatured,
    required this.isPublished,
  });

  factory EventModel.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final startTs = data['startsAt'] as Timestamp?;
    final endTs = data['endsAt'] as Timestamp?;

    return EventModel(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Etkinlik',
      description: (data['description'] as String?)?.trim() ?? '',
      location: (data['location'] as String?)?.trim().isNotEmpty == true
          ? (data['location'] as String).trim()
          : 'Kulup Tesisi',
      category: (data['category'] as String?)?.trim().isNotEmpty == true
          ? (data['category'] as String).trim()
          : 'Genel',
      startsAt: startTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: endTs?.toDate(),
      imageUrl: (data['imageUrl'] as String?)?.trim().isNotEmpty == true
          ? (data['imageUrl'] as String).trim()
          : null,
      isFeatured: (data['isFeatured'] as bool?) ?? false,
      isPublished: (data['isPublished'] as bool?) ?? true,
    );
  }

  bool get isPast {
    final eventEnd = endsAt ?? startsAt;
    return eventEnd.isBefore(DateTime.now());
  }

  String get dateLabel {
    final day = startsAt.day.toString().padLeft(2, '0');
    final month = startsAt.month.toString().padLeft(2, '0');
    final year = startsAt.year.toString();
    final hour = startsAt.hour.toString().padLeft(2, '0');
    final minute = startsAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }
}
