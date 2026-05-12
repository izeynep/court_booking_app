import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────

class CourtModel {
  final String id, name, surface;
  final int price;
  final bool isActive;

  const CourtModel({
    required this.id,
    required this.name,
    required this.surface,
    required this.price,
    required this.isActive,
  });

  factory CourtModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return CourtModel(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Kort',
      surface: (d['surface'] as String?) ?? 'hard',
      price: (d['price'] as num?)?.toInt() ?? 0,
      isActive: (d['isActive'] as bool?) ?? true,
    );
  }
}

class ClubStatus {
  final int activeCourtCount, presentCount, partnerSeekerCount;

  const ClubStatus({
    required this.activeCourtCount,
    required this.presentCount,
    required this.partnerSeekerCount,
  });

  factory ClubStatus.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ClubStatus(
      activeCourtCount: (d['activeCourtCount'] as num?)?.toInt() ?? 0,
      presentCount: (d['presentCount'] as num?)?.toInt() ?? 0,
      partnerSeekerCount: (d['partnerSeekerCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = ClubStatus(
    activeCourtCount: 0,
    presentCount: 0,
    partnerSeekerCount: 0,
  );
}

class MatchModel {
  final String id, p1Name, p2Name, score, courtName;
  final DateTime createdAt;
  final bool p1Won;

  const MatchModel({
    required this.id,
    required this.p1Name,
    required this.p2Name,
    required this.score,
    required this.courtName,
    required this.createdAt,
    required this.p1Won,
  });

  factory MatchModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final ts = d['createdAt'] as Timestamp?;
    return MatchModel(
      id: doc.id,
      p1Name: (d['p1Name'] as String?) ?? '',
      p2Name: (d['p2Name'] as String?) ?? '',
      score: (d['score'] as String?) ?? '',
      courtName: (d['courtName'] as String?) ?? '',
      createdAt: ts?.toDate() ?? DateTime.now(),
      p1Won: (d['p1Won'] as bool?) ?? true,
    );
  }

  String get agoLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}

class PartnerRequestModel {
  final String id, userName, initials, level, courtType, availableAt;
  final Color color;

  const PartnerRequestModel({
    required this.id,
    required this.userName,
    required this.initials,
    required this.level,
    required this.courtType,
    required this.availableAt,
    required this.color,
  });

  factory PartnerRequestModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final colorInt = (d['color'] as num?)?.toInt() ?? 0xFF2D6A4F;
    return PartnerRequestModel(
      id: doc.id,
      userName: (d['userName'] as String?) ?? '',
      initials: (d['initials'] as String?) ?? '??',
      level: (d['level'] as String?) ?? '',
      courtType: (d['courtType'] as String?) ?? '',
      availableAt: (d['availableAt'] as String?) ?? '',
      color: Color(colorInt),
    );
  }
}

// ── Phase 2 models ────────────────────────────────────────────────────────────

class AnnouncementModel {
  final String id, title, subtitle, tag, iconKey;
  final Color colorA, colorB;
  final int order;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.iconKey,
    required this.colorA,
    required this.colorB,
    required this.order,
  });

  factory AnnouncementModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    return AnnouncementModel(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      subtitle: (d['subtitle'] as String?) ?? '',
      tag: (d['tag'] as String?) ?? '',
      iconKey: (d['iconKey'] as String?) ?? 'star',
      colorA: Color((d['colorA'] as num?)?.toInt() ?? 0xFF1B4D38),
      colorB: Color((d['colorB'] as num?)?.toInt() ?? 0xFF2D6A4F),
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }

  IconData get icon => _iconMap[iconKey] ?? Icons.star_rounded;

  static const _iconMap = <String, IconData>{
    'trophy': Icons.emoji_events_rounded,
    'offer': Icons.local_offer_rounded,
    'twilight': Icons.wb_twilight_rounded,
    'star': Icons.star_rounded,
    'sports': Icons.sports_tennis_rounded,
  };
}

class CoachModel {
  final String id, initials, name, specialty, price, schedule, spots,
      lessonType;
  final Color color;

