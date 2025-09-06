import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import 'procedural_impact.dart';

// Keep consistent with your scene layout
const double kBaselineRatio = 0.906;

/// Blazing meteor that always travels LEFT -> RIGHT and
/// spawns a visible explosion (ProceduralImpact) on ground contact.
///
/// NOTE: Default priority is high so it renders above hills/clouds.
/// You can still override when creating the component.
class ProceduralMeteor extends PositionComponent
    with HasGameRef, CollisionCallbacks {
  final bool background;

  ProceduralMeteor({
    required this.background,
    int priority = 1500, // draw above mountains/background
  }) : super(size: Vector2.all(1), anchor: Anchor.center, priority: priority);

  // ---- init guard ----
  bool _ready = false;

  // ---- RNG & motion ----
  final _rng = Random();
  Vector2 _vel = Vector2.zero();   // init to avoid LateInitializationError
  late double _speed, _life;
  double _t = 0;

  // ---- visuals ----
  late double _headR, _trailLen, _flareLen;
  late int _layers;
  late double _fanDeg;

  final Paint _add = Paint()..blendMode = BlendMode.plus;
  final Paint _bloom = Paint()
    ..blendMode = BlendMode.plus
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // spawn off LEFT, fly right/down at a shallow angle
    final y0 = _rng.nextDouble() * (gameRef.size.y * 0.45);
    final x0 = -140.0 - _rng.nextDouble() * 80.0;
    position = Vector2(x0, y0);

    final shallow = _rng.nextDouble() * 0.21 + 0.08; // ~8°..20°
    final angle = shallow;

    _speed = (background ? 110.0 : 150.0) + _rng.nextDouble() * (background ? 30.0 : 40.0);
    _vel = Vector2(cos(angle), sin(angle)) * _speed;

    _headR    = background ? 12.0 : 26.0 + _rng.nextDouble() * 6.0;
    _trailLen = background ? 340.0 : 600.0 + _rng.nextDouble() * 160.0;
    _layers   = background ? 6 : 11;   // painterly thickness
    _fanDeg   = background ? 12 : 22;  // wide fiery fan
    _flareLen = _headR * (background ? 2.8 : 4.2);
    _life     = 7.0; // safety, usually hits ground first

    if (!background) {
      add(CircleHitbox(radius: _headR * 0.9)..collisionType = CollisionType.passive);
    }

    _ready = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready) return;

    _t += dt;

    // Ground Y in THIS component's parent space (fallback to game size)
    final parentSize = (parent is PositionComponent && (parent as PositionComponent).size.y > 0)
        ? (parent as PositionComponent).size
        : gameRef.size;
    final groundY = parentSize.y * kBaselineRatio;

    // previous pos
    final prevX = x;
    final prevY = y;

    // integrate motion
    position += _vel * dt;

    // --- SWEPT CIRCLE vs. GROUND ---
    final prevBottom = prevY + _headR * 0.6;
    final currBottom = y + _headR * 0.6;

    if (prevBottom < groundY && currBottom >= groundY) {
      // intersection factor 0..1
      final denom = (currBottom - prevBottom);
      final k = denom.abs() < 1e-6 ? 0.0 : (groundY - prevBottom) / denom;

      final hitX = prevX + (x - prevX) * k;

      // rest the head slightly above the ground
      x = hitX;
      y = groundY - _headR * 0.2;

      // add impact to the SAME PARENT so layer/coords match
      (parent ?? gameRef).add(
        ProceduralImpact(
          position: Vector2(hitX, groundY),
          big: !background,
          priority: 3000, // above everything
        ),
      );

      removeFromParent();
      return;
    }

    // cleanup after impact check (don't remove early)
    if (_t > _life ||
        x < -400 || x > parentSize.x + 400 ||
        y > parentSize.y + 300) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas c) {
    super.render(c);
    if (!_ready) return;

    final dir = _vel.normalized();
    final baseTail = -dir * _trailLen;
    final n = Vector2(-dir.y, dir.x);

    final flick = 1.0 + sin(_t * 18.0) * 0.10;
    final breathe = 1.0 + sin(_t * 4.0) * 0.05;

    // ==== FIERY FAN ====
    final fanRad = _fanDeg * pi / 180.0;
    for (int i = 0; i < _layers; i++) {
      final t = (_layers == 1) ? 0.5 : i / (_layers - 1);
      final spread = (t - 0.5) * 2.0;
      final rot = _rotate(baseTail, fanRad * spread * 0.95);

      final wHead = ui.lerpDouble((background ? 5.0 : 9.0),
                                  (background ? 8.0 : 16.0), 1 - t)! * flick * breathe;
      final wTail = ui.lerpDouble((background ? 1.0 : 1.6),
                                  (background ? 1.8 : 2.8), 1 - t)!;

      final headL = Offset( n.x * wHead,  n.y * wHead);
      final headR = Offset(-n.x * wHead, -n.y * wHead);
      final tailL = Offset(rot.x + n.x * wTail, rot.y + n.y * wTail);
      final tailR = Offset(rot.x - n.x * wTail, rot.y - n.y * wTail);

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(headL.dx, headL.dy)
        ..lineTo(tailL.dx, tailL.dy)
        ..lineTo(tailR.dx, tailR.dy)
        ..lineTo(headR.dx, headR.dy)
        ..close();

      _add.shader = ui.Gradient.linear(
        Offset.zero, Offset(rot.x, rot.y),
        const [
          Color(0xFFFFFFFF), // white core
          Color(0xFFFFF176), // pale yellow
          Color(0xFFFFB74D), // orange
          Color(0xFFFF7043), // deep orange
          Color(0x00FF7043), // fade
        ],
        const [0.00, 0.20, 0.46, 0.78, 1.00],
      );
      c.drawPath(path, _add);
    }

    // === SOFT GLOW STREAK ===
    _drawGlowStreak(c, baseTail * 0.82, _headR * (background ? 1.2 : 1.8));

    // === BRIGHT CORE WEDGE ===
    final coreW = background ? 3.0 : 4.6;
    final coreL = baseTail * 0.9;
    final pL = Offset(coreL.x + n.x * coreW, coreL.y + n.y * coreW);
    final pR = Offset(coreL.x - n.x * coreW, coreL.y - n.y * coreW);
    final core = Path()..moveTo(0, 0)..lineTo(pL.dx, pL.dy)..lineTo(pR.dx, pR.dy)..close();
    _add.shader = ui.Gradient.linear(
      Offset.zero, Offset(coreL.x, coreL.y),
      const [Color(0xFFFFFFFF), Color(0xB3FFF59D), Color(0x00FFFFFF)],
      const [0.0, 0.55, 1.0],
    );
    c.drawPath(core, _add);

    // === HEAD + BLOOM ===
    _add.shader = ui.Gradient.radial(
      Offset.zero, _headR * 0.9 * flick,
      const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
      const [0.0, 1.0],
    );
    c.drawCircle(Offset.zero, _headR * 0.9 * flick, _add);

    _add.shader = ui.Gradient.radial(
      Offset.zero, _headR * 1.45 * flick,
      const [Color(0xFFFFF59D), Color(0xFFFFB74D), Color(0x00FFB74D)],
      const [0.0, 0.65, 1.0],
    );
    c.drawCircle(Offset.zero, _headR * 1.45 * flick, _add);

    _bloom.shader = ui.Gradient.radial(
      Offset.zero, _headR * (background ? 3.2 : 4.0) * flick,
      const [Color(0x55FFB74D), Color(0x00FFB74D)],
      const [0.0, 1.0],
    );
    c.drawCircle(Offset.zero, _headR * (background ? 3.2 : 4.0) * flick, _bloom);

    _drawSparks(c, dir, baseTail);
  }

  // helpers
  Vector2 _rotate(Vector2 v, double ang) {
    final s = sin(ang), c = cos(ang);
    return Vector2(v.x * c - v.y * s, v.x * s + v.y * c);
  }

  void _drawGlowStreak(Canvas c, Vector2 along, double width) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, width * 0.7)
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(along.x, along.y),
        const [Color(0xFFFFE082), Color(0x00FFE082)],
        const [0.0, 1.0],
      );
    c.drawLine(Offset.zero, Offset(along.x, along.y), paint);
  }

  void _drawSparks(Canvas c, Vector2 dir, Vector2 baseTail) {
    final n = Vector2(-dir.y, dir.x);
    final sparkCount = background ? 6 : 12; // fewer sparks
    for (int i = 0; i < sparkCount; i++) {
      final t = _rng.nextDouble();
      final along = baseTail * t;
      final jitter = ((_rng.nextDouble() - 0.5) * (_headR * 0.9));
      final off = Offset(along.x + n.x * jitter, along.y + n.y * jitter);

      final r = background ? 0.8 : 1.3;
      _add.shader = ui.Gradient.radial(
        off, r * 3.0,
        const [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
        const [0.0, 1.0],
      );
      c.drawCircle(off, r, _add);
    }
  }
}
