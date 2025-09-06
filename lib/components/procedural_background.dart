import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class ProceduralBackground extends PositionComponent
    with HasGameRef<FlameGame> {
  ProceduralBackground({int priority = 0}) : super(priority: priority);

  // No 'late final' anywhere — hot-reload safe
  final Random _rand = Random();
  final List<_Star> _stars = [];
  final List<_Ridge> _ridges = [];

  double _t = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;

    if (_stars.isEmpty) {
      // Pre-generate stable stars (positions + base radii)
      for (var i = 0; i < 120; i++) {
        final x = _rand.nextDouble() * size.x;
        final y = _rand.nextDouble() * size.y * 0.58;
        final r = 0.6 + _rand.nextDouble() * 1.3;
        final phase = _rand.nextDouble() * pi * 2;
        _stars.add(_Star(Vector2(x, y), r, phase));
      }
    }

    if (_ridges.isEmpty) {
      // Furthest -> nearest (cooler + lighter far, darker near)
      _ridges.addAll([
        _Ridge(
          colorTop: const ui.Color(0xFF111E3A),
          colorBot: const ui.Color(0xFF0E1A32),
          yRatio: 0.64,
          amp: 22,
          freq: 1.5,
          speed: 9,
          fogAlpha: 0.08,
        ),
        _Ridge(
          colorTop: const ui.Color(0xFF162443),
          colorBot: const ui.Color(0xFF12203B),
          yRatio: 0.72,
          amp: 36,
          freq: 1.2,
          speed: 16,
          fogAlpha: 0.10,
        ),
        _Ridge(
          colorTop: const ui.Color(0xFF1B2B4E),
          colorBot: const ui.Color(0xFF152644),
          yRatio: 0.80,
          amp: 52,
          freq: 0.9,
          speed: 24,
          fogAlpha: 0.12,
        ),
        _Ridge(
          colorTop: const ui.Color(0xFF21345D),
          colorBot: const ui.Color(0xFF182A4C),
          yRatio: 0.88,
          amp: 68,
          freq: 0.7,
          speed: 34,
          fogAlpha: 0.14,
        ),
      ]);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    for (final r in _ridges) {
      r.offset = (r.offset - r.speed * dt) % size.x;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final w = size.x, h = size.y;

    // --- Sky gradient ---
    final sky = ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        ui.Offset(0, h),
        const [
          ui.Color(0xFF0E1730),
          ui.Color(0xFF172448),
          ui.Color(0xFF1E2D57),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), sky);

    // --- Horizon haze ---
    final haze = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, h * 0.60),
        ui.Offset(0, h * 0.90),
        const [ui.Color(0x00000000), ui.Color(0x22000000)],
        const [0.0, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, h * 0.60, w, h * 0.30), haze);

    // --- Moon + halo ---
    final moonCenter = ui.Offset(w * 0.18, h * 0.20);
    _drawCrescent(canvas, center: moonCenter, r: h * 0.065);

    // --- Stars (twinkle + soft glow) ---
    final starPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    final glowPaint = ui.Paint()
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5);

    for (final s in _stars) {
      final tw = 0.72 + 0.28 * (0.5 + 0.5 * sin(_t * (1.2 + s.r * 0.3) + s.phase));
      final r = s.r * tw;

      canvas.drawCircle(
        ui.Offset(s.pos.x, s.pos.y),
        r * 1.8,
        glowPaint..color = const ui.Color(0x55FFFFFF),
      );
      canvas.drawCircle(ui.Offset(s.pos.x, s.pos.y), r, starPaint);
    }

    // --- Ridges + inter-layer fog ---
    for (final r in _ridges) {
      _drawRidge(canvas, r, w, h);
      _drawFogBand(canvas, baseY: h * r.yRatio, thickness: h * 0.06, alpha: r.fogAlpha);
    }

    // --- Base vignette / ground blend ---
    final baseFog = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, h * 0.92),
        ui.Offset(0, h),
        const [ui.Color(0x00FFFFFF), ui.Color(0x22000000)],
        const [0.0, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, h * 0.92, w, h * 0.08), baseFog);

    final vignette = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(w * 0.5, h * 0.5), h * 0.75,
        const [ui.Color(0x00000000), ui.Color(0x22000000)],
        const [0.65, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w, h), vignette);
  }

  // ---------- helpers ----------
  void _drawCrescent(ui.Canvas canvas,
      {required ui.Offset center, required double r}) {
    final rect = ui.Rect.fromCircle(center: center, radius: r);
    canvas.saveLayer(rect.inflate(r * 0.5), ui.Paint());
    canvas.drawCircle(center, r, ui.Paint()..color = const ui.Color(0xFFEFF5FF));
    final mask = ui.Paint()..blendMode = ui.BlendMode.clear;
    canvas.drawCircle(center.translate(r * 0.52, r * 0.06), r * 1.02, mask);
    canvas.restore();

    final halo = ui.Paint()
      ..blendMode = ui.BlendMode.plus
      ..shader = ui.Gradient.radial(
        center,
        r * 2.6,
        const [ui.Color(0x66FFFFFF), ui.Color(0x00000000)],
        const [0.0, 1.0],
      );
    canvas.drawCircle(center, r * 2.6, halo);
  }

  void _drawRidge(ui.Canvas canvas, _Ridge r, double w, double h) {
    final baseY = h * r.yRatio;
    final path = ui.Path()..moveTo(-w, h);
    final k = r.freq * 2 * pi / w;
    final off = r.offset;

    for (double x = -w; x <= w * 2; x += 16) {
      final y = baseY + sin((x + off) * k) * r.amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(w * 2, h)
      ..close();

    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, baseY - r.amp * 1.4),
        ui.Offset(0, h),
        [r.colorTop, r.colorBot],
        const [0.0, 1.0],
      );
    canvas.drawPath(path, paint);
  }

  void _drawFogBand(ui.Canvas canvas,
      {required double baseY, required double thickness, required double alpha}) {
    final w = size.x;
    final rect = ui.Rect.fromLTWH(0, baseY - thickness * 0.6, w, thickness * 1.6);
    final fog = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, rect.top),
        ui.Offset(0, rect.bottom),
        [
          ui.Color(0x00FFFFFF),
          ui.Color(0x33FFFFFF).withOpacity(alpha),
          ui.Color(0x00FFFFFF),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(rect, fog);
  }
}

// ---------- data classes ----------
class _Star {
  final Vector2 pos;
  final double r;
  final double phase;
  _Star(this.pos, this.r, this.phase);
}

class _Ridge {
  final ui.Color colorTop;
  final ui.Color colorBot;
  final double yRatio;
  final double amp;
  final double freq;
  final double speed;
  final double fogAlpha;
  double offset = 0;
  _Ridge({
    required this.colorTop,
    required this.colorBot,
    required this.yRatio,
    required this.amp,
    required this.freq,
    required this.speed,
    required this.fogAlpha,
  });
}
