import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';

class Sky extends Component with HasGameRef {
  Sky({int priority = 0}) : super(priority: priority);

  late final _SkyBg _bg;
  double _t = 0;

  @override
  Future<void> onLoad() async {
    _bg = _SkyBg(size: gameRef.size);
    add(_bg);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt * 0.02; // slow day/night drift
    _bg.setPhase(_t % (2 * math.pi));
  }
}

class _SkyBg extends PositionComponent {
  _SkyBg({required Vector2 size}) {
    this.size = size;
  }

  double _phase = 0;
  void setPhase(double p) => _phase = p;

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    final dayTop = const ui.Color(0xFF6CA1D0);
    final dayBottom = const ui.Color(0xFFB3E5FC);
    final nightTop = const ui.Color(0xFF0A1430);
    final nightBottom = const ui.Color(0xFF2C3E50);

    final nightness = 0.5 + 0.5 * (1 - math.cos(_phase));
    final top = ui.Color.lerp(dayTop, nightTop, nightness)!;
    final bottom = ui.Color.lerp(dayBottom, nightBottom, nightness)!;

    final rect = ui.Offset.zero & size.toSize();
    final paint = ui.Paint()
      ..shader =
          ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [top, bottom]);
    canvas.drawRect(rect, paint);
  }
}
