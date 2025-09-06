import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

// Components you already have:
import '../components/procedural_ground.dart';
import '../components/procedural_meteor.dart';
import '../components/procedural_player.dart';
import '../components/procedural_ptero.dart';
import '../components/procedural_rock.dart';
import '../components/score_text.dart';

// NEW: our self-contained mountain background
import '../components/procedural_mountain.dart';

class DinoGame extends FlameGame
    with TapCallbacks, KeyboardEvents, HasCollisionDetection {
  // -------- World / camera --------
  final double _worldW = 1080.0;
  final double _worldH = 540.0;

  // -------- Game state --------
  int score = 0;
  int hiScore = 0;
  bool _running = false;

  // Speed (used by ground & difficulty ramp)
  double _speed = 300;
  double get speed => _speed;

  // Player
  late ProceduralPlayer player;

  // Spawners (rocks & ptero use simple timers)
  final Random rand = Random();
  double _rockTimer = 2.0;
  double _pteroTimer = 5.0;

  // ONE-meteor spawner (TimerComponent – no extra update needed)
  final Random _rng = Random();
  late TimerComponent _meteorTimer; // foreground only, one at a time
  int get _activeMeteors =>
      children.whereType<ProceduralMeteor>().where((m) => !m.background).length;

  @override
  Future<void> onLoad() async {
    // Camera/world setup
    camera.viewfinder.visibleGameSize = Vector2(_worldW, _worldH);
    camera.viewfinder.position = Vector2(_worldW / 2, _worldH / 2);

    // 0) Background mountains (draws sky+moon+stars+mountains as one)
    add(ProceduralMountain(priority: 0));

    // 1) Ground
    add(ProceduralGround(
      scrollSpeedProvider: () => speed,
      priority: 2,
    ));

    // 2) Player + UI
    player = ProceduralPlayer(priority: 5);
    add(player);
    add(ScoreText(priority: 20)..position = Vector2(20, 20));

    // 3) Foreground meteor timer (ONE at a time, 2.0..3.5s)
    _meteorTimer = TimerComponent(
      period: 2.0,
      repeat: true,
      onTick: () {
        if (!_running) return;
        if (_activeMeteors == 0) {
          add(ProceduralMeteor(
            background: false,
            priority: 1500, // ensure it renders over mountains
          ));
        }
        _meteorTimer.timer.limit = 2.0 + _rng.nextDouble() * 1.5; // 2..3.5s
      },
    );
    add(_meteorTimer);

    // Show start overlay until the first tap/space
    overlays.add('Start');
  }

  // -------- Game lifecycle --------
  void start() {
    if (_running) return;

    overlays.remove('Start');
    _running = true;
    _speed = 300;
    score = 0;

    // Reset spawn timers with some randomness
    _rockTimer = 2.0 + rand.nextDouble() * 2.0;
    _pteroTimer = 5.0 + rand.nextDouble() * 4.0;

    // Clear existing foreground hazards
    children.whereType<ProceduralRock>().toList().forEach(remove);
    children.whereType<ProceduralPtero>().toList().forEach(remove);
    children
        .whereType<ProceduralMeteor>()
        .where((m) => !m.background)
        .toList()
        .forEach(remove);

    player.reset();
  }

  void resetGame() {
    start();
    overlays.remove('GameOver');
  }

  void gameOver() {
    _running = false;
    if (score > hiScore) hiScore = score;
    overlays.add('GameOver');
  }

  // -------- Single update() --------
  @override
  void update(double dt) {
    super.update(dt);
    if (!_running) return;

    // Score & speed progression
    score += (60 * dt).toInt();
    _speed += 0.25 * dt * 60;

    // Rocks (ground obstacles)
    _rockTimer -= dt;
    if (_rockTimer <= 0) {
      add(ProceduralRock(speedProvider: () => speed, priority: 6));
      _rockTimer = 1.2 + rand.nextDouble() * 1.8 * (400 / _speed);
    }

    // Pterodactyl (air obstacle) after some score
    if (score > 500) {
      _pteroTimer -= dt;
      if (_pteroTimer <= 0) {
        add(ProceduralPtero(speedProvider: () => speed * 1.1, priority: 6));
        _pteroTimer = 3.0 + rand.nextDouble() * 4.0 * (400 / _speed);
      }
    }
  }

  // -------- Input --------
  @override
  void onTapDown(TapDownEvent event) {
    if (!_running) {
      start();
    } else {
      player.jump();
    }
    super.onTapDown(event);
  }

  // Linux embedder sometimes delivers invalid key events (logical/physical 0)
  // This guard avoids those assertion crashes.
  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keys) {
    // Ignore malformed key events (common on Linux with IME/compose keys)
    if (event.logicalKey.keyLabel.isEmpty &&
        event.physicalKey.usbHidUsage == 0) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (!_running) {
          start();
        } else {
          player.jump();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        player.duck(true);
        return KeyEventResult.handled;
      }
    }
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        player.duck(false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
