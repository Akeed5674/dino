import 'dart:math';

class Spawner {
  final void Function() onRock;
  final void Function() onPtero;
  final void Function() onMeteor;

  Spawner({required this.onRock, required this.onPtero, required this.onMeteor});

  final _rng = Random();
  double _cooldown = 0;

  void tick(double dt, int score, double speed) {
    _cooldown -= dt;
    if (_cooldown > 0) return;

    final allowPtero = score >= 250;
    final allowMeteor = score >= 550;
    final roll = _rng.nextDouble();

    if (allowMeteor && roll > 0.75) {
      onMeteor();
      _cooldown = 1.1 + _rng.nextDouble() * 0.7;
    } else if (allowPtero && roll > 0.45) {
      onPtero();
      _cooldown = 0.9 + _rng.nextDouble() * 0.6;
    } else {
      onRock();
      _cooldown = 0.8 + _rng.nextDouble() * 0.5;
    }

    // slightly faster spawns at higher speeds
    final clampSpd = speed.clamp(220, 620);
    _cooldown = (_cooldown * (280 / clampSpd)).clamp(0.45, 1.35);
  }
}
