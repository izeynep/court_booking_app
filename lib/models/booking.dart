import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String courtName;
  final DateTime startAt;
  final int price;

  Booking({
    required this.id,
    required this.courtName,
    required this.startAt,
    required this.price,
  });

  /// Firestore → Model (TEK YER)
  factory Booking.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final ts = data['startAt'] as Timestamp;

    final priceRaw = data['price'];
    final price = priceRaw is int ? priceRaw : (priceRaw as num?)?.toInt() ?? 0;

    return Booking(
      id: doc.id,
      courtName: (data['courtName'] as String?) ?? 'Kort',
      startAt: ts.toDate(),
      price: price,
    );
  }

  /// UI yardımcıları
  bool get isPast => startAt.isBefore(DateTime.now());

  String get formattedDate {
    final d = startAt;
    return '${d.day}/${d.month}/${d.year} • '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  String get priceLabel => '$price₺ / saat';
}
