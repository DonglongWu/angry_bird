import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart';
import 'dart:ui';
import 'consts.dart';
import 'bird.dart';
import 'pig.dart';

enum ObstacleType { wood, stone, glass, rock, pole }

class Obstacle extends BodyComponent with ContactCallbacks {
  final Vector2 position;
  final Vector2 size;
  final ObstacleType type;
  final double angle;

  double hp;
  double _lifeTime = 0;
  bool destroyed = false;

  Obstacle(this.position, this.size, this.type, {this.angle = 0})
      : hp = _initialHp(type);

  static double _initialHp(ObstacleType type) {
    switch (type) {
      case ObstacleType.wood:
        return 60;
      case ObstacleType.stone:
        return 120;
      case ObstacleType.glass:
        return 20;
      case ObstacleType.rock:
        return double.infinity;
      case ObstacleType.pole:
        return double.infinity;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;
  }

  void takeDamage(double amount, {bool isBomb = false}) {
    if (_lifeTime < 0.2 || destroyed) return;

    switch (type) {
      case ObstacleType.glass:
        hp -= amount * 2;
        break;
      case ObstacleType.rock:
        if (isBomb) hp = -1;
        break;
      case ObstacleType.pole:
        return;
      default:
        hp -= amount;
        break;
    }

    if (hp <= 0 && !destroyed) {
      destroyed = true;
      _onBreak();
    }
  }

  void _onBreak() {
    removeFromParent();
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (destroyed) return;
    if (other is Bird) {
      takeDamage(other.impactPower * 0.6);
    } else if (other is Pig) {
      takeDamage(10);
    }
  }

  @override
  Body createBody() {
    Shape shape;
    if (type == ObstacleType.rock) {
      shape = CircleShape()..radius = size.x;
    } else {
      shape = PolygonShape()..setAsBoxXY(size.x, size.y);
    }

    final fixtureDef = FixtureDef(
      shape,
      density: _densityFor(type),
      friction: _frictionFor(type),
      restitution: _restitutionFor(type),
    );

    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: position,
      angle: angle,
    );

    final body = world.createBody(bodyDef)..createFixture(fixtureDef);
    body.userData = this;
    return body;
  }

  double _densityFor(ObstacleType t) {
    switch (t) {
      case ObstacleType.wood:
        return 0.8;
      case ObstacleType.stone:
        return 2.5;
      case ObstacleType.glass:
        return 0.3;
      case ObstacleType.rock:
        return 4.0;
      case ObstacleType.pole:
        return 3.0;
    }
  }

  double _frictionFor(ObstacleType t) {
    switch (t) {
      case ObstacleType.wood:
        return 0.5;
      case ObstacleType.stone:
        return 0.8;
      case ObstacleType.glass:
        return 0.2;
      case ObstacleType.rock:
        return 1.0;
      case ObstacleType.pole:
        return 0.9;
    }
  }

  double _restitutionFor(ObstacleType t) {
    switch (t) {
      case ObstacleType.wood:
        return 0.1;
      case ObstacleType.stone:
        return 0.05;
      case ObstacleType.glass:
        return 0.05;
      case ObstacleType.rock:
        return 0.0;
      case ObstacleType.pole:
        return 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final ppm = pixelsPerMeter;
    final paint = Paint();

    switch (type) {
      case ObstacleType.wood:
        paint.color = const Color(0xFF8B4513);
        _drawBox(canvas, paint, ppm);
        break;
      case ObstacleType.stone:
        paint.color = const Color(0xFF808080);
        _drawBox(canvas, paint, ppm);
        break;
      case ObstacleType.glass:
        paint.color = const Color(0x8822BFF3);
        _drawBox(canvas, paint, ppm);
        break;
      case ObstacleType.rock:
        paint.color = const Color(0xFF696969);
        canvas.drawCircle(
          Offset(position.x * ppm, position.y * ppm),
          size.x * ppm * 1.5,
          paint,
        );
        break;
      case ObstacleType.pole:
        paint.color = const Color(0xFF444444);
        _drawBox(canvas, paint, ppm);
        break;
    }
  }

  void _drawBox(Canvas canvas, Paint paint, double ppm) {
    canvas.save();
    canvas.translate(position.x * ppm, position.y * ppm);
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x * 2 * ppm,
        height: size.y * 2 * ppm,
      ),
      paint,
    );
    canvas.restore();
  }
}
