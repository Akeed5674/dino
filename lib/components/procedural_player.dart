import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';

import '../components/procedural_rock.dart';
import '../game/dino_game.dart'; // so we can call gameRef.gameOver()

const double kBaselineRatio = 0.906;

class ProceduralPlayer extends PositionComponent
    with HasGameRef<DinoGame>, CollisionCallbacks {
  ProceduralPlayer({int priority = 0}) : super(priority: priority);

  late final SpriteAnimationComponent _anim;

  double _vy = 0.0;
  static const double _jumpV = -600;
  static const double _gravity = 1650;

  bool _ducking = false;
  double get _baseline => gameRef.size.y * kBaselineRatio + 1;
  static const double _x = 120;

  double _t = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final frames = <Sprite>[];
    for (int i = 0; i < 6; i++) {
      frames.add(await _ninjaFrame(i));
    }

    _anim = SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(frames, stepTime: 0.1),
      size: Vector2(54, 64),
      anchor: Anchor.bottomLeft,
      priority: priority,
    );

    add(_anim);

    // Player hitbox
    add(RectangleHitbox(
      position: Vector2(8, -58),
      size: Vector2(34, 56),
    ));

    reset();
  }

  @override
  void onGameResize(Vector2 s) {
    super.onGameResize(s);
    position = Vector2(_x, _baseline);
  }

  // 6 frames: 0=plant R, 1=drive R, 2=pass, 3=plant L, 4=drive L, 5=pass
  Future<Sprite> _ninjaFrame(int phase) async {
    const w = 54.0, h = 64.0;
    final rec = ui.PictureRecorder();
    final c = ui.Canvas(rec);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = const ui.Color(0x00000000));

    const skin = ui.Color(0xFFF2C9A1);
    const suit = ui.Color(0xFF0F1116);
    const suit2 = ui.Color(0xFF0B0D12);
    const band = ui.Color(0xFFEAEFFB);
    const sword = ui.Color(0xFFB9C4D6);
    const swordGrip = ui.Color(0xFF272B37);

    // torso & head
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(19, 20, 22, 28), const ui.Radius.circular(6)),
      ui.Paint()..color = suit,
    );
    c.drawCircle(const ui.Offset(30, 12), 11, ui.Paint()..color = suit);
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(23, 8.5, 14, 7.5), const ui.Radius.circular(3)),
      ui.Paint()..color = skin,
    );
    c.drawCircle(const ui.Offset(27, 12), 1.7, ui.Paint());
    c.drawCircle(const ui.Offset(33, 12), 1.7, ui.Paint());
    c.drawRect(const ui.Rect.fromLTWH(22, 6, 18, 3), ui.Paint()..color = band);
    final tail = ui.Path()
      ..moveTo(22, 7.5)
      ..lineTo(13.5, 3.5)
      ..lineTo(16.5, 10)
      ..close();
    c.drawPath(tail, ui.Paint()..color = band);

    // katana
    final blade = ui.Paint()
      ..color = sword
      ..strokeWidth = 3
      ..strokeCap = ui.StrokeCap.round;
    c.drawLine(const ui.Offset(19, 28), const ui.Offset(6, 14), blade);
    c.drawRRect(
      ui.RRect.fromRectAndRadius(
          const ui.Rect.fromLTWH(17.5, 28, 6.5, 3), const ui.Radius.circular(1.2)),
      ui.Paint()..color = swordGrip,
    );

    // helper
    void limb(ui.Offset pivot, double angleDeg, double len, double thick) {
      c.save();
      c.translate(pivot.dx, pivot.dy);
      c.rotate(angleDeg * pi / 180);
      c.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(0, -thick / 2, len, thick),
          ui.Radius.circular(thick / 2),
        ),
        ui.Paint()..color = suit2,
      );
      c.restore();
    }

    // Angles for a real stride (plant/pass), plus a FLAT planted foot
    final i = phase % 6;
    double armA, armB, thighR, thighL;
    double footFlatX = 0, footFlatW = 0;
    switch (i) {
      case 0: // plant R
        armA = -22; armB = 22;
        thighR = 12; thighL = -28;
        footFlatX = 22; footFlatW = 14;
        break;
      case 1: // drive R
        armA = -12; armB = 12;
        thighR = 4; thighL = -16;
        break;
      case 2: // pass
        armA = 0; armB = 0;
        thighR = -4; thighL = 4;
        break;
      case 3: // plant L
        armA = 22; armB = -22;
        thighR = -28; thighL = 12;
        footFlatX = 34; footFlatW = 14;
        break;
      case 4: // drive L
        armA = 12; armB = -12;
        thighR = -16; thighL = 4;
        break;
      default: // pass
        armA = 0; armB = 0;
        thighR = 4; thighL = -4;
    }

    // arms
    limb(const ui.Offset(30, 28), armA, 16, 6);
    limb(const ui.Offset(30, 28), armB, 16, 6);

    // legs
    limb(const ui.Offset(30, 46), thighR, 20, 7);
    limb(const ui.Offset(30, 46), thighL, 20, 7);

    // planted foot touches sprite bottom exactly
    if (footFlatW > 0) {
      c.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromLTWH(footFlatX, h - 5.0, footFlatW, 3.5),
          const ui.Radius.circular(2),
        ),
        ui.Paint()..color = suit2,
      );
    }

    final img = (rec.endRecording()).toImageSync(w.toInt(), h.toInt());
    return Sprite(img);
  }

  // collisions → game over
  @override
  void onCollisionStart(Set<Vector2> _, PositionComponent other) {
    super.onCollisionStart(_, other);
    if (other is ProceduralRock) {
      gameRef.gameOver(); // call your DinoGame.gameOver()
    }
  }

  void reset() {
    _vy = 0;
    _ducking = false;
    _t = 0;
    position = Vector2(_x, _baseline); // feet on ground
    _anim
      ..position = Vector2.zero()
      ..scale = Vector2(1, 1);
  }

  void jump() {
    if (y >= _baseline - 0.5) _vy = _jumpV;
  }

  void duck(bool v) {
    _ducking = v;
    _anim.scale = v ? Vector2(1.0, 0.84) : Vector2(1.0, 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final baseline = _baseline;

    // gravity
    _vy += _gravity * dt;
    var newY = y + _vy * dt;
    if (newY > baseline) { newY = baseline; _vy = 0; }

    // small bob INSIDE the sprite so feet stay on the baseline
    _t += dt;
    final bob = (!_ducking && (newY >= baseline - 0.5)) ? (sin(_t * 9.5) * 1.2) : 0.0;
    y = newY;             // component sits on baseline
    _anim.y = -bob;       // visual bob only
  }
}
