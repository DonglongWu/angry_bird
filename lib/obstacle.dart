// obstacle.dart
import 'physics.dart';

class Obstacle extends RectBody {
  bool alive = true;
  double _opacity = 1.0;
  bool _broken = false;

  final double breakThreshold;     // 目前未直接用到，保留以便后续扩展
  double durability;

  double _sleepTimer = 0.0;
  final double sleepAfter = 0.45;  // s
  final double sleepLinear = 5.0;  // px/s

  Obstacle({
    Vec2? pos,
    Vec2? center,
    required Vec2 halfSize,
    double mass = 2.0,
    Vec2? vel,
    Vec2? acc,
    this.breakThreshold = 2.5,
    double? durability,
  })  : durability = durability ?? mass * 2.0,
        super(
        pos: (pos ?? center)!,
        halfSize: halfSize,
        mass: mass,
        vel: vel ?? Vec2(0, 0),
        acc: acc ?? Vec2(0, 0),
      );

  double get opacity => _opacity;
  bool get broken => _broken;

  void onImpact(double j) {
    if (!alive || _broken) return;
    final damage = j * 2.0;
    durability -= damage;
    if (durability <= 0) {
      _broken = true;
      alive = false;
      _opacity = 0.0;
    }
  }

  void tick(double dt) {
    if (!alive) return;
    _opacity = _opacity.clamp(0.0, 1.0);
  }

  void tickSleep(double dt) {
    if (!alive) return;
    if (vel.length < sleepLinear) {
      _sleepTimer += dt;
      if (_sleepTimer > sleepAfter) {
        acc = Vec2(0, 0);
        vel = Vec2(0, 0);
      }
    } else {
      _sleepTimer = 0.0;
    }
  }
}

class ObstacleRot extends RotRectBody {
  bool alive = true;
  double _opacity = 1.0;
  bool _broken = false;

  final double breakThreshold;
  double durability;

  double _sleepTimer = 0.0;
  final double sleepAfter = 0.45;
  final double sleepLinear = 5.0;

  ObstacleRot({
    Vec2? pos,
    Vec2? center,
    required Vec2 halfSize,
    required double angleRadians,
    double mass = 3.6,
    Vec2? vel,
    Vec2? acc,
    this.breakThreshold = 2.5,
    double? durability,
  })  : durability = durability ?? mass * 2.0,
        super(
        pos: (pos ?? center)!,
        halfSize: halfSize,
        angle: angleRadians,
        mass: mass,
        vel: vel ?? Vec2(0, 0),
        acc: acc ?? Vec2(0, 0),
      );

  double get opacity => _opacity;
  bool get broken => _broken;

  void onImpact(double j) {
    if (!alive || _broken) return;
    final damage = j * 2.0;
    durability -= damage;
    if (durability <= 0) {
      _broken = true;
      alive = false;
      _opacity = 0.0;
    }
  }

  void tick(double dt) {
    if (!alive) return;
    _opacity = _opacity.clamp(0.0, 1.0);
  }

  void tickSleep(double dt) {
    if (!alive) return;
    if (vel.length < sleepLinear) {
      _sleepTimer += dt;
      if (_sleepTimer > sleepAfter) {
        acc = Vec2(0, 0);
        vel = Vec2(0, 0);
      }
    } else {
      _sleepTimer = 0.0;
    }
  }
}
