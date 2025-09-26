// collision.dart
import 'package:flame_forge2d/flame_forge2d.dart';
import 'bird.dart';
import 'obstacle.dart';
import 'pig.dart';

/// 碰撞处理器 (带动量+动能伤害模型)
class CollisionHandler extends ContactListener {
  @override
  void beginContact(Contact contact) {
    final a = contact.fixtureA.body.userData;
    final b = contact.fixtureB.body.userData;

    if (a == null || b == null) return;

    // 鸟 vs 障碍物
    if (a is Bird && b is Obstacle) {
      _handleBirdHitObstacle(a, b, contact);
    } else if (b is Bird && a is Obstacle) {
      _handleBirdHitObstacle(b, a, contact);
    }

    // 鸟 vs 猪
    if (a is Bird && b is Pig) {
      _handleBirdHitPig(a, b, contact);
    } else if (b is Bird && a is Pig) {
      _handleBirdHitPig(b, a, contact);
    }

    // 障碍物 vs 猪
    if (a is Obstacle && b is Pig) {
      _handleObstacleHitPig(a, b, contact);
    } else if (b is Obstacle && a is Pig) {
      _handleObstacleHitPig(b, a, contact);
    }
  }

  /// 鸟撞障碍物
  void _handleBirdHitObstacle(Bird bird, Obstacle obstacle, Contact contact) {
    if (!bird.alive || obstacle.destroyed) return;

    final vRel = (bird.body.linearVelocity - obstacle.body.linearVelocity).length;
    final m = bird.body.mass;

    // 动量 + 动能模型
    final momentum = m * vRel;              // m * v
    final kinetic = 0.5 * m * vRel * vRel;  // 0.5 * m * v^2
    final damage = momentum * 0.5 + kinetic * 0.2;

    obstacle.takeDamage(damage);
  }

  /// 鸟撞猪
  void _handleBirdHitPig(Bird bird, Pig pig, Contact contact) {
    if (!bird.alive || pig.dead) return;

    final vRel = (bird.body.linearVelocity - pig.body.linearVelocity).length;
    final m = bird.body.mass;

    final momentum = m * vRel;
    final kinetic = 0.5 * m * vRel * vRel;
    final damage = momentum * 0.7 + kinetic * 0.3;

    pig.takeDamage(damage);
  }

  /// 障碍物砸猪
  void _handleObstacleHitPig(Obstacle obs, Pig pig, Contact contact) {
    if (obs.destroyed || pig.dead) return;

    final vRel = (obs.body.linearVelocity - pig.body.linearVelocity).length;
    final m = obs.body.mass;

    final momentum = m * vRel;
    final kinetic = 0.5 * m * vRel * vRel;
    final damage = momentum * 0.4 + kinetic * 0.1;

    pig.takeDamage(damage);
  }
}
