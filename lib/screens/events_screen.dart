import 'package:flutter/material.dart';

import 'package:court_booking_app/data/event_repository.dart';
import 'package:court_booking_app/models/event.dart';
import 'package:court_booking_app/ui/app_state_widgets.dart';

final _eventRepository = EventRepository();

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Stream<List<EventModel>> _eventsStream;

  @override
  void initState() {
    super.initState();
    _reloadEvents();
  }

  void _reloadEvents() {
    _eventsStream = _eventRepository.watchPublishedEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _EventsHeader(),
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: _eventsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return AppError(
                      message: 'Etkinlikler su an yuklenemedi.',
                      onRetry: () => setState(_reloadEvents),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoading(
                      message: 'Etkinlikler yukleniyor...',
                    );
                  }

                  final liveEvents = snapshot.data ?? [];
                  final events = liveEvents.isEmpty
                      ? _demoEvents()
                      : liveEvents;
                  final featured = _featuredEvents(events);
                  final upcoming =
                      events.where((event) => !event.isPast).toList()
                        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
                  final past = events.where((event) => event.isPast).toList()
                    ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      if (featured.isNotEmpty) ...[
                        _FeaturedEventRail(events: featured),
                        const SizedBox(height: 28),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _EventSection(
                          title: 'Yaklasan Etkinlikler',
                          subtitle: liveEvents.isEmpty
                              ? 'Ornek etkinlik akisi'
                              : 'Kulup takvimindeki siradaki programlar',
                          events: upcoming,
                        ),
                      ],
                      if (upcoming.isNotEmpty && past.isNotEmpty)
                        const SizedBox(height: 28),
                      if (past.isNotEmpty)
                        _EventSection(
                          title: 'Gecmis Etkinlikler',
                          subtitle: 'Tamamlanan kulup programlari',
                          events: past,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EventModel> _featuredEvents(List<EventModel> events) {
    final featured = events.where((event) => event.isFeatured).toList();
    if (featured.isNotEmpty) {
      return featured.take(3).toList();
    }
    return events.where((event) => !event.isPast).take(3).toList();
  }

  List<EventModel> _demoEvents() {
    final now = DateTime.now();
    return [
      EventModel(
        id: 'demo-tournament',
        title: 'KortSaha Yaz Kupasi',
        description:
            'Eleme maclari, final gunu ve tesis ici odul toreni tek programda.',
        location: 'Merkez Kort',
        category: 'Turnuva',
        startsAt: DateTime(now.year, now.month, now.day + 6, 18, 30),
        endsAt: DateTime(now.year, now.month, now.day + 6, 22),
        imageUrl: null,
        isFeatured: true,
        isPublished: true,
      ),
      EventModel(
        id: 'demo-group',
        title: 'Hafta Sonu Grup Dersi',
        description:
            'Orta seviye oyuncular icin servis, ayak calismasi ve mini mac.',
        location: 'Hard Kort 2',
        category: 'Ders',
        startsAt: DateTime(now.year, now.month, now.day + 2, 10),
        endsAt: DateTime(now.year, now.month, now.day + 2, 12),
        imageUrl: null,
        isFeatured: false,
        isPublished: true,
      ),
      EventModel(
        id: 'demo-social',
        title: 'Kulup Sosyal Aksami',
        description:
            'Yeni uyelerle tanisma, acik eslesme listesi ve lounge bulusmasi.',
        location: 'Cafe & Lounge',
        category: 'Sosyal',
        startsAt: DateTime(now.year, now.month, now.day + 4, 19),
        endsAt: DateTime(now.year, now.month, now.day + 4, 21),
        imageUrl: null,
        isFeatured: true,
        isPublished: true,
      ),
      EventModel(
        id: 'demo-past',
        title: 'Padel Ciftler Gunu',
        description:
            'Tamamlanan ciftler bulusmasi ve gun sonu sonuc paylasimi.',
        location: 'Padel Kortlari',
        category: 'Turnuva',
        startsAt: DateTime(now.year, now.month, now.day - 5, 17),
        endsAt: DateTime(now.year, now.month, now.day - 5, 20),
        imageUrl: null,
        isFeatured: false,
        isPublished: true,
      ),
    ];
  }
}

class _EventsHeader extends StatelessWidget {
  const _EventsHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFE07040),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Etkinlikler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF141414),
                ),
              ),
              Text(
                'Turnuvalar, dersler ve kulup bulusmalari',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF606060),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeaturedEventRail extends StatelessWidget {
  final List<EventModel> events;

  const _FeaturedEventRail({required this.events});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'One Cikanlar',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF141414),
        ),
      ),
      const SizedBox(height: 2),
      const Text(
        'Kulup takviminden secilen programlar',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFAAAAAA),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 176,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (_, index) => _FeaturedEventCard(event: events[index]),
        ),
      ),
    ],
  );
}

class _FeaturedEventCard extends StatelessWidget {
  final EventModel event;

  const _FeaturedEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final palette = _EventPalette.fromCategory(event.category);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.deep, palette.base],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: palette.base.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.category,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  event.dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<EventModel> events;

  const _EventSection({
    required this.title,
    required this.subtitle,
    required this.events,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF141414),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFAAAAAA),
        ),
      ),
      const SizedBox(height: 12),
      for (final event in events) ...[
        _EventCard(event: event),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final palette = _EventPalette.fromCategory(event.category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: palette.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  event.category.toLowerCase().contains('ders')
                      ? Icons.school_rounded
                      : Icons.emoji_events_rounded,
                  color: palette.base,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF141414),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.base,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoTag(icon: Icons.schedule_rounded, label: event.dateLabel),
              _InfoTag(icon: Icons.place_rounded, label: event.location),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: Color(0xFF606060),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF606060)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF606060),
          ),
        ),
      ],
    ),
  );
}

class _EventPalette {
  final Color base;
  final Color deep;
  final Color soft;

  const _EventPalette({
    required this.base,
    required this.deep,
    required this.soft,
  });

  factory _EventPalette.fromCategory(String category) {
    final normalized = category.toLowerCase();

    if (normalized.contains('turnuva')) {
      return const _EventPalette(
        base: Color(0xFFE07040),
        deep: Color(0xFF9C4020),
        soft: Color(0xFFFAEDE8),
      );
    }

    if (normalized.contains('ders') || normalized.contains('antrenman')) {
      return const _EventPalette(
        base: Color(0xFF5B3F7A),
        deep: Color(0xFF3A2460),
        soft: Color(0xFFEDE8F4),
      );
    }

    return const _EventPalette(
      base: Color(0xFF2D6A4F),
      deep: Color(0xFF1B4D38),
      soft: Color(0xFFE0F0E8),
    );
  }
}
