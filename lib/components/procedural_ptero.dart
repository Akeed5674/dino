import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class ProceduralPtero extends PositionComponent with HasGameRef {
  final double Function() speedProvider;
  final Paint _paint = Paint()..color = const Color(0xFF212121);
  double _wingFlap = 0;
  final double _wingSpeed = 8;

  ProceduralPtero({required this.speedProvider, int priority = 0})
      : super(
            size: Vector2(80, 50),
            anchor: Anchor.center,
            priority: priority);

  @override
  Future<void> onLoad() async {
    final yLane = gameRef.size.y - 120 - Random().nextDouble() * 100;
    position = Vector2(gameRef.size.x + width, yLane);
    add(RectangleHitbox(size: size * 0.9));
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= speedProvider() * dt;
    if (x < -width) removeFromParent();

    _wingFlap += _wingSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final wingY = sin(_wingFlap) * (size.y / 2.5);

    final body = Path()
      ..moveTo(size.x * 0.2, size.y / 2)
      ..lineTo(size.x, size.y * 0.4)
      ..lineTo(size.x * 0.9, size.y * 0.6)
      ..close();

    final wing = Path()
      ..moveTo(size.x * 0.2, size.y / 2)
      ..quadraticBezierTo(size.x * 0.5, size.y / 2 - wingY, size.x * 0.8, size.y / 2)
      ..quadraticBezierTo(size.x * 0.5, size.y / 2 + wingY, size.x * 0.2, size.y/2)
      ..close();
      
    canvas.drawPath(wing, _paint);
    canvas.drawPath(body, _paint);
  }
}

