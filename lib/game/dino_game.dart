import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';            // TapDownEvent
import 'package:flame/collisions.dart';

import '../components/sky.dart';
import '../components/parallax_bg.dart';
import '../components/clouds.dart';
import '../components/ground.dart';
import '../components/player.dart';
import '../components/rock.dart';
import '../components/score_text.dart';
import '../components/meteor.dart';
import '../components/ptero.dart';
import 'package:flutter/services.dart';




class DinoGame extends FlameGame
    with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  int score = 0;
  int hiScore = 0;

  final _worldW = 1080.0;
  final _worldH = 540.0;

  double _speed = 350; // world scroll speed
  double get speed => _speed;

  late Player player;
  double _rockTimer = 0;
  double _bgMeteorTimer = 0;
  double _hazardMeteorTimer = 2.5;
  double _pteroTimer = 4;
  bool _running = false;

  @override
  Future<void> onLoad() async {
    // Flame 1.32.x
camera.viewfinder.visibleGameSize = Vector2(_worldW, _worldH);
camera.viewfinder.position = Vector2(_worldW / 2, _worldH / 2);
    // Far -> near
    add(Sky(priority: 0));
    add(ParallaxBg(priority: 1)); // mountains/volcano
    add(Clouds(priority: 2));
    add(Ground(priority: 3));

    player = Player(priority: 5);
    add(player);

    add(ScoreText(priority: 20)..position = Vector2(10, 10));

    overlays.add('Start');
  }

  // Overlays call these:
  void start() {
    if (_running) return;
    overlays.remove('Start');
    _running = true;
    _speed = 350;
    score = 0;
    _rockTimer = 0;
    _bgMeteorTimer = 0;
    _hazardMeteorTimer = 2.5;
    _pteroTimer = 4;
    children.whereType<Rock>().toList().forEach(remove);
    children.whereType<Meteor>().toList().forEach(remove);
    children.whereType<Ptero>().toList().forEach(remove);
    player.reset();
  }

  void resetGame() {
    _running = false;
    if (score > hiScore) hiScore = score;
    overlays.add('Start');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_running) return;

    score += (60 * dt).toInt();
    _speed += 0.5 * dt * 60; // gentle ramp

    // Rocks
    _rockTimer -= dt;
    if (_rockTimer <= 0) {
      add(Rock(speedProvider: () => speed, priority: 6));
      _rockTimer = 1.1 + (0.9) * (1 / (1 + score / 700));
    }

    // Background meteors (no collision, just ambiance)
    _bgMeteorTimer -= dt;
    if (_bgMeteorTimer <= 0) {
      add(Meteor(background: true, priority: 2));
      _bgMeteorTimer = 2.5 + (rand.nextDouble() * 2.5);
    }

    // Occasionally hazardous meteor (collides)
    _hazardMeteorTimer -= dt;
    if (_hazardMeteorTimer <= 0) {
      add(Meteor(background: false, priority: 6)); // colliding
      _hazardMeteorTimer = 6 + rand.nextDouble() * 4;
    }

    // Ptero (flies head height)
    _pteroTimer -= dt;
    if (_pteroTimer <= 0) {
      add(Ptero(speedProvider: () => speed * 0.8, priority: 6));
      _pteroTimer = 7 + rand.nextDouble() * 6;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_running) player.jump();
    super.onTapDown(event);
  }

@override
KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
  if (event is KeyDownEvent) {
    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_running) player.jump();
      return KeyEventResult.handled;
    }
  }
  return KeyEventResult.ignored;
}




  void gameOver() {
    _running = false;
    if (score > hiScore) hiScore = score;
    overlays.add('GameOver');
  }
}
