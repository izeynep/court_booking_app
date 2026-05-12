import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:court_booking_app/data/firebase_service.dart';

// ─────────────────────────────────────────────
//  PALETTE
// ─────────────────────────────────────────────
class _C {
  // Backgrounds
  static const bg = Color(0xFFFFFFFF);
  static const bgSoft = Color(0xFFF8F8F8);
  static const card = Color(0xFFFFFFFF);
  static const divider = Color(0xFFF0F0F0);

  // Text
  static const ink = Color(0xFF141414);
  static const inkMid = Color(0xFF606060);
  static const inkLight = Color(0xFFAAAAAA);

  // Court — Clay
  static const clay = Color(0xFFB8603A);
  static const clayMid = Color(0xFF8C4428);
  static const clayDark = Color(0xFF6E3320);

  // Court — Hard (Wimbledon green)
  static const hard = Color(0xFF2D6A4F);
  static const hardMid = Color(0xFF1E4D39);
  static const hardDark = Color(0xFF163929);

  // Court — Padel (Wimbledon purple)
  static const padel = Color(0xFF5B3F7A);
  static const padelMid = Color(0xFF422D5A);
  static const padelDark = Color(0xFF2E1E40);

  // Ground & paths
  static const ground = Color(0xFFF5F5F0);
  static const groundEdge = Color(0xFFEAEAE4);
  static const path = Color(0xFFE0D8CC);
  static const pathEdge = Color(0xFFD4CABC);
  static const grass = Color(0xFFDDEDD6);

  // Buildings
  static const cafeTop = Color(0xFFF0E6D8);
  static const cafeLeft = Color(0xFFBAAA96);
  static const cafeRight = Color(0xFFCCBBA8);
  static const hallTop = Color(0xFFE8E4E0);
  static const hallLeft = Color(0xFFB0ACAA);
  static const hallRight = Color(0xFFC4C0BC);

  // Accents
  static const green = Color(0xFF2D6A4F);
  static const greenSoft = Color(0xFFE0F0E8);
  static const purple = Color(0xFF5B3F7A);
  static const purpleSoft = Color(0xFFEDE8F4);
  static const orange = Color(0xFFE07040);
  static const orangeSoft = Color(0xFFFAEDE8);

  // Tree
  static const treeTrunk = Color(0xFF9C7C5C);
  static const treeA = Color(0xFF3A6B44);
  static const treeB = Color(0xFF4E8558);
  static const treeC = Color(0xFF62A06C);
}

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────
enum CourtType { clay, hard, padel }

