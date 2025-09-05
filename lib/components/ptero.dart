import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';

class Ptero extends SpriteComponent
    with HasGameRef<DinoGame>, CollisionCallbacks {
  final double Function() speedProvider;

  Ptero({required this.speedProvider, int priority = 0})
      : super(size: Vector2(64, 40), anchor: Anchor.centerLeft, priority: priority);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('images/ptero.png'); // transparent
    final yLane = gameRef.size.y - 80 - 40 - 20; // a bit above head
    position = Vector2(gameRef.size.x + width + 10, yLane);
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= speedProvider() * dt;
    if (x < -width - 40) removeFromParent();
  }
}
