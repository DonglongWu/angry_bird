import 'physics.dart';
import 'consts.dart';
import 'dart:math' as math;

typedef VoidCallback = void Function();

enum BirdType { normal, splitter, dasher }

class Bird extends CircleBody {
  bool alive = true;
  double opacity = 1.0;
  final BirdType type;
  bool abilityUsed = false;

  // rest detection
  final double restLinVel;
  final double restHoldSec;
  double _restTimer = 0.0;

  final VoidCallback? onGone;

  Bird({
    Vec2? pos,
    Vec2? center,
    required double radius,
    double? mass,
    this.onGone,
    this.restLinVel = GameConsts.restLinVel,
    this.restHoldSec = GameConsts.restHoldSec,
    Vec2? vel,
    Vec2? acc,
    this.type = BirdType.normal,
  }) : super(
    pos: (pos ?? center)!,
    radius: radius,
    mass: mass ?? (1.0 * 3.14159 * radius * radius),
    vel: vel ?? Vec2(0, 0),
    acc: acc ?? Vec2(0, 0),
  );

  void tick(double dt) {
    if (!alive) return;
    final speed = vel.length;
    final resting = speed < restLinVel;
    if (resting) {
      _restTimer += dt;
      if (_restTimer >= restHoldSec) {
        markGone();
      }
    } else {
      _restTimer = 0.0;
    }
  }

  void markGone() {
    if (!alive) return;
    alive = false;
    opacity = 0.0;
    onGone?.call();
  }

  void tickFade(double dt) {
    if (alive) return;
    opacity = (opacity - dt * 4.0).clamp(0.0, 1.0);
  }

  /// 在飞行中触发技能
  /// 返回：如果产生了新鸟，返回它们；否则返回空数组
  List<Bird> triggerAbility() {
    if (abilityUsed || !alive) return const [];
    abilityUsed = true;

    switch (type) {
      case BirdType.normal:
        return const [];
      case BirdType.dasher:
      // 速度乘倍增，方向不变
        final spd = vel.length;
        if (spd <= 1e-3) return const [];
        final k = SlingConsts.dashMultiplier;
        final newSpd = (spd * k).clamp(0.0, SlingConsts.maxSpeed);
        final n = vel / spd;
        vel = n * newSpd;
        return const [];
      case BirdType.splitter:
      // 生成左右两只分身（小一点、速度略减，方向偏转）
        final spd = vel.length;
        if (spd <= 1e-3) return const [];
        final centerPos = Vec2(pos.x, pos.y);
        final baseDir = vel / spd;

        List<Bird> kids = [];
        double ang = SlingConsts.splitAngleDeg * math.pi / 180.0;
        Vec2 rot(Vec2 v, double a) {
          final c = math.cos(a), s = math.sin(a);
          return Vec2(c * v.x - s * v.y, s * v.x + c * v.y);
        }
        for (final sign in [-1.0, 1.0]) {
          final dir = rot(baseDir, ang * sign);
          final v = dir * (spd * SlingConsts.splitSpeedFactor);
          kids.add(Bird(
            center: centerPos,
            radius: SlingConsts.splitRadius,
            mass: 1.0,
            vel: v,
            acc: Vec2(acc.x, acc.y),
            type: BirdType.normal,
          ));
        }
        return kids;
    }
  }
}
