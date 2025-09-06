import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

// keep in sync with ground:
const double kBaselineRatio = 0.906;

class ProceduralRock extends PositionComponent
    with HasGameRef<FlameGame>, CollisionCallbacks {
  final double Function() speedProvider;

  final _rand = Random();
  late final ui.Path _canopyPath;
  late final ui.Path _trunkPath;

  static const ui.Color _trunkColor = ui.Color(0xFF111418);
  static const ui.Color _canopyColor = ui.Color(0xFF161B22);

  ProceduralRock({
    required this.speedProvider,
    int priority = 0,
  }) : super(
          size: Vector2(56 + Random().nextDouble() * 20,
              80 + Random().nextDouble() * 24),
          anchor: Anchor.bottomCenter,
          priority: priority,
        );


  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _placeOnBaseline();
    _buildShape();

    add(RectangleHitbox(
      // fair hitbox
      position: Vector2(-size.x * 0.18, -size.y * 0.90),
      size: Vector2(size.x * 0.36, size.y * 0.88),
    ));
  }

  void _placeOnBaseline() {
    final baselineY = gameRef.size.y * kBaselineRatio + 1;
    position = Vector2(gameRef.size.x + width, baselineY);
  }

  void _buildShape() {
    final trunkW = size.x * 0.16;
    final trunkH = size.y * 0.62;
    final trunkLeft = -trunkW / 2 + (_rand.nextDouble() - 0.5) * 4.0;
    final trunkTop = -trunkH;

    final trunkRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(trunkLeft, trunkTop, trunkW, trunkH),
      const ui.Radius.circular(7),
    );

    final trunk = ui.Path()..addRRect(trunkRect);
    trunk
      ..moveTo(trunkLeft + trunkW * 0.55, trunkTop + trunkH * 0.28)
      ..cubicTo(
        trunkLeft + trunkW * 1.4, trunkTop + trunkH * 0.10,
        trunkLeft + trunkW * 0.2, trunkTop + trunkH * 0.55,
        trunkLeft + trunkW * 0.75, trunkTop + trunkH * 0.98,
      );
    _trunkPath = trunk;

    final canopyR = size.x * (0.28 + _rand.nextDouble() * 0.06);
    final centerY = trunkTop - size.y * 0.06;
    final p = ui.Path()
      ..addRRect(ui.RRect.fromRectAndRadius(
          ui.Rect.fromCircle(center: ui.Offset(0, centerY), radius: canopyR),
          const ui.Radius.circular(16)))
      ..addRRect(ui.RRect.fromRectAndRadius(
          ui.Rect.fromCircle(
              center: ui.Offset(-canopyR * 0.7, centerY + canopyR * 0.05),
              radius: canopyR),
          const ui.Radius.circular(16)))
      ..addRRect(ui.RRect.fromRectAndRadius(
          ui.Rect.fromCircle(
              center: ui.Offset(canopyR * 0.65, centerY + canopyR * 0.10),
              radius: canopyR),
          const ui.Radius.circular(16)));
    _canopyPath = p;
  }

  @override
  void update(double dt) {
    super.update(dt);
    y = gameRef.size.y * kBaselineRatio + 1; // stay glued to ground
    x -= speedProvider() * dt;
    if (x < -width - 50) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    canvas.drawPath(_trunkPath, ui.Paint()..color = _trunkColor);
    canvas.drawPath(_canopyPath, ui.Paint()..color = _canopyColor);
  }
}
