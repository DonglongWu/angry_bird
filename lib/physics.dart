import 'package:flame_forge2d/flame_forge2d.dart';


/// 全局物理配置
class PhysicsConfig {
  static final gravity = Vector2(0, 20.0); // Forge2D 默认重力

  // 睡眠相关参数（抑制 jitter）
  static const sleepLinVel = 1.5;
  static const sleepAngVel = 0.02;
  static const sleepTime = 0.6;
  static const wakeImpulse = 50.0;
}

/// 材质配置
class MaterialConfig {
  static FixtureDef woodBox(Vector2 size) {
    return FixtureDef(
      PolygonShape()..setAsBoxXY(size.x, size.y),
      density: 0.6,
      friction: 0.5,
      restitution: 0.15,
    );
  }

  static FixtureDef stoneBox(Vector2 size) {
    return FixtureDef(
      PolygonShape()..setAsBoxXY(size.x, size.y),
      density: 2.5,
      friction: 0.6,
      restitution: 0.05,
    );
  }

  static FixtureDef glassBox(Vector2 size) {
    return FixtureDef(
      PolygonShape()..setAsBoxXY(size.x, size.y),
      density: 0.3,
      friction: 0.2,
      restitution: 0.01,
    );
  }

  static FixtureDef rockCircle(double radius) {
    return FixtureDef(
      CircleShape()..radius = radius,
      density: 3.5,
      friction: 0.8,
      restitution: 0.05,
    );
  }

  static FixtureDef poleBox(Vector2 size) {
    return FixtureDef(
      PolygonShape()..setAsBoxXY(size.x, size.y),
      density: 5.0,
      friction: 0.9,
      restitution: 0.0,
    );
  }

  static FixtureDef circle(double radius,
      {double density = 1.0, double friction = 0.3, double restitution = 0.2}) {
    return FixtureDef(
      CircleShape()..radius = radius,
      density: density,
      friction: friction,
      restitution: restitution,
    );
  }
}

/// HP 与伤害计算工具
class DamageHelper {
  static double initialHp(String type, double area) {
    switch (type) {
      case 'wood':
        return 50 + area * 0.02;
      case 'stone':
        return 100 + area * 0.04;
      case 'glass':
        return 10;
      case 'rock':
        return double.infinity;
      case 'pole':
        return double.infinity;
      default:
        return 30;
    }
  }

  static double calcImpact(Contact contact) {
    final vA = contact.fixtureA.body.linearVelocity;
    final vB = contact.fixtureB.body.linearVelocity;
    return (vA - vB).length;
  }
}
