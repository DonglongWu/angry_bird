// pig.dart
import 'dart:math' as math;
import 'physics.dart';

class Pig extends CircleBody {
  bool alive = true;
  double opacity = 1.0;

  Pig({
    Vec2? pos,
    Vec2? center,
    required double radius,
    double mass = 1.0,
    Vec2? vel,
    Vec2? acc,
  }) : super(
    pos: (pos ?? center)!,
    radius: radius,
    mass: mass,
    vel: vel ?? Vec2(0, 0),
    acc: acc ?? Vec2(0, 0),
  );

  void markDead() => alive = false;

  bool tickDeath(double dt, double duration) {
    if (alive) return false;
    if (duration <= 0) { opacity = 0; return true; }
    opacity = (opacity - dt / duration).clamp(0.0, 1.0);
    return opacity <= 0.0;
  }
}
