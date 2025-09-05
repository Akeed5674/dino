import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';

class Rock extends SpriteComponent
    with HasGameRef<DinoGame>, CollisionCallbacks {
  final double Function() speedProvider;

  Rock({required this.speedProvider, int priority = 0})
      : super(size: Vector2(56, 40), anchor: Anchor.bottomLeft, priority: priority);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('images/rock.png');
    final groundY = gameRef.size.y - 80;
    position = Vector2(gameRef.size.x + width + 20, groundY);
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    x -= speedProvider() * dt;
    if (x < -width - 50) {
      removeFromParent();
      gameRef.score += 1;
    }
  }
}
