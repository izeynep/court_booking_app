import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/navigation/app_router.dart';
import 'package:court_booking_app/ui/app_state_widgets.dart';

/// ===============================================================
/// MY BOOKINGS SCREEN (Rezervasyonlarım) - DOSYA HARİTASI
/// 1) Auth Guard (uid yoksa Welcome’a yönlendir)
/// 2) Firestore Stream (uid’ye göre bookings çek)
/// 3) Mapping (Firestore doc -> _BookingRow model)
/// 4) Split (Yaklaşan / Geçmiş ayrımı)
/// 5) Tab UI (Yaklaşan / Geçmiş)
/// 6) List UI + Cancel (sadece yaklaşanlarda iptal)
/// ===============================================================

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  /// UI sabit renkler
  static const _brandGreen = Color(0xFF0B6B3A);
  static const _bg = Color(0xFFF6F7F9);

  /// -------------------------------------------------------------
  /// 0) Yardımcı: DateTime'ı ekranda yazdırmak için format
  /// -------------------------------------------------------------
  String _formatDateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy • $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    /// -------------------------------------------------------------
    /// 1) AUTH GUARD
    /// uid yoksa (login değilse) bu sayfayı göstermiyoruz.
    /// Not: build içinde navigation direkt yapılmaz, post-frame ile yapıyoruz.
    /// -------------------------------------------------------------
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) AppRouter.goWelcome(context);
      });

      return const Scaffold(
        backgroundColor: _bg,
        body: AppLoading(message: 'Yönlendiriliyor...'),
      );
    }

    /// -------------------------------------------------------------
    /// 2) NORMAL UI (Login var)
    /// -------------------------------------------------------------
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Rezervasyonlarım',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      /// -------------------------------------------------------------
      /// 3) STREAM: Firestore’dan rezervasyonları canlı çek
      ///
      /// - collection('bookings')
      /// - where uid == current user
      /// - orderBy startAt (yaklaşanları sıralayabilmek için)
      /// - snapshots() => canlı stream
      /// -------------------------------------------------------------
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('uid', isEqualTo: uid)
            .orderBy('startAt')
            .snapshots(),
        builder: (context, snapshot) {
          /// 3A) Hata state
          if (snapshot.hasError) {
            return const AppError(
              message: 'Bir hata oluştu. Lütfen tekrar dene.',
            );
          }

          /// 3B) Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Rezervasyonlar yükleniyor...');
          }

          /// ---------------------------------------------------------
          /// 4) DATA: Firestore docs -> “bizim modelimize” çevir
          /// snapshot.data?.docs = doküman listesi
          /// ---------------------------------------------------------
          final docs = snapshot.data?.docs ?? [];
          final now = DateTime.now();

          /// 4A) Her doc’u _BookingRow’a map’liyoruz
          ///
          /// doc.data() Map<String, dynamic> gelir.
          /// - startAt Timestamp -> DateTime
          /// - price bazen int bazen num gelebilir -> int'e çeviriyoruz
          final items = docs
              .map((doc) {
                final data = doc.data();

                final ts = data['startAt'] as Timestamp?;
                final startAt = ts?.toDate();

                final priceRaw = data['price'];
                final price = priceRaw is int
                    ? priceRaw
                    : (priceRaw as num?)?.toInt();

                return _BookingRow(
                  docId: doc.id, // iptal için lazım
                  courtName: data['courtName'] as String?,
                  startAt: startAt,
                  price: price,
                );
              })
              /// 4B) startAt null olanları ele (güvenlik)
              .where((b) => b.startAt != null)
              .toList();

          /// ---------------------------------------------------------
          /// 5) Yaklaşan / Geçmiş ayırma
          ///
          /// - dt < now => past
          /// - dt >= now => upcoming
          /// ---------------------------------------------------------
          final upcoming = <_BookingRow>[];
          final past = <_BookingRow>[];

          for (final b in items) {
            final dt = b.startAt!;
            (dt.isBefore(now) ? past : upcoming).add(b);
          }

          /// 5A) Empty state (hiç rezervasyon yoksa)
          if (upcoming.isEmpty && past.isEmpty) {
            return const AppEmpty(message: 'Henüz rezervasyonun yok');
          }

          /// ---------------------------------------------------------
          /// 6) TAB UI
          /// Yaklaşan / Geçmiş diye iki sekme
          /// ---------------------------------------------------------
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const SizedBox(height: 8),

                /// Tab bar kapsülü
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    labelColor: _brandGreen,
                    unselectedLabelColor: Colors.grey,
                    indicator: BoxDecoration(
                      color: const Color(0xFFE8F3EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(text: 'Yaklaşan'),
                      Tab(text: 'Geçmiş'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                /// Tab içerikleri
                Expanded(
                  child: TabBarView(
                    children: [
                      /// Yaklaşan => iptal edilebilir
                      _BookingsList(
                        rows: upcoming,
                        formatDateTime: _formatDateTime,
                        canCancel: true,
                      ),

                      /// Geçmiş => iptal yok
                      _BookingsList(
                        rows: past,
                        formatDateTime: _formatDateTime,
                        canCancel: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ===============================================================
/// 7) BOOKINGS LIST (tek tab içeriği)
/// - rows: gösterilecek bookingler
/// - canCancel: iptal butonu görünsün mü?
/// - formatDateTime: dışarıdan gelen formatter (daha test edilebilir)
/// ===============================================================
class _BookingsList extends StatelessWidget {
  final List<_BookingRow> rows;
  final String Function(DateTime) formatDateTime;
  final bool canCancel;

  const _BookingsList({
    required this.rows,
    required this.formatDateTime,
    required this.canCancel,
  });

  /// 7A) İptal onayı dialog’u (geri alınamaz diye uyarı)
  Future<bool> _confirmCancel(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Rezervasyonu iptal et?'),
        content: const Text('Bu işlem geri alınamaz. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    /// Tab boş state
    if (rows.isEmpty) {
      return AppEmpty(
        message: canCancel
            ? 'Yaklaşan rezervasyon yok'
            : 'Geçmiş rezervasyon yok',
      );
    }

    /// 7B) Liste UI
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final b = rows[i];
        final dt = b.startAt!;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                /// sol ikon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sports_tennis,
                    color: MyBookingsScreen._brandGreen,
                  ),
                ),

                const SizedBox(width: 12),

                /// orta metin alanı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.courtName ?? 'Kort',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatDateTime(dt)}${b.price == null ? '' : ' • ${b.price}₺'}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                /// sağ iptal butonu (sadece yaklaşanlarda)
                if (canCancel)
                  TextButton(
                    onPressed: () async {
                      final ok = await _confirmCancel(context);
                      if (!ok) return;

                      /// Firestore’dan silme (cancel)
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(b.docId)
                          .delete();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rezervasyon iptal edildi'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// 8) Küçük ViewModel/Row class
/// Firestore doc’u UI’da taşımak için minimal model.
/// ===============================================================
class _BookingRow {
  final String docId; // Firestore doc id (silmek için)
  final String? courtName; // kort adı
  final DateTime? startAt; // rezervasyon başlangıcı
  final int? price; // ücret

  _BookingRow({required this.docId, this.courtName, this.startAt, this.price});
}
