import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';
import 'rock.dart';

class Player extends SpriteComponent
    with HasGameRef<DinoGame>, CollisionCallbacks {
  Player({int priority = 0})
      : super(size: Vector2(64, 64), anchor: Anchor.bottomLeft, priority: priority);

  final double _gravity = 1600;
  final double _jumpV = -620;
  double _vy = 0;
  late double _groundY;
  bool _alive = true;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('images/dino.png');
    _groundY = gameRef.size.y - 80;
    position = Vector2(80, _groundY);
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  void reset() {
    _alive = true;
    _vy = 0;
    position = Vector2(80, _groundY);
  }

  void jump() {
    if (!_alive) return;
    if (y >= _groundY - 1) _vy = _jumpV;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_alive) return;
    _vy += _gravity * dt;
    y += _vy * dt;
    if (y > _groundY) {
      y = _groundY;
      _vy = 0;
    }
  }

  @override
  void onCollision(Set<Vector2> _, PositionComponent other) {
    if (other is Rock && _alive) {
      _alive = false;
      gameRef.gameOver();
    }
    super.onCollision(_, other);
  }
}
