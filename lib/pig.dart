import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'world.dart';
import 'consts.dart';
import 'bird.dart';
import 'obstacle.dart';

class Pig extends BodyComponent<AngryWorld>
    with HasGameRef<AngryWorld>, ContactCallbacks {
  final Vector2 spawnPos;
  final double radius;

  double hp;
  bool dead = false;

  Pig({required this.spawnPos, this.radius = 0.4, this.hp = 50});

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.5,
      restitution: 0.2,
    );

    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: spawnPos,
      linearDamping: 1.2,
      angularDamping: 2.5,
    );

    final b = world.createBody(bodyDef)..createFixture(fixtureDef);
    b.userData = this;
    return b;
  }

  void takeDamage(double damage) {
    if (dead) return;
    hp -= damage;

    if (hp <= 0) {
      dead = true;
      _onDeath();
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (dead) return;
    if (other is Bird) {
      takeDamage(other.impactPower);
    } else if (other is Obstacle) {
      takeDamage(15);
    }
  }

  void _onDeath() {
    removeFromParent();
    gameRef.addScore(100);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = dead ? const Color(0xFF555555) : const Color(0xFF00FF00);
    final px = body.position.x * pixelsPerMeter;
    final py = body.position.y * pixelsPerMeter;

    canvas.drawCircle(
      Offset(px, py),
      radius * pixelsPerMeter,
      paint,
    );
  }
}
