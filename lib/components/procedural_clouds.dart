import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Painterly cumulus clouds that fade in only in the "morning" window.
/// Morning = timeOfDay in [0.10, 0.35] (t ∈ 0..1 across a full day).
class ProceduralClouds extends Component with HasGameRef {
  final Random _random = Random();
  final List<_Cloud> _clouds = [];

  /// Supply a time-of-day provider that returns t in [0,1).
  /// If null, clouds assume it's always morning (visible).
  final double Function()? timeProvider;

  ProceduralClouds({this.timeProvider, int priority = 0}) : super(priority: priority);

  // Config
  static const int cloudCount = 5;
  static const double morningStart = 0.10;
  static const double morningEnd = 0.35;

  @override
  Future<void> onLoad() async {
    final size = gameRef.size;
    for (var i = 0; i < cloudCount; i++) {
      _clouds.add(
        _Cloud(
          position: Vector2(
            _random.nextDouble() * size.x * 1.5,
            size.y * (0.10 + _random.nextDouble() * 0.18),
          ),
          gameSize: size,
          scale: 0.9 + _random.nextDouble() * 0.6,
          speed: 12 + _random.nextDouble() * 18,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    for (final c in _clouds) {
      c.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    // Morning-only visibility with smooth fade at edges.
    final t = timeProvider?.call() ?? 0.2; // default: visible (morning)
    double vis;
    if (t < morningStart || t > morningEnd) {
      // fade in/out near the window edges
      final edge = 0.04; // seconds of softness (fraction of day)
      if (t >= morningStart - edge && t < morningStart) {
        vis = ((t - (morningStart - edge)) / edge).clamp(0.0, 1.0);
      } else if (t > morningEnd && t <= morningEnd + edge) {
        vis = (1 - (t - morningEnd) / edge).clamp(0.0, 1.0);
      } else {
        vis = 0.0;
      }
    } else {
      vis = 1.0;
    }
    if (vis <= 0) return;

    // Draw with overall alpha multiplier
    canvas.saveLayer(null, Paint());
    for (final c in _clouds) {
      c.render(canvas, opacity: vis);
    }
    canvas.restore();
  }
}

class _Cloud {
  final Vector2 gameSize;
  Vector2 position;
  final double speed;
  final double scale;
  final List<_Puff> _puffs = [];
  final Random _rng = Random();

  _Cloud({
    required this.position,
    required this.gameSize,
    required this.scale,
    required double speed,
  }) : speed = speed {
    // Build a big cumulus—clustered puffs with soft gradients.
    final count = 5 + _rng.nextInt(4);
    for (var i = 0; i < count; i++) {
      final dx = (i - (count - 1) / 2) * 42.0 + (_rng.nextDouble() * 18 - 9);
      final dy = (_rng.nextDouble() * 16 - 10) - (i == 0 ? 4 : 0);
      final r = (34 + _rng.nextDouble() * 34) * (i == 0 ? 1.25 : 1.0);
      _puffs.add(_Puff(offset: Vector2(dx, dy), radius: r));
    }
  }

  void update(double dt) {
    position.x -= speed * dt;
    if (position.x < -260) {
      position
        ..x = gameSize.x + 260
        ..y = gameSize.y * (0.10 + _rng.nextDouble() * 0.18);
    }
  }

  void render(Canvas canvas, {required double opacity}) {
    for (final p in _puffs) {
      p.render(canvas, cloudPos: position, scale: scale, opacity: opacity);
    }
  }
}

class _Puff {
  final Vector2 offset;
  final double radius;

  _Puff({required this.offset, required this.radius});

  void render(Canvas canvas,
      {required Vector2 cloudPos, required double scale, required double opacity}) {
    final center = (cloudPos + offset * scale).toOffset();
    final r = radius * scale;

    // Base body (cool white)
    final base = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18)
      ..shader = ui.Gradient.radial(
        center,
        r * 1.15,
        [
          const Color(0xFFFFFFFF).withOpacity(0.85 * opacity),
          const Color(0xFFDEE9FF).withOpacity(0.00),
        ],
        const [0.0, 1.0],
      );
    canvas.drawCircle(center, r, base);

    // Warm highlight (top-left side)
    final highlight = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..shader = ui.Gradient.radial(
        Offset(center.dx - r * 0.35, center.dy - r * 0.35),
        r * 0.9,
        [
          const Color(0xFFFFF1E6).withOpacity(0.70 * opacity),
          const Color(0x00FFFFFF),
        ],
        const [0.0, 1.0],
      );
    canvas.drawCircle(center, r * 0.92, highlight);

    // Subtle shadow/base tint (gives the painterly volume)
    final shadow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..shader = ui.Gradient.radial(
        Offset(center.dx + r * 0.25, center.dy + r * 0.15),
        r * 1.1,
        [
          const Color(0xFF9FB5D6).withOpacity(0.25 * opacity),
          const Color(0x00000000),
        ],
        const [0.0, 1.0],
      );
    canvas.drawCircle(center, r, shadow);
  }
}
