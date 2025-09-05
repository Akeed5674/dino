import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/dino_game.dart';

final rand = Random();

class Meteor extends SpriteComponent
    with HasGameRef<DinoGame>, CollisionCallbacks {
  final bool background; // true = no collision, scenic

  Meteor({required this.background, int priority = 0})
      : super(size: Vector2(56, 56), anchor: Anchor.center, priority: priority);

  late final double _vx;
  late final double _vy;
  double _rotV = 0;

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('images/meteor.png');

    // Start near top-right with some variance
    final startX = gameRef.size.x + 40 + rand.nextDouble() * 120;
    final startY = 30 + rand.nextDouble() * (gameRef.size.y * 0.45);
    position = Vector2(startX, startY);

    // Diagonal down-left
    final base = background ? 140.0 : 220.0;
    _vx = -base - rand.nextDouble() * 120;
    _vy = 120 + rand.nextDouble() * 160;
    _rotV = (-1 + rand.nextDouble() * 2) * 1.8;

    if (!background) {
      // Only hazardous meteors collide
      add(CircleHitbox(radius: width * .45)..collisionType = CollisionType.passive);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    x += _vx * dt;
    y += _vy * dt;
    angle += _rotV * dt;

    // remove off screen
    if (x < -100 || y > gameRef.size.y + 100) {
      removeFromParent();
    }
  }

  // Damage player only if not background
  @override
  void onCollision(Set<Vector2> _, PositionComponent other) {
    if (!background && other is SpriteComponent && other is! Meteor) {
      gameRef.gameOver();
    }
    super.onCollision(_, other);
  }
}
