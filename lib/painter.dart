// obstacle.dart
// 统一的障碍物定义：轴对齐矩形 Obstacle & 斜梁 ObstacleRot（固定角度）
// 支持血量、受击、淡出和“休眠”抖动抑制。
import 'physics.dart';

enum ObstacleType { wood, stone, glass }

// 基础血量（与面积相关）
double _baseHp(ObstacleType t, Vec2 half) {
  final area = (half.x * 2) * (half.y * 2);
  switch (t) {
    case ObstacleType.wood:  return 45 + area * 0.02;
    case ObstacleType.stone: return 80 + area * 0.03;
    case ObstacleType.glass: return 25 + area * 0.015;
  }
}

// 材质韧性（越大越抗击打，同样的冲量扣的血更少）
double _toughness(ObstacleType t) {
  switch (t) {
    case ObstacleType.wood:  return 1.0;
    case ObstacleType.stone: return 1.8;
    case ObstacleType.glass: return 0.6;
  }
}

/// 轴对齐矩形
class Obstacle extends RectBody {
  final ObstacleType type;

  bool alive = true;
  double opacity = 1.0;
  double hp;
  double _sleep = 0.0; // 低速累积时间

  Obstacle({
    this.type = ObstacleType.wood,
    Vec2? pos,
    Vec2? center,
    required Vec2 halfSize,
    double mass = 2.0,
    Vec2? vel,
    Vec2? acc,
    double? hitpoints,
  })  : hp = hitpoints ?? _baseHp(type, halfSize),
        super(
        pos: (pos ?? center)!,
        halfSize: halfSize,
        mass: mass,
        vel: vel ?? Vec2(0, 0),
        acc: acc ?? Vec2(0, 0),
      );

  bool get broken => !alive;

  /// 碰撞时由 world 调用；j 为碰撞冲量标量
  void onImpact(double j) {
    if (!alive) return;
    final tough = _toughness(type);
    final dmg = j / (18.0 * tough); // 调整 18.0 以改变整体难度
    hp -= dmg;
    if (hp <= 0) {
      alive = false;
      // 如果希望“立即消失”，保持 0；想要渐隐可在 tick() 里做
      opacity = 0.0;
      vel = Vec2(0, 0);
      acc = Vec2(0, 0);
    }
  }

  /// 每帧调用（可用于渐隐）
  void tick(double dt) {
    if (!alive && opacity > 0) {
      opacity = (opacity - dt * 3.0).clamp(0.0, 1.0);
    }
  }

  /// 低速抖动抑制：在地面等处小幅颤动时，过一会把速度钳到 0
  void tickSleep(double dt) {
    // 仅在“未受力”(acc==0)情况下考虑休眠
    if (acc.x == 0 && acc.y == 0) {
      if (vel.length < 2.0) {
        _sleep += dt;
        if (_sleep > 0.15) {
          vel = Vec2(0, 0);
        }
      } else {
        _sleep = 0.0;
      }
    } else {
      _sleep = 0.0;
    }
  }
}

/// 斜梁（定角度的有向矩形；此版本不包含自旋转惯性，只做平移）
/// 如需“真正倾倒”，后续可以在 physics.dart 中扩展角速度与角动量。
class ObstacleRot extends RotRectBody {
  final ObstacleType type;

  bool alive = true;
  double opacity = 1.0;
  double hp;
  double _sleep = 0.0;

  ObstacleRot({
    this.type = ObstacleType.wood,
    Vec2? pos,
    Vec2? center,              // world 用的是 center
    required Vec2 halfSize,
    required double angleRadians,
    double mass = 3.6,
    Vec2? vel,
    Vec2? acc,
    double? hitpoints,
  })  : hp = hitpoints ?? (_baseHp(type, halfSize) * 1.1), // 梁略硬一点
        super(
        pos: (pos ?? center)!,
        halfSize: halfSize,
        angle: angleRadians,
        mass: mass,
        vel: vel ?? Vec2(0, 0),
        acc: acc ?? Vec2(0, 0),
      );

  bool get broken => !alive;

  void onImpact(double j) {
    if (!alive) return;
    final tough = _toughness(type);
    final dmg = j / (18.0 * tough);
    hp -= dmg;
    if (hp <= 0) {
      alive = false;
      opacity = 0.0;
      vel = Vec2(0, 0);
      acc = Vec2(0, 0);
    }
  }

  void tick(double dt) {
    if (!alive && opacity > 0) {
      opacity = (opacity - dt * 3.0).clamp(0.0, 1.0);
    }
  }

  void tickSleep(double dt) {
    if (acc.x == 0 && acc.y == 0) {
      if (vel.length < 2.0) {
        _sleep += dt;
        if (_sleep > 0.15) vel = Vec2(0, 0);
      } else {
        _sleep = 0.0;
      }
    } else {
      _sleep = 0.0;
    }
  }
}
