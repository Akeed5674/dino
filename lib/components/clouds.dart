import 'dart:ui' as ui;
import 'package:flame/components.dart';

class Clouds extends Component with HasGameRef {
  Clouds({int priority = 0}) : super(priority: priority);

  @override
  Future<void> onLoad() async {
    Future<SpriteComponent> cloud(Vector2 pos, double scale, double opacity) async {
      final sprite = await Sprite.load('images/clouds.png'); // transparent
      final c = SpriteComponent(
        sprite: sprite,
        size: Vector2(220, 130) * scale,
        position: pos,
        anchor: Anchor.centerLeft,
        priority: priority,
      );
      c.paint = ui.Paint()..color = const ui.Color(0xFFFFFFFF).withOpacity(opacity);
      return c;
    }

    add(await cloud(Vector2(gameRef.size.x * 0.08, gameRef.size.y * 0.18), 1.1, 0.85));
    add(await cloud(Vector2(gameRef.size.x * 0.50, gameRef.size.y * 0.12), 1.2, 0.80));
    add(await cloud(Vector2(gameRef.size.x * 0.78, gameRef.size.y * 0.22), 0.9, 0.90));
  }

  @override
  void update(double dt) {
    for (final c in children.whereType<SpriteComponent>()) {
      c.x -= 18 * dt;
      if (c.x + c.width < 0) c.x = gameRef.size.x;
    }
  }
}