  const CoachModel({
    required this.id,
    required this.initials,
    required this.name,
    required this.specialty,
    required this.price,
    required this.schedule,
    required this.spots,
    required this.lessonType,
    required this.color,
  });

  factory CoachModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final colorInt = (d['color'] as num?)?.toInt() ?? 0xFF2D6A4F;
    return CoachModel(
      id: doc.id,
      initials: (d['initials'] as String?) ?? '',
      name: (d['name'] as String?) ?? '',
      specialty: (d['specialty'] as String?) ?? '',
      price: (d['price'] as String?) ?? '',
      schedule: (d['schedule'] as String?) ?? '',
      spots: (d['spots'] as String?) ?? '',
      lessonType: (d['lessonType'] as String?) ?? 'private',
      color: Color(colorInt),
    );
  }
}

class ClubPostModel {
  final String id, content, tag;
  final DateTime createdAt;
  final int likes;
  final Color tagColor;

  const ClubPostModel({
    required this.id,
    required this.content,
    required this.tag,
    required this.createdAt,
    required this.likes,
    required this.tagColor,
  });

  factory ClubPostModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final ts = d['createdAt'] as Timestamp?;
    final colorInt = (d['tagColor'] as num?)?.toInt() ?? 0xFF5B3F7A;
    return ClubPostModel(
      id: doc.id,
      content: (d['content'] as String?) ?? '',
      tag: (d['tag'] as String?) ?? '',
      createdAt: ts?.toDate() ?? DateTime.now(),
      likes: (d['likes'] as num?)?.toInt() ?? 0,
      tagColor: Color(colorInt),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    return '${diff.inDays} gün önce';
  }
}

class TournamentModel {
  final String id, name, date, format, prize;
  final int spotsLeft, totalSpots;
  final Color color;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.date,
    required this.format,
    required this.prize,
    required this.spotsLeft,
    required this.totalSpots,
    required this.color,
  });

  factory TournamentModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data();
    final colorInt = (d['color'] as num?)?.toInt() ?? 0xFF2D6A4F;
    return TournamentModel(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      date: (d['date'] as String?) ?? '',
      format: (d['format'] as String?) ?? '',
      prize: (d['prize'] as String?) ?? '',
      spotsLeft: (d['spotsLeft'] as num?)?.toInt() ?? 0,
      totalSpots: (d['totalSpots'] as num?)?.toInt() ?? 1,
      color: Color(colorInt),
    );
  }
}

// ─────────────────────────────────────────────
//  SERVICE
// ─────────────────────────────────────────────

class FirebaseService {
  FirebaseService._();
  static final _db = FirebaseFirestore.instance;

  // ── Courts ────────────────────────────────────────────────────────────────
  static Stream<List<CourtModel>> watchCourts() => _db
      .collection('courts')
      .snapshots()
      .map((s) => s.docs
          .map(CourtModel.fromDoc)
          .where((c) => c.isActive)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  // ── Club Status ───────────────────────────────────────────────────────────
  static Stream<ClubStatus> watchClubStatus() => _db
      .collection('club_status')
      .doc('current')
      .snapshots()
      .map((doc) => doc.exists ? ClubStatus.fromDoc(doc) : ClubStatus.empty);

  // ── Matches ───────────────────────────────────────────────────────────────
  static Stream<List<MatchModel>> watchRecentMatches({int limit = 5}) => _db
      .collection('matches')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(MatchModel.fromDoc).toList());

