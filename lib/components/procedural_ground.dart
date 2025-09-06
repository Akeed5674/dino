import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';

typedef ScrollSpeedProvider = double Function();

// ONE baseline used by everything:
const double kBaselineRatio = 0.906;

class ProceduralGround extends PositionComponent with HasGameRef<FlameGame> {
  final ScrollSpeedProvider scrollSpeedProvider;
  ProceduralGround({required this.scrollSpeedProvider, int priority = 0})
      : super(priority: priority);

  static const double bandHeight = 24;
  double _offset = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = gameRef.size;
    position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _offset = (_offset + scrollSpeedProvider() * dt) % size.x;
  }

  @override
  void render(ui.Canvas canvas) {
    final w = size.x;
    final baseY = size.y * kBaselineRatio; // shared!
    final k1 = 2 * pi / (w * 0.95);
    final k2 = 2 * pi / (w * 0.45);

    final top = ui.Path()..moveTo(0, baseY);
    for (double x = -w; x <= w * 2; x += 12) {
      final y = baseY +
          5 * sin(k1 * (x + _offset)) +
          3 * sin(k2 * (x * 1.2 + _offset * 1.3));
      top.lineTo(x, y);
    }
    final track = ui.Path.from(top)
      ..lineTo(size.x, baseY + bandHeight)
      ..lineTo(0, baseY + bandHeight)
      ..close();

    canvas.drawPath(track, ui.Paint()..color = const ui.Color(0xFF394156));
    final highlight = ui.Gradient.linear(
      ui.Offset(0, baseY),
      ui.Offset(0, baseY + bandHeight),
      const [ui.Color(0x66FFFFFF), ui.Color(0x00000000)],
      const [0.0, 1.0],
    );
    canvas.drawPath(track, ui.Paint()..shader = highlight);
  }
}