class CourtItem {
  final CourtType type;
  final String label;
  final double x, y, w, h;
  const CourtItem({
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

class BuildingItem {
  final String label;
  final double x, y, w, h, z;
  final Color top, left, right;
  const BuildingItem({
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.z,
    required this.top,
    required this.left,
    required this.right,
  });
}

class LivePlayer {
  final String initials, name, status;
  final Color color;
  final bool waving;
  final double mx, my;
  const LivePlayer({
    required this.initials,
    required this.name,
    required this.status,
    required this.color,
    required this.mx,
    required this.my,
    this.waving = false,
  });
}


// ─────────────────────────────────────────────
//  DATA
// ─────────────────────────────────────────────
// Tenis kortu gerçek oranı: 23.77m x 8.23m → yaklaşık 2.89:1 (enine)
// Padel: 20m x 10m → 2:1
// Clay tek kort, geniş

const _courts = [
  // Clay — sol, dikey (uzun taraf dikey)
  CourtItem(
    type: CourtType.clay,
    label: 'Clay',
    x: 0.04,
    y: 0.13,
    w: 0.20,
    h: 0.38,
  ),
  // Hard x4 — sağ, 2x2 grid, yatay kortlar
  CourtItem(
    type: CourtType.hard,
    label: 'Hard 1',
    x: 0.50,
    y: 0.08,
    w: 0.22,
    h: 0.14,
  ),
  CourtItem(
    type: CourtType.hard,
    label: 'Hard 2',
    x: 0.76,
    y: 0.08,
    w: 0.22,
    h: 0.14,
  ),
  CourtItem(
    type: CourtType.hard,
    label: 'Hard 3',
    x: 0.50,
    y: 0.26,
    w: 0.22,
    h: 0.14,
  ),
  CourtItem(
    type: CourtType.hard,
    label: 'Hard 4',
    x: 0.76,
    y: 0.26,
    w: 0.22,
    h: 0.14,
  ),
  // Padel x2 — alt sağ
  CourtItem(
    type: CourtType.padel,
    label: 'Padel 1',
    x: 0.50,
    y: 0.58,
    w: 0.19,
    h: 0.27,
  ),
  CourtItem(
    type: CourtType.padel,
    label: 'Padel 2',
    x: 0.74,
    y: 0.58,
    w: 0.19,
    h: 0.27,
  ),
];

const _buildings = [
  BuildingItem(
    label: 'Cafe & Lounge',
    x: 0.28,
    y: 0.08,
    w: 0.16,
    h: 0.20,
    z: 0.10,
    top: _C.cafeTop,
    left: _C.cafeLeft,
    right: _C.cafeRight,
  ),
  BuildingItem(
    label: 'Spor Salonu',
    x: 0.28,
    y: 0.38,
    w: 0.17,
    h: 0.23,
    z: 0.12,
    top: _C.hallTop,
    left: _C.hallLeft,
    right: _C.hallRight,
  ),
];

const _players = [
  LivePlayer(
    initials: 'AK',
    name: 'Ahmet K.',
    status: 'Clay Kort',
    color: _C.clay,
    mx: 0.10,
    my: 0.30,
  ),
  LivePlayer(
    initials: 'EK',
    name: 'Ece K.',
    status: 'Hard 1',
    color: _C.hard,
    mx: 0.57,
    my: 0.16,
    waving: true,
  ),
  LivePlayer(
    initials: 'SA',
    name: 'Selin A.',
    status: 'Hard 2',
    color: _C.hard,
    mx: 0.83,
    my: 0.16,
  ),
  LivePlayer(
    initials: 'DM',
    name: 'Deniz M.',
    status: 'Padel 1',
    color: _C.padel,
    mx: 0.57,
    my: 0.70,
  ),
  LivePlayer(
    initials: 'NÖ',
    name: 'Naz Ö.',
    status: 'Cafe',
    color: _C.orange,
    mx: 0.34,
    my: 0.18,
    waving: true,
  ),
];


// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});
  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glow;
  late final AnimationController _bob;
  late final AnimationController _wave;

  double _rotZ = -0.03;
  double _rotX = 0.0;
  double _lastDx = 0, _lastDy = 0;
  int _tab = 0;

  List<PartnerRequestModel> _partners = [];
  List<MatchModel> _matches = [];
  ClubStatus _clubStatus = ClubStatus.empty;
  StreamSubscription<List<PartnerRequestModel>>? _partnersSub;
  StreamSubscription<List<MatchModel>>? _matchesSub;
  StreamSubscription<ClubStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _partnersSub = FirebaseService.watchPartnerRequests().listen((data) {
      if (mounted) setState(() => _partners = data);
    });
    _matchesSub = FirebaseService.watchRecentMatches().listen((data) {
      if (mounted) setState(() => _matches = data);
    });
    _statusSub = FirebaseService.watchClubStatus().listen((data) {
      if (mounted) setState(() => _clubStatus = data);
    });
  }

  @override
  void dispose() {
    _glow.dispose();
    _bob.dispose();
    _wave.dispose();
    _partnersSub?.cancel();
    _matchesSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _tabs(),
            // ── MAP ──
            SizedBox(
              height: 300,
              child: GestureDetector(
                onPanStart: (d) {
                  _lastDx = d.localPosition.dx;
                  _lastDy = d.localPosition.dy;
                },
                onPanUpdate: (d) {
                  setState(() {
                    _rotZ += (d.localPosition.dx - _lastDx) * 0.0016;
                    _rotX -= (d.localPosition.dy - _lastDy) * 0.0008;
                    _rotZ = _rotZ.clamp(-0.20, 0.20);
                    _rotX = _rotX.clamp(-0.10, 0.10);
                    _lastDx = d.localPosition.dx;
                    _lastDy = d.localPosition.dy;
                  });
                },
                onDoubleTap: () => setState(() {
                  _rotZ = -0.03;
                  _rotX = 0.0;
                }),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_glow, _bob, _wave]),
                    builder: (_, __) => CustomPaint(
                      painter: _MapPainter(
                        rotZ: _rotZ,
                        rotX: _rotX,
                        glow: _glow.value,
                        bob: _bob.value,
                        wave: _wave.value,
                        players: _players,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            // ── SCROLL ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _quickStats(),
                    const SizedBox(height: 20),
                    _partnerSection(),
                    const SizedBox(height: 20),
                    _matchFeed(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.bgSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.sports_tennis_rounded,
            color: _C.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Club',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const _PulseDot(),
                  const SizedBox(width: 5),
                  Text(
                    '${_clubStatus.presentCount} kişi tesiste · '
                    '${_clubStatus.activeCourtCount} kort aktif',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _C.inkMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _LiveBadge(),
      ],
    ),
  );

  Widget _tabs() {
    final labels = ['Tümü', 'Müsait', 'Sosyal'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final on = _tab == i;
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: on ? _C.ink : _C.bgSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : _C.inkMid,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _quickStats() => Row(
    children: [
      Expanded(
        child: _StatCard(
          label: 'Aktif kort',
          value: '${_clubStatus.activeCourtCount}',
          icon: Icons.sports_tennis_rounded,
          color: _C.green,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          label: 'Partner arıyor',
          value: '${_clubStatus.partnerSeekerCount}',
          icon: Icons.person_search_rounded,
          color: _C.purple,
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: _StatCard(
          label: 'Cafe',
          value: 'Sakin',
          icon: Icons.local_cafe_rounded,
          color: _C.orange,
        ),
      ),
    ],
  );

  Widget _partnerSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader(
        title: 'Partner Arıyor',
        subtitle: 'Yakındaki oyuncularla eşleş',
        action: 'Tümü',
      ),
      const SizedBox(height: 10),
      for (final r in _partners) _PartnerCard(r: r),
    ],
  );

  Widget _matchFeed() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionHeader(
        title: 'Son Maçlar',
        subtitle: 'Canlı skor akışı',
        action: 'Geçmiş',
      ),
      const SizedBox(height: 10),
      for (final m in _matches) _MatchCard(m: m),
    ],
  );
}

// ─────────────────────────────────────────────
//  PAINTER
// ─────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  final double rotZ, rotX, glow, bob, wave;
  final List<LivePlayer> players;

  const _MapPainter({
    required this.rotZ,
    required this.rotX,
    required this.glow,
    required this.bob,
    required this.wave,
    required this.players,
  });

  Offset _p(double nx, double ny, double nz, Size s) {
    final cx = s.width / 2;
    final cy = s.height * 0.50;
    final sc = s.width * 0.82;
    final tilt = 0.50 + rotX;
    final c = math.cos(rotZ), si = math.sin(rotZ);
    final rx = (nx - 0.5) * c - (ny - 0.5) * si;
    final ry = (nx - 0.5) * si + (ny - 0.5) * c;
    return Offset(cx + rx * sc, cy + ry * sc * tilt - nz * 56);
  }

  Path _tile(Size s, double x, double y, double w, double h, double z) {
    final tl = _p(x, y, z, s), tr = _p(x + w, y, z, s);
    final br = _p(x + w, y + h, z, s), bl = _p(x, y + h, z, s);
    return Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
  }

  void _quad(Canvas c, Offset a, Offset b, Offset cc, Offset d, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(cc.dx, cc.dy)
        ..lineTo(d.dx, d.dy)
        ..close(),
      p,
    );
  }

