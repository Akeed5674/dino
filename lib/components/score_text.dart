import 'package:flame/components.dart';
import 'package:flutter/material.dart'; // <-- This import was missing
import '../game/dino_game.dart';

class ScoreText extends TextComponent with HasGameRef<DinoGame> {
  ScoreText({int priority = 0})
      : super(
          priority: priority,
          text: 'Score: 0',
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 3.0,
                  color: Colors.black,
                  offset: Offset(2.0, 2.0),
                ),
              ],
            ),
          ),
        );

  @override
  void update(double dt) {
    super.update(dt);
    text = 'Score: ${gameRef.score}';
  }
}

