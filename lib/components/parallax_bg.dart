import 'dart:ui' as ui;
import 'package:flame/components.dart';

class ParallaxBg extends Component with HasGameRef {
  ParallaxBg({int priority = 0}) : super(priority: priority);

  late final Sprite _mountains;
  late final Sprite _volcano;

  double _x1 = 0;
  double _x2 = 0;

  @override
  Future<void> onLoad() async {
    _mountains = await Sprite.load('images/mountains.png');
    _volcano   = await Sprite.load('images/volcano.png');
  }

  @override
  void update(double dt) {
    _x1 = (_x1 - dt * 20) % _mountains.srcSize.x; // far layer
    _x2 = (_x2 - dt * 35) % _volcano.srcSize.x;   // near layer
  }

  @override
  void render(ui.Canvas canvas) {
    final h = gameRef.size.y * 0.70;
    final y = gameRef.size.y - h - 80;

    void tile(Sprite s, double scrollX) {
      final dSize = Vector2(s.srcSize.x, h);
      double dx = -scrollX;
      while (dx < gameRef.size.x) {
        s.render(canvas, position: Vector2(dx, y), size: dSize);
        dx += dSize.x;
      }
    }

    tile(_mountains, _x1);
    tile(_volcano, _x2);
  }
}
