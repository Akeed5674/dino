import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/dino_game.dart';

void main() {
  final game = DinoGame();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          'Start': (context, _) => _StyledOverlay(
                title: 'Dino Plus',
                subtitle: 'Tap or press Space to start',
                onPressed: () => game.start(),
                buttonText: 'Play',
              ),
          'GameOver': (context, _) => _StyledOverlay(
                title: 'Game Over',
                subtitle:
                    'Score: ${game.score}\nBest: ${game.hiScore}',
                onPressed: () => game.start(),
                buttonText: 'Restart',
              ),
        },
        initialActiveOverlays: const ['Start'],
      ),
    ),
  );
}

class _StyledOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final String buttonText;

  const _StyledOverlay({
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF465A70), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF51627E),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'Arial',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
