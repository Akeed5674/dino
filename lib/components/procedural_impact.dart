import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

const double kBaselineRatio = 0.906;

/// Small fiery explosion on ground impact (bright flash, shockwave, petals, embers, smoke).
class ProceduralImpact extends PositionComponent {
  final bool big;
  ProceduralImpact({
    required Vector2 position,
    this.big = true,
    int priority = 3000, // draw above terrain/clouds/meteors
  }) : super(position: position, size: Vector2.all(1), anchor: Anchor.center, priority: priority);

  final _rng = Random();
  double _t = 0.0;
  late double _dur;

  late List<_Debris> _debris;
  late List<_Shard>  _shards;

  final _add  = Paint()..blendMode = BlendMode.plus;
  final _norm = Paint();
  final _bloom = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _dur = big ? 1.35 : 1.05;

    // Upward-biased debris (glowing dots)
    final nDebris = big ? 24 : 16;
    _debris = List.generate(nDebris, (_) {
      final a   = (-pi / 2) + (_rng.nextDouble() - 0.5) * pi * 0.9;
      final spd = (big ? 260.0 : 200.0) * (0.7 + _rng.nextDouble() * 0.9);
      final r   = (big ? 1.9 : 1.6) * (0.8 + _rng.nextDouble() * 1.2);
      return _Debris(angle: a, speed: spd, radius: r);
    });

    // Radial “petals” burst (short fiery wedges)
    final nShards = big ? 14 : 10;
    _shards = List.generate(nShards, (i) {
      final a = (-pi / 2) + (i / nShards - 0.5) * pi * 0.9 + (_rng.nextDouble() - 0.5) * 0.15;
      final len = (big ? 110.0 : 90.0) * (0.8 + _rng.nextDouble() * 0.6);
      final w   = (big ? 10.0 : 8.0) * (0.9 + _rng.nextDouble() * 0.4);
      return _Shard(angle: a, length: len, width: w);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _dur) removeFromParent();
  }

  @override
  void render(Canvas c) {
    super.render(c);

    final p    = (_t / _dur).clamp(0.0, 1.0);
    final inv  = 1.0 - p;
    final hotO = Curves.easeOut.transform(inv);
    final smokeO = Curves.easeIn.transform(inv);

    // 0) ground scorch (lingers)
    final scorchR = ui.lerpDouble(26, big ? 64 : 52, p)!;
    _norm
      ..shader = ui.Gradient.radial(
        Offset.zero, scorchR,
        [const Color(0x2220170F).withOpacity(0.35 * inv), const Color(0x00000000)],
        const [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
    c.drawCircle(Offset.zero, scorchR, _norm);

    // 1) white hot flash + bloom
    final flashR = ui.lerpDouble(big ? 30 : 24, big ? 18 : 14, p)!;
    _add
      ..shader = ui.Gradient.radial(
        Offset.zero, flashR,
        [const Color(0xFFFFFFFF).withOpacity(0.9 * hotO), const Color(0x00FFFFFF)],
        const [0.0, 1.0],
      )
      ..style = PaintingStyle.fill;
    c.drawCircle(Offset.zero, flashR, _add);

    _bloom.shader = ui.Gradient.radial(
      Offset.zero, (big ? 100.0 : 80.0),
      [const Color(0x66FFF3B0).withOpacity(0.7 * hotO), const Color(0x00FFF3B0)],
      const [0.0, 1.0],
    );
    c.drawCircle(Offset.zero, big ? 100 : 80, _bloom);

    // 2) expanding shockwave ring
    final ringR = (big ? 30.0 : 24.0) + p * (big ? 200.0 : 150.0);
    _add
      ..shader = null
      ..color = Colors.white.withOpacity(0.55 * inv)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, (big ? 7.0 : 5.0) * inv);
    c.drawCircle(Offset.zero, ringR, _add);

    // 3) fiery radial shards
    for (final s in _shards) {
      final len = s.length * (0.65 + 0.35 * inv);
      final w   = s.width  * (0.55 + 0.45 * inv);
      final dir = Offset(cos(s.angle), sin(s.angle));
      final n   = Offset(-sin(s.angle), cos(s.angle));

      final tip = dir * len;
      final pL  = Offset(0, 0) + n * w * 0.5;
      final pR  = Offset(0, 0) - n * w * 0.5;

      final path = Path()
        ..moveTo(pL.dx, pL.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(pR.dx, pR.dy)
        ..close();

      _add.shader = ui.Gradient.linear(
        const Offset(0, 0), tip,
        const [Color(0xFFFFFFFF), Color(0xFFFFE082), Color(0xFFFF8A50), Color(0x00FF8A50)],
        const [0.00, 0.25, 0.60, 1.00],
      );
      _add.blendMode = BlendMode.plus;
      c.drawPath(path, _add);
    }

    // 4) dust/smoke plume
    final plumeH = (big ? 120.0 : 95.0) * (0.8 + 0.2 * inv);
    final plumeW = (big ? 100.0 : 80.0);
    final smoke = Path()
      ..moveTo(-plumeW * 0.55, 0)
      ..quadraticBezierTo(-plumeW * 0.38, -plumeH * 0.35, -plumeW * 0.22, -plumeH)
      ..lineTo(plumeW * 0.22, -plumeH)
      ..quadraticBezierTo(plumeW * 0.38, -plumeH * 0.35, plumeW * 0.55, 0)
      ..close();
    _norm.shader = ui.Gradient.linear(
      const Offset(0, 0), Offset(0, -plumeH),
      [const Color(0x44FFFFFF).withOpacity(0.5 * smokeO), const Color(0x00FFFFFF)],
      const [0.0, 1.0],
    );
    c.drawPath(smoke, _norm);

    // 5) glowing debris with mini streaks
    for (final d in _debris) {
      final t = p;
      final vx = cos(d.angle) * d.speed;
      final vy0 = sin(d.angle) * d.speed;
      const g = 520.0;
      final px = vx * t;
      final py = vy0 * t - 0.5 * g * (t * t);
      final life = (1.0 - t).clamp(0.0, 1.0);

      // glowing dot
      _add
        ..shader = null
        ..color = const Color(0xFFFFB74D).withOpacity(0.85 * life);
      c.drawCircle(Offset(px, -py - 6), d.radius, _add);

      // short additive streak behind each debris
      final v = Offset(vx, vy0 - g * t);
      final vdir = v.distanceSquared == 0 ? const Offset(0, -1) : -v / v.distance;
      final tail = Offset(px, -py - 6) + vdir * (big ? 10.0 : 8.0) * life;
      final streak = Paint()
        ..blendMode = BlendMode.plus
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(0.6, d.radius * 0.7)
        ..shader = ui.Gradient.linear(
          Offset(px, -py - 6), tail,
          const [Color(0xFFFFE082), Color(0x00FFE082)],
          const [0.0, 1.0],
        );
      c.drawLine(Offset(px, -py - 6), tail, streak);
    }
  }
}

class _Debris {
  final double angle, speed, radius;
  _Debris({required this.angle, required this.speed, required this.radius});
}

class _Shard {
  final double angle, length, width;
  _Shard({required this.angle, required this.length, required this.width});
}
