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
          'Start': (context, _) => _CenterOverlay(
                child: ElevatedButton(
                  onPressed: () => game.start(),
                  child: const Text('Start'),
                ),
              ),
          'GameOver': (context, _) => _CenterOverlay(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Game Over\nScore: ${game.score}\nBest: ${game.hiScore}',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => game.resetGame(),
                    child: const Text('Restart'),
                  ),
                ]),
              ),
        },
        initialActiveOverlays: const ['Start'],
      ),
    ),
  );
}

class _CenterOverlay extends StatelessWidget {
  final Widget child;
  const _CenterOverlay({required this.child, super.key});
  @override
  Widget build(BuildContext context) =>
      Container(color: Colors.black.withOpacity(.28), child: Center(child: child));
}
