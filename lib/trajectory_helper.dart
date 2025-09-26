import 'package:flame_forge2d/flame_forge2d.dart';
import 'consts.dart';

class TrajectoryHelper {
  static List<Vector2> predict(
      Vector2 release,
      Vector2 slingAnchor,
      double dt, {
        int steps = 90,
      }) {
    final points = <Vector2>[];
    var pos = Vector2.copy(release);
    var vel = (release - slingAnchor) * -SlingConsts.slingPower;

    // 限制最大速度
    if (vel.length > SlingConsts.maxSpeed) {
      vel.normalize();
      vel.scale(SlingConsts.maxSpeed);
    }

    for (int i = 0; i < steps; i++) {
      vel += SlingConsts.gravity * dt;
      pos += vel * dt;

      if (i % 2 == 0) {
        points.add(Vector2.copy(pos));
      }
    }
    return points;
  }
}
