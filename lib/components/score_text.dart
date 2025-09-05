import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../game/dino_game.dart';

class ScoreText extends TextComponent with HasGameRef<DinoGame> {
  ScoreText({int priority = 0})
      : super(
          priority: priority,
          text: '0',
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFF0E1726),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    text = '${gameRef.score}';
  }
}