  void _block(
    Canvas c,
    Size s, {
    required double x,
    required double y,
    required double w,
    required double h,
    required double z,
    required Color top,
    required Color left,
    required Color right,
    double glowOp = 0,
    Color glowCol = Colors.transparent,
  }) {
    final tl = _p(x, y, z, s), tr = _p(x + w, y, z, s);
    final bl = _p(x, y + h, z, s), br = _p(x + w, y + h, z, s);
    final tl0 = _p(x, y, 0, s), tr0 = _p(x + w, y, 0, s);
    final bl0 = _p(x, y + h, 0, s), br0 = _p(x + w, y + h, 0, s);
    final tp = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    // soft shadow
    c.drawPath(
      Path()
        ..moveTo(tl0.dx + 4, tl0.dy + 5)
        ..lineTo(tr0.dx + 4, tr0.dy + 5)
        ..lineTo(br0.dx + 4, br0.dy + 5)
        ..lineTo(bl0.dx + 4, bl0.dy + 5)
        ..close(),
      Paint()
        ..color = Colors.black.withOpacity(0.07)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    _quad(c, tl0, tl, bl, bl0, Paint()..color = left);
    _quad(c, tr0, tr, br, br0, Paint()..color = right);

    c.drawPath(
      tp,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(top, Colors.white, 0.10)!,
            top,
            Color.lerp(top, Colors.black, 0.06)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(tp.getBounds()),
    );

    if (glowOp > 0) {
      c.drawPath(
        tp,
        Paint()
          ..color = glowCol.withOpacity(glowOp)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
    }

    c.drawPath(
      tp,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(0.30),
    );
  }

  void _courtLines(Canvas c, Size s, CourtItem ct, double z) {
    final isPadel = ct.type == CourtType.padel;
    final isClay = ct.type == CourtType.clay;
    final op = isClay ? 0.48 : 0.60;
    final lp = Paint()
      ..strokeWidth = 0.85
      ..strokeCap = StrokeCap.round;
    const dz = 0.004;

    void ln(double x1, double y1, double x2, double y2, [double o = 1]) {
      lp.color = Colors.white.withOpacity(op * o);
      c.drawLine(
        _p(ct.x + ct.w * x1, ct.y + ct.h * y1, z + dz, s),
        _p(ct.x + ct.w * x2, ct.y + ct.h * y2, z + dz, s),
        lp,
      );
    }

    // Boundary
    ln(0.06, 0.06, 0.94, 0.06, .9);
    ln(0.94, 0.06, 0.94, 0.94, .9);
    ln(0.94, 0.94, 0.06, 0.94, .9);
    ln(0.06, 0.94, 0.06, 0.06, .9);

    if (!isPadel) {
      // Singles sidelines
      ln(0.22, 0.06, 0.22, 0.94, .45);
      ln(0.78, 0.06, 0.78, 0.94, .45);
      // Service boxes
      ln(0.22, 0.30, 0.78, 0.30, .55);
      ln(0.22, 0.70, 0.78, 0.70, .55);
      // Centre service line
      ln(0.50, 0.30, 0.50, 0.70, .40);
    } else {
      // Padel service boxes
      ln(0.25, 0.06, 0.25, 0.94, .35);
      ln(0.75, 0.06, 0.75, 0.94, .35);
      ln(0.06, 0.50, 0.94, 0.50, .55);
      // Glass wall outline
      c.drawPath(
        _tile(
          s,
          ct.x + ct.w * 0.01,
          ct.y + ct.h * 0.01,
          ct.w * 0.98,
          ct.h * 0.98,
          z + 0.018,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withOpacity(0.35),
      );
    }
  }

  void _net(Canvas c, Size s, CourtItem ct, double z) {
    final a = _p(ct.x + ct.w * 0.50, ct.y + ct.h * 0.07, z + 0.016, s);
    final b = _p(ct.x + ct.w * 0.50, ct.y + ct.h * 0.93, z + 0.016, s);

    c.drawLine(
      a,
      b,
      Paint()
        ..color = Colors.black.withOpacity(0.28)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    final mesh = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 0.4;
    for (double t = 0.15; t <= 0.85; t += 0.14) {
      c.drawLine(
        _p(ct.x + ct.w * 0.48, ct.y + ct.h * t, z + 0.018, s),
        _p(ct.x + ct.w * 0.52, ct.y + ct.h * t, z + 0.018, s),
        mesh,
      );
    }

    for (final yy in [0.07, 0.93]) {
      c.drawLine(
        _p(ct.x + ct.w * 0.50, ct.y + ct.h * yy, z + 0.006, s),
        _p(ct.x + ct.w * 0.50, ct.y + ct.h * yy, z + 0.036, s),
        Paint()
          ..color = Colors.black.withOpacity(0.35)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _road(Canvas c, Size s, List<Offset> pts, {double w = 11}) {
    final rp = Paint()
      ..color = _C.path
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final ep = Paint()
      ..color = _C.pathEdge.withOpacity(0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < pts.length - 1; i++) {
      c.drawLine(
        _p(pts[i].dx, pts[i].dy, 0.004, s),
        _p(pts[i + 1].dx, pts[i + 1].dy, 0.004, s),
        rp,
      );
      c.drawLine(
        _p(pts[i].dx, pts[i].dy, 0.006, s),
        _p(pts[i + 1].dx, pts[i + 1].dy, 0.006, s),
        ep,
      );
    }
  }

  void _tree(Canvas c, Size s, double nx, double ny, {double sc = 1}) {
    final pos = _p(nx, ny, 0.03, s);
    // shadow
    c.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy + 11 * sc),
        width: 16 * sc,
        height: 5 * sc,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.09)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    // trunk
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx, pos.dy + 10 * sc),
          width: 3.5 * sc,
          height: 11 * sc,
        ),
        Radius.circular(2 * sc),
      ),
      Paint()..color = _C.treeTrunk,
    );
    // canopy layers
    void tri(double topY, double hw, double hh, Color col) {
      c.drawPath(
        Path()
          ..moveTo(pos.dx, pos.dy + topY * sc)
          ..lineTo(pos.dx - hw * sc, pos.dy + (topY + hh) * sc)
          ..lineTo(pos.dx + hw * sc, pos.dy + (topY + hh) * sc)
          ..close(),
        Paint()..color = col,
      );
    }

    tri(-20, 12, 16, _C.treeA);
    tri(-11, 10, 15, _C.treeB);
    tri(-3, 8, 13, _C.treeC);
  }

  void _lbl(
    Canvas c,
    String t,
    Offset pos, {
    double fs = 8,
    Color col = Colors.white,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          color: col,
          fontSize: fs,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // ── Ground ──
    final gnd = _tile(size, -0.09, -0.06, 1.18, 1.12, 0);
    canvas.drawShadow(gnd, Colors.black.withOpacity(0.18), 30, false);
    canvas.drawPath(
      gnd,
      Paint()
        ..shader = const LinearGradient(
          colors: [_C.ground, _C.groundEdge],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(gnd.getBounds()),
    );

    // Grass strips top/bottom
    _quad(
      canvas,
      _p(-0.04, -0.01, 0.001, size),
      _p(1.04, -0.01, 0.001, size),
      _p(1.04, 0.10, 0.001, size),
      _p(-0.04, 0.10, 0.001, size),
      Paint()..color = _C.grass.withOpacity(0.70),
    );
    _quad(
      canvas,
      _p(-0.04, 0.92, 0.001, size),
      _p(1.04, 0.92, 0.001, size),
      _p(1.04, 1.04, 0.001, size),
      _p(-0.04, 1.04, 0.001, size),
      Paint()..color = _C.grass.withOpacity(0.60),
    );

    // Roads
    _road(canvas, size, [
      const Offset(0.46, 0.04),
      const Offset(0.46, 0.96),
    ], w: 12);
    _road(canvas, size, [
      const Offset(0.04, 0.54),
      const Offset(0.96, 0.54),
    ], w: 12);
    _road(canvas, size, [
      const Offset(0.26, 0.22),
      const Offset(0.96, 0.22),
    ], w: 9);

    // Buildings
    for (final b in _buildings) {
      _block(
        canvas,
        size,
        x: b.x,
        y: b.y,
        w: b.w,
        h: b.h,
        z: b.z,
        top: b.top,
        left: b.left,
        right: b.right,
      );
      // inner detail line
      canvas.drawPath(
        _tile(
          size,
          b.x + 0.02,
          b.y + 0.02,
          b.w - 0.04,
          b.h - 0.04,
          b.z + 0.004,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withOpacity(0.35),
      );
      _lbl(
        canvas,
        b.label,
        _p(b.x + b.w * 0.5, b.y + b.h * 0.5, b.z + 0.008, size),
        col: const Color(0xFF5A5560),
        fs: 7.2,
        bold: true,
      );
    }

    // Courts
    for (final ct in _courts) {
      final isClay = ct.type == CourtType.clay;
      final isHard = ct.type == CourtType.hard;
      final top = isClay
          ? _C.clay
          : isHard
          ? _C.hard
          : _C.padel;
      final left = isClay
          ? _C.clayDark
          : isHard
          ? _C.hardDark
          : _C.padelDark;
      final right = isClay
          ? _C.clayMid
          : isHard
          ? _C.hardMid
          : _C.padelMid;
      const z = 0.022;
      _block(
        canvas,
        size,
        x: ct.x,
        y: ct.y,
        w: ct.w,
        h: ct.h,
        z: z,
        top: top,
        left: left,
        right: right,
        glowOp: 0.04 + glow * 0.05,
        glowCol: top,
      );
      _courtLines(canvas, size, ct, z);
      _net(canvas, size, ct, z);
    }

    // Trees
    for (final t in const [
      Offset(0.01, 0.05),
      Offset(0.12, 0.07),
      Offset(0.02, 0.78),
      Offset(0.13, 0.90),
      Offset(0.91, 0.03),
      Offset(0.97, 0.28),
      Offset(0.97, 0.78),
      Offset(0.90, 0.92),
      Offset(0.36, 0.56),
      Offset(0.44, 0.56),
    ]) {
      _tree(canvas, size, t.dx, t.dy, sc: 0.88);
    }

    // Avatars
    for (final p in players) {
      _avatar(canvas, size, p);
    }
  }

  void _avatar(Canvas c, Size s, LivePlayer p) {
    final bobY = p.waving ? bob * 4.0 : bob * 1.5;
    final base = _p(p.mx, p.my, 0.038, s);
    final pos = Offset(base.dx, base.dy - bobY);

    // shadow
    c.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 9), width: 16, height: 5),
      Paint()..color = Colors.black.withOpacity(0.13),
    );
    // glow
    c.drawCircle(
      pos,
      14,
      Paint()
        ..color = p.color.withOpacity(0.20 + bob * 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    // body
    c.drawCircle(pos, 10, Paint()..color = p.color);
    c.drawCircle(
      pos,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withOpacity(0.70),
    );
    // highlight
    c.drawCircle(
      Offset(pos.dx - 3, pos.dy - 3),
      2.8,
      Paint()..color = Colors.white.withOpacity(0.28),
    );
    // initials
    _lbl(c, p.initials, pos, fs: 7.0, col: Colors.white, bold: true);
    // wave
    if (p.waving) {
      final angle = wave * math.pi * 0.45 - 0.1;
      final wx = pos.dx + 14 * math.cos(angle);
      final wy = pos.dy - 7 - 5 * math.sin(wave * math.pi);
      (TextPainter(
        text: const TextSpan(text: '👋', style: TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout()).paint(c, Offset(wx - 5, wy - 9));
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) => true;
}

// ─────────────────────────────────────────────
//  WIDGETS
// ─────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(_C.green, const Color(0xFF68C98A), _c.value),
        boxShadow: [
          BoxShadow(
            color: _C.green.withOpacity(0.35 + _c.value * 0.20),
            blurRadius: 7,
          ),
        ],
      ),
    ),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: _C.ink,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _C.ink.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: Color(0xFF58C98D)),
        SizedBox(width: 6),
        Text(
          'Canlı',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.divider),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const Spacer(),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _C.ink,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _C.inkLight,
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title, subtitle, action;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.action,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _C.ink,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: _C.inkLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      Text(
        action,
        style: const TextStyle(
          fontSize: 12,
          color: _C.purple,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  const _ActionButton({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.20),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _PartnerCard extends StatelessWidget {
  final PartnerRequestModel r;
  const _PartnerCard({required this.r});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.divider),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: r.color.withOpacity(0.12),
          child: Text(
            r.initials,
            style: TextStyle(
              color: r.color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.userName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: [
                  _Tag(label: r.level, color: _C.purple),
                  _Tag(label: r.courtType, color: r.color),
                  _Tag(label: r.availableAt, color: _C.inkMid),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _ActionButton(label: 'Davet Et', color: r.color),
      ],
    ),
  );
}

class _MatchCard extends StatelessWidget {
  final MatchModel m;
  const _MatchCard({required this.m});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.divider),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _C.greenSoft,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(
            child: Text('🎾', style: TextStyle(fontSize: 19)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: _C.ink),
                  children: [
                    TextSpan(
                      text: m.p1Name,
                      style: TextStyle(
                        fontWeight: m.p1Won ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
                    const TextSpan(
                      text: '  vs  ',
                      style: TextStyle(color: _C.inkLight),
                    ),
                    TextSpan(
                      text: m.p2Name,
                      style: TextStyle(
                        fontWeight: !m.p1Won
                            ? FontWeight.w800
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${m.courtName} · ${m.agoLabel}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _C.inkLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _C.greenSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            m.score,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _C.green,
            ),
          ),
        ),
      ],
    ),
  );
}
