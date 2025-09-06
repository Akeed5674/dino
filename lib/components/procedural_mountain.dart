import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Night scene with layered snowy mountains:
/// - Sky gradient + moon halo + twinkling stars
/// - Three jagged mountain ranges (far -> near) with vertical color gradients
/// - Snow caps with subtle left/right shading
/// - Valley fog bands + base vignette for smooth blending
class ProceduralMountain extends PositionComponent with HasGameRef<FlameGame> {
  ProceduralMountain({int priority = 0}) : super(priority: priority);

  final Random _rnd = Random(42);
  final List<ui.Offset> _stars = [];
  final List<double> _starR = [];
  double _t = 0;

  @override
  Future<void> onLoad() async {
    size = gameRef.size;

    // Stable star field
    for (int i = 0; i < 130; i++) {
      final x = _rnd.nextDouble() * size.x;
      final y = _rnd.nextDouble() * size.y * 0.55;
      _stars.add(ui.Offset(x, y));
      _starR.add(0.6 + _rnd.nextDouble() * 1.1);
    }
  }

  @override
  void update(double dt) {
    _t += dt;
  }

  @override
  void render(ui.Canvas c) {
    final w = size.x, h = size.y;

    // ---- Sky gradient ----
    c.drawRect(
      ui.Rect.fromLTWH(0, 0, w, h),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(0, 0),
          ui.Offset(0, h),
          const [
            ui.Color(0xFF0C1022),
            ui.Color(0xFF121C3D),
            ui.Color(0xFF1C2A58),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );

    // ---- Moon + halo (top-right) ----
    final moon = ui.Offset(w * 0.82, h * 0.18);
    final rMoon = h * 0.09;
    c.drawCircle(moon, rMoon, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    c.drawCircle(
      moon,
      rMoon * 2.8,
      ui.Paint()
        ..blendMode = ui.BlendMode.plus
        ..shader = ui.Gradient.radial(
          moon,
          rMoon * 2.8,
          const [ui.Color(0x66FFFFFF), ui.Color(0x00000000)],
          const [0.0, 1.0],
        ),
    );

    // ---- Stars (twinkle + glow) ----
    final starCore = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    final starGlow = ui.Paint()
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.2);
    for (int i = 0; i < _stars.length; i++) {
      final p = _stars[i];
      final r0 = _starR[i];
      final tw = 0.72 + 0.28 * (0.5 + 0.5 * sin(_t * (1.2 + r0 * 0.25) + i));
      final r = r0 * tw;
      c.drawCircle(p, r * 1.7, starGlow..color = const ui.Color(0x55FFFFFF));
      c.drawCircle(p, r, starCore);
    }

    // ---- Layered snowy mountains (far -> near) ----
    _drawRange(
      c,
      w: w,
      h: h,
      baseY: h * 0.66,
      height: h * 0.34,
      peaks: 6,
      seed: 11,
      top: const ui.Color(0xFF3D5E91).withOpacity(0.50),
      bot: const ui.Color(0xFF20355B).withOpacity(0.50),
      snowLight: const ui.Color(0xFFEFF4FF).withOpacity(0.70),
      snowShade: const ui.Color(0xFFC9D2F3).withOpacity(0.60),
      snowScale: 0.65,
      lightOnRight: true,
    );

    _drawRange(
      c,
      w: w,
      h: h,
      baseY: h * 0.76,
      height: h * 0.46,
      peaks: 5,
      seed: 21,
      top: const ui.Color(0xFF2F4F80).withOpacity(0.75),
      bot: const ui.Color(0xFF182B4F).withOpacity(0.75),
      snowLight: const ui.Color(0xFFEFF4FF).withOpacity(0.85),
      snowShade: const ui.Color(0xFFC9D2F3).withOpacity(0.72),
      snowScale: 0.85,
      lightOnRight: true,
    );

    _drawRange(
      c,
      w: w,
      h: h,
      baseY: h * 0.88,
      height: h * 0.56,
      peaks: 4,
      seed: 31,
      top: const ui.Color(0xFF24426F).withOpacity(0.95),
      bot: const ui.Color(0xFF0F213D).withOpacity(0.95),
      snowLight: const ui.Color(0xFFF7FAFF),
      snowShade: const ui.Color(0xFFDAE3FF),
      snowScale: 1.00,
      lightOnRight: true,
    );

    // ---- Valley fog bands ----
    _fogBand(c, y: h * 0.74, thickness: h * 0.07, alpha: 0.10);
    _fogBand(c, y: h * 0.83, thickness: h * 0.08, alpha: 0.12);
    _fogBand(c, y: h * 0.92, thickness: h * 0.10, alpha: 0.15);

    // ---- Bottom vignette ----
    c.drawRect(
      ui.Rect.fromLTWH(0, h * 0.92, w, h * 0.08),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, h * 0.92),
          ui.Offset(0, h),
          const [ui.Color(0x00FFFFFF), ui.Color(0x22000000)],
        ),
    );
  }

  // ================= helpers =================

  void _drawRange(
    ui.Canvas c, {
    required double w,
    required double h,
    required double baseY,
    required double height,
    required int peaks,
    required int seed,
    required ui.Color top,
    required ui.Color bot,
    required ui.Color snowLight,
    required ui.Color snowShade,
    required double snowScale,
    required bool lightOnRight,
  }) {
    final rng = Random(seed);
    final List<ui.Offset> ridge = [];

    // Build jagged ridge with randomness
    final spacing = w / (peaks + 1);
    for (int i = 0; i <= peaks + 1; i++) {
      final jitterX = (i.isEven ? 1.0 : -1.0) * (18 + rng.nextDouble() * 26);
      final px = (i * spacing + jitterX).clamp(0.0, w).toDouble();
      final ph = height * (0.55 + rng.nextDouble() * 0.45);
      final py = (baseY - ph).toDouble();
      ridge.add(ui.Offset(px, py));
    }

    // Body path
    final path = ui.Path()..moveTo(0, baseY);
    for (final p in ridge) {
      path.lineTo(p.dx, p.dy);
    }
    path
      ..lineTo(w, baseY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    // Vertical gradient for body
    final paint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, baseY - height),
        ui.Offset(0, baseY),
        [top, bot],
        const [0.0, 1.0],
      );
    c.drawPath(path, paint);

    // Snow caps on ridge vertices
    for (int i = 1; i < ridge.length - 1; i++) {
      final tip = ridge[i];
      final capW = 24.0 * snowScale * (0.85 + rng.nextDouble() * 0.4);
      final capH = 36.0 * snowScale * (0.85 + rng.nextDouble() * 0.4);

      final left = ui.Offset(tip.dx - capW, tip.dy + capH * 0.5);
      final right = ui.Offset(tip.dx + capW, tip.dy + capH * 0.5);

      final snow = ui.Path()
        ..moveTo(left.dx, left.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(right.dx, right.dy)
        ..close();

      final shader = ui.Gradient.linear(
        ui.Offset(tip.dx - capW, tip.dy),
        ui.Offset(tip.dx + capW, tip.dy + capH * 0.8),
        lightOnRight
            ? [snowShade, snowLight]
            : [snowLight, snowShade],
        const [0.0, 1.0],
      );
      c.drawPath(snow, ui.Paint()..shader = shader);
    }
  }

  void _fogBand(
    ui.Canvas c, {
    required double y,
    required double thickness,
    required double alpha,
  }) {
    final rect = ui.Rect.fromLTWH(0, y - thickness * 0.5, size.x, thickness);
    c.drawRect(
      rect,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, rect.top),
          ui.Offset(0, rect.bottom),
          [
            const ui.Color(0x00FFFFFF),
            ui.Color(0x33FFFFFF).withOpacity(alpha),
            const ui.Color(0x00FFFFFF),
          ],
          const [0.0, 0.6, 1.0],
        ),
    );
  }
}
