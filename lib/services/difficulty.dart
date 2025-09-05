class Difficulty {
  double t = 0;
  double speed = 220;
  final void Function(double) onSpeed;

  Difficulty({required this.onSpeed});

  void reset() { t = 0; speed = 220; onSpeed(speed); }

  void tick(double dt) {
    t += dt;
    speed = 220 + (t * 14);
    if (speed > 620) speed = 620;
    onSpeed(speed);
  }
}
