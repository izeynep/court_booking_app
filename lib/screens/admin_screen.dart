import 'package:flutter/material.dart';

import 'package:court_booking_app/data/firebase_service.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Portal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _SeedButton(),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(title: 'Total Bookings', value: '128'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(title: 'Active Courts', value: '8/10'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Text(
            'Court Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _CourtTile(name: 'Court 1 - Clay', isOpen: true),
          const SizedBox(height: 10),
          _CourtTile(name: 'Court 2 - Grass', isOpen: false),
        ],
      ),
    );
  }
}

class _SeedButton extends StatefulWidget {
  @override
  State<_SeedButton> createState() => _SeedButtonState();
}

class _SeedButtonState extends State<_SeedButton> {
  bool _loading = false;
  String? _message;

  Future<void> _seed() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await FirebaseService.seedAll();
      if (mounted) setState(() => _message = 'Seed tamamlandı ✅');
    } catch (e) {
      if (mounted) setState(() => _message = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _seed,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_rounded),
          label: Text(_loading ? 'Yükleniyor...' : 'Örnek Veriyi Yükle'),
        ),
      ),
      if (_message != null) ...[
        const SizedBox(height: 6),
        Text(
          _message!,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ],
  );
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CourtTile extends StatelessWidget {
  final String name;
  final bool isOpen;

  const _CourtTile({required this.name, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_tennis, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}