  // ── Partner Requests ──────────────────────────────────────────────────────
  static Stream<List<PartnerRequestModel>> watchPartnerRequests({
    int limit = 5,
  }) =>
      _db
          .collection('partner_requests')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(PartnerRequestModel.fromDoc).toList());

  // ── Announcements ─────────────────────────────────────────────────────────
  static Stream<List<AnnouncementModel>> watchAnnouncements({int limit = 5}) =>
      _db
          .collection('announcements')
          .orderBy('order')
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(AnnouncementModel.fromDoc).toList());

  // ── Coaches ───────────────────────────────────────────────────────────────
  static Stream<List<CoachModel>> watchCoaches() => _db
      .collection('coaches')
      .snapshots()
      .map((s) => s.docs.map(CoachModel.fromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  // ── Club Posts ────────────────────────────────────────────────────────────
  static Stream<List<ClubPostModel>> watchClubPosts({int limit = 10}) => _db
      .collection('club_posts')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ClubPostModel.fromDoc).toList());

  // ── Tournaments ───────────────────────────────────────────────────────────
  static Stream<List<TournamentModel>> watchTournaments() => _db
      .collection('tournaments')
      .snapshots()
      .map((s) => s.docs.map(TournamentModel.fromDoc).toList());

  // ─────────────────────────────────────────────
  //  SEED  (run once from admin portal)
  // ─────────────────────────────────────────────

  static Future<void> seedAll() async {
    await Future.wait([
      _seedCourts(),
      _seedClubStatus(),
      _seedMatches(),
      _seedPartnerRequests(),
      _seedAnnouncements(),
      _seedCoaches(),
      _seedClubPosts(),
      _seedTournaments(),
    ]);
  }

  static Future<void> _seedCourts() async {
    final check = await _db.collection('courts').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final data in [
      {'name': 'Kort 1', 'surface': 'clay', 'price': 500, 'isActive': true},
      {'name': 'Kort 2', 'surface': 'hard', 'price': 600, 'isActive': true},
      {'name': 'Kort 3', 'surface': 'hard', 'price': 450, 'isActive': true},
      {'name': 'Kort 4', 'surface': 'hard', 'price': 550, 'isActive': true},
      {'name': 'Kort 5', 'surface': 'padel', 'price': 700, 'isActive': true},
      {'name': 'Kort 6', 'surface': 'padel', 'price': 650, 'isActive': true},
    ]) {
      batch.set(_db.collection('courts').doc(), data);
    }
    await batch.commit();
  }

  static Future<void> _seedClubStatus() async {
    await _db.collection('club_status').doc('current').set(
      {'activeCourtCount': 3, 'presentCount': 5, 'partnerSeekerCount': 2},
      SetOptions(merge: true),
    );
  }

  static Future<void> _seedMatches() async {
    final check = await _db.collection('matches').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final now = DateTime.now();
    final batch = _db.batch();
    for (final data in [
      {
        'p1Name': 'Ece K.',
        'p2Name': 'Selin A.',
        'score': '6–3  7–5',
        'courtName': 'Kort 2',
        'p1Won': true,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 18)),
        ),
      },
      {
        'p1Name': 'Can Y.',
        'p2Name': 'Mert S.',
        'score': '4–6  6–4  10–7',
        'courtName': 'Kort 3',
        'p1Won': true,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 1)),
        ),
      },
    ]) {
      batch.set(_db.collection('matches').doc(), data);
    }
    await batch.commit();
  }

  static Future<void> _seedPartnerRequests() async {
    final check = await _db.collection('partner_requests').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final now = DateTime.now();
    final batch = _db.batch();
    for (final data in [
      {
        'userName': 'Rüya K.',
        'initials': 'RK',
        'level': 'Orta',
        'courtType': 'Hard',
        'availableAt': 'Bugün 16:00',
        'color': 0xFF2D6A4F,
        'createdAt': Timestamp.fromDate(now),
      },
      {
        'userName': 'Zeynep A.',
        'initials': 'ZA',
        'level': 'İleri',
        'courtType': 'Clay',
        'availableAt': 'Yarın 09:00',
        'color': 0xFFE07040,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 5)),
        ),
      },
    ]) {
      batch.set(_db.collection('partner_requests').doc(), data);
    }
    await batch.commit();
  }

  static Future<void> _seedAnnouncements() async {
    final check = await _db.collection('announcements').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final data in [
      {
        'title': 'Yaz Turnuvası 2025',
        'subtitle': "Kayıt başladı! 12 Temmuz'da başlıyor.",
        'tag': 'YENİ',
        'iconKey': 'trophy',
        'colorA': 0xFF1B4D38,
        'colorB': 0xFF2D6A4F,
        'order': 0,
      },
      {
        'title': 'Üye Özel İndirimi',
        'subtitle': 'Temmuz boyunca kort ücretlerinde %20 indirim.',
        'tag': 'İNDİRİM',
        'iconKey': 'offer',
        'colorA': 0xFF3A2460,
        'colorB': 0xFF5B3F7A,
        'order': 1,
      },
      {
        'title': 'Gece Tenisi Başlıyor',
        'subtitle': "Aydınlatmalı kortlarımız artık 23:00'a kadar açık.",
        'tag': 'DUYURU',
        'iconKey': 'twilight',
        'colorA': 0xFF9C4020,
        'colorB': 0xFFE07040,
        'order': 2,
      },
    ]) {
      batch.set(_db.collection('announcements').doc(), data);
    }
    await batch.commit();
  }

  static Future<void> _seedCoaches() async {
    final check = await _db.collection('coaches').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final data in [
      {
        'initials': 'MD',
        'name': 'Murat Demir',
        'specialty': 'Tenis Antrenörü',
        'price': '400₺ / saat',
        'schedule': 'P/Ç/C  09:00–12:00',
        'spots': '3 yer açık',
        'lessonType': 'private',
        'color': 0xFF2D6A4F,
      },
      {
        'initials': 'AK',
        'name': 'Ayşe Koç',
        'specialty': 'Padel Uzmanı',
        'price': '350₺ / saat',
        'schedule': 'Sal/Per  16:00–19:00',
        'spots': '1 yer açık',
        'lessonType': 'private',
        'color': 0xFF5B3F7A,
      },
      {
        'initials': 'LA',
        'name': 'Levent Arslan',
        'specialty': 'Grup Dersi • 6–8 kişi',
        'price': '150₺ / kişi',
        'schedule': 'Pzt  18:00',
        'spots': '2 yer açık',
        'lessonType': 'group',
        'color': 0xFF2B5BAD,
      },
      {
        'initials': 'DY',
        'name': 'Dilan Yıldız',
        'specialty': 'Kadın Grubu • 4–6 kişi',
        'price': '180₺ / kişi',
        'schedule': 'Çar  10:00',
        'spots': '4 yer açık',
        'lessonType': 'group',
        'color': 0xFFE07040,
      },
    ]) {
      batch.set(_db.collection('coaches').doc(), data);
    }
    await batch.commit();
  }

  static Future<void> _seedClubPosts() async {
    final check = await _db.collection('club_posts').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final now = DateTime.now();
    final batch = _db.batch();
    for (final data in [
      {
        'content':
            'Kortlarımızın bakımı Pazar günü 08:00–12:00 saatleri arasında yapılacaktır. Bu saatler arasında rezervasyon alınmayacaktır.',
        'tag': 'Duyuru',
        'tagColor': 0xFF5B3F7A,
        'likes': 12,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 2)),
        ),
      },
      {
        'content':
            'Bu ay 3 kez kort rezervasyonu yapanlara ücretsiz 1 saatlik kort hediye ediyoruz! 🎾',
        'tag': 'Kampanya',
        'tagColor': 0xFFE07040,
        'likes': 38,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'content':
            'Yeni dönem ders programımız açıklandı! Tüm seviyeler için bireysel ve grup dersleri mevcut.',
        'tag': 'Haber',
        'tagColor': 0xFF2D6A4F,
        'likes': 21,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
    ]) {
      batch.set(_db.collection('club_posts').doc(), data);
    }
    await batch.commit();
  }

  static Future<void> _seedTournaments() async {
    final check = await _db.collection('tournaments').limit(1).get();
    if (check.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final data in [
      {
        'name': 'KortSaha Yaz Kupası',
        'date': '14 Temmuz 2025',
        'format': 'Bireysel (K/E)',
        'prize': '3.000₺',
        'spotsLeft': 8,
        'totalSpots': 32,
        'color': 0xFF2D6A4F,
      },
      {
        'name': 'Padel Çiftler Turnuvası',
        'date': '28 Temmuz 2025',
        'format': 'Çiftler',
        'prize': '2.000₺',
        'spotsLeft': 3,
        'totalSpots': 16,
        'color': 0xFF5B3F7A,
      },
    ]) {
      batch.set(_db.collection('tournaments').doc(), data);
    }
    await batch.commit();
  }
}
