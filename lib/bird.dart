import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'world.dart';
import 'consts.dart';
import 'pig.dart';
import 'obstacle.dart';

/// 鸟基类
abstract class Bird extends BodyComponent<AngryWorld>
    with HasGameRef<AngryWorld>, ContactCallbacks {
  final Vector2 spawnPos;
  final double radius;
  bool alive = true;
  double _sleepTimer = 0;
  double _lifeTime = 0;

  Bird({required this.spawnPos, this.radius = 0.5});

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(
      shape,
      density: baseDensity,
      friction: 0.6,
      restitution: 0.2,
    );

    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: spawnPos,
      bullet: true,
      linearDamping: 1.5,
      angularDamping: 3.0,
    );

    final b = world.createBody(bodyDef)..createFixture(fixtureDef);
    b.userData = this;
    return b;
  }

  double get baseDensity => 2.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

    _lifeTime += dt;
    final vel = body.linearVelocity;

    // 限制最大速度
    const double maxSpeed = 20.0;
    if (vel.length > maxSpeed) {
      body.linearVelocity = vel.normalized() * maxSpeed;
    }

    // 掉出世界
    if (body.position.y > gameRef.worldSize.y + 5) {
      _killBird();
      return;
    }

    if (_lifeTime < 1.0) return; // 开局保护

    // 速度过低 → 计时休眠
    if (vel.length < 0.5) {
      _sleepTimer += dt;
      if (_sleepTimer > 2.0) {
        _killBird();
      }
    } else {
      _sleepTimer = 0;
    }
  }

  void _killBird() {
    alive = false;
    gameRef.resetCamera();
    removeFromParent();
  }

  void launch(Vector2 force) {
    body.applyLinearImpulse(force);
    gameRef.followBird(this);
  }

  /// 动量作为攻击力
  double get impactPower {
    final mass = body.mass;
    final speed = body.linearVelocity.length;
    return mass * speed;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (!alive) return;
    if (other is Pig) {
      other.takeDamage(impactPower * 0.8);
    } else if (other is Obstacle) {
      other.takeDamage(impactPower * 0.5);
    }
  }

  Color get birdColor => const Color(0xFFB22222);

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = birdColor;
    final px = body.position.x * pixelsPerMeter;
    final py = body.position.y * pixelsPerMeter;

    canvas.drawCircle(
      Offset(px, py),
      radius * pixelsPerMeter,
      paint,
    );
  }

  void onTapSkill() {}
}

/// 普通鸟
class NormalBird extends Bird {
  NormalBird({required super.spawnPos}) : super(radius: 0.5);
}

/// 三叉鸟
class TripleBird extends Bird {
  bool _usedSkill = false;
  TripleBird({required super.spawnPos}) : super(radius: 0.4);

  @override
  Color get birdColor => const Color(0xFF1E90FF);

  @override
  void onTapSkill() {
    if (_usedSkill) return;
    _usedSkill = true;
    final pos = body.position;

    for (var offset in [-0.3, 0.3]) {
      final newBird = NormalBird(spawnPos: pos + Vector2(offset, 0));
      gameRef.add(newBird);
      newBird.launch(body.linearVelocity + Vector2(offset * 5, 0));
    }
  }
}

/// 冲刺鸟
class DasherBird extends Bird {
  bool _usedSkill = false;
  DasherBird({required super.spawnPos}) : super(radius: 0.5);

  @override
  Color get birdColor => const Color(0xFFFFA500);

  @override
  void onTapSkill() {
    if (_usedSkill) return;
    _usedSkill = true;

    final dir = body.linearVelocity.normalized();
    body.applyLinearImpulse(dir * 40);
    gameRef.focusOnEffect(body.position, zoom: 28, lock: 0.5);
  }
}

/// 爆炸鸟
class BombBird extends Bird {
  bool exploded = false;
  BombBird({required super.spawnPos}) : super(radius: 0.6);

  @override
  Color get birdColor => const Color(0xFF000000);

  void triggerExplosion() {
    if (exploded || _lifeTime < 1.0) return;
    exploded = true;
    _killBird();
    gameRef.focusOnEffect(body.position, zoom: 35, lock: 1.0);
  }
}

/// 巨鸟
class HeavyBird extends Bird {
  HeavyBird({required super.spawnPos}) : super(radius: 0.8);

  @override
  double get baseDensity => 5.0;

  @override
  Color get birdColor => const Color(0xFF8B0000);
}
