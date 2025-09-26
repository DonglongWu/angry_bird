import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'pig.dart';
import 'painter.dart';
import 'bird.dart';
import 'obstacle.dart';
import 'particle.dart' show GameParticle;
import 'particle_component.dart';
import 'camera.dart';
import 'consts.dart';
import 'level1.dart';

/// Forge2D 主世界
class AngryWorld extends Forge2DGame {
  Vector2 worldSize = Vector2.zero();
  late CameraController camCtrl;

  int score = 0;
  Bird? activeBird;
  late Vector2 slingshotPos;

  AngryWorld()
      : super(
    gravity: Vector2(0, 20.0),
    zoom: 1.0,
  );

  double get groundY => worldSize.y - 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final worldWidth = size.x / pixelsPerMeter;
    final worldHeight = size.y / pixelsPerMeter;
    worldSize = Vector2(worldWidth, worldHeight);

    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.position = worldSize / 2;
    camCtrl = CameraController(camera, worldSize, size, baseZoom: 1.0);

    slingshotPos = Vector2(2.5, worldSize.y - 1.5);

    add(Background(worldSize, slingshotPos));
    add(Ground(worldSize));

    Level1().build(this);

    camCtrl.focusOnSlingshot(slingshotPos);

    // ❌ 不需要再绑定 CollisionHandler
    // world.contactListener = CollisionHandler();
  }

  @override
  void update(double dt) {
    super.update(dt);
    camCtrl.update(dt);
  }

  void addScore(int value) => score += value;

  void spawnBird() {
    final bird = NormalBird(spawnPos: slingshotPos + Vector2(1.0, -1.0));
    add(bird);
    activeBird = bird;
    camCtrl.focusOnSlingshot(slingshotPos);
  }

  void followBird(Bird bird) => camCtrl.followBird(bird.body);

  void resetCamera() => camCtrl.focusOnSlingshot(slingshotPos);

  void focusOnEffect(Vector2 pos, {double zoom = 25.0, double lock = 1.0}) {
    camCtrl.focusOnEffect(pos, zoomFactor: zoom, lock: lock);
  }

  void resetWorld() {
    for (final b in List.of(children.whereType<Bird>())) {
      b.removeFromParent();
    }
    for (final p in List.of(children.whereType<Pig>())) {
      p.removeFromParent();
    }
    for (final o in List.of(children.whereType<Obstacle>())) {
      o.removeFromParent();
    }
    activeBird = null;
  }

  void addParticles(List<GameParticle> parts, {Color? color}) {
    for (final p in parts) {
      add(ParticleComponent(p, color: color));
    }
  }
}

class Background extends PositionComponent {
  final Vector2 worldSize;
  final Vector2 slingshotPos;
  double _time = 0;

  Background(this.worldSize, this.slingshotPos) {
    size = worldSize;
    anchor = Anchor.topLeft;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    SimplePainter.drawGrass(canvas, Vector2(0, worldSize.y - 1.0), worldSize.x, 0.5);

    SimplePainter.drawSun(canvas, Vector2(3, 3), 1.5, time: _time);
    SimplePainter.drawCloud(canvas, Vector2((_time * 2) % worldSize.x, 3), 1.5);

    for (int i = 0; i < 12; i++) {
      SimplePainter.drawFlower(
        canvas,
        Vector2(4.0 + i * 3.0, worldSize.y - 1.2),
        0.3,
        time: _time,
      );
    }

    SimplePainter.drawSlingshot(canvas, slingshotPos, 3.0);
  }
}

class Ground extends BodyComponent {
  final Vector2 worldSize;
  Ground(this.worldSize);

  @override
  Body createBody() {
    final y = worldSize.y - 1.0;
    final shape = EdgeShape()..set(Vector2(0, y), Vector2(worldSize.x, y));

    final fixtureDef = FixtureDef(
      shape,
      friction: 0.9,
      restitution: 0.0,
    );

    final bodyDef = BodyDef(type: BodyType.static);
    final body = world.createBody(bodyDef);
    body.createFixture(fixtureDef);
    return body;
  }
}
