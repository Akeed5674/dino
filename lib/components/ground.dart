import 'dart:ui' as ui;
import 'package:flame/components.dart';

class Ground extends PositionComponent with HasGameRef {
  Ground({int priority = 0}) : super(priority: priority);

  late final Sprite _tile;
  double _x = 0;
  final double _h = 80;

  @override
  Future<void> onLoad() async {
    _tile = await Sprite.load('images/ground.png'); // transparent strip
    size = Vector2(gameRef.size.x, _h);
    position = Vector2(0, gameRef.size.y - _h);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _x = (_x - dt * 140) % _tile.srcSize.x;
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    double drawX = -_x;
    final dSize = Vector2(_tile.srcSize.x, _h);
    while (drawX < size.x) {
      _tile.render(canvas, position: Vector2(drawX, 0), size: dSize);
      drawX += dSize.x;
    }
  }
}
