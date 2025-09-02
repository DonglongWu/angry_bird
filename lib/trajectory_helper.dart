// trajectory_helper.dart
import 'physics.dart';
import 'consts.dart';

class TrajectoryHelper {
  List<Vec2> predict({
    required Vec2 release,
    required Vec2 slingAnchor,
    required double avgDt,
    int steps = 160,
  }) {
    final pts = <Vec2>[];
    final dt = avgDt.clamp(1 / 120, 1 / 30);

    Vec2 pos = release;
    Vec2 vel = (release - slingAnchor) * -SlingConsts.slingPower;
    vel.clampLength(SlingConsts.maxSpeed);

    for (int i = 0; i < steps; i++) {
      vel = vel + SlingConsts.gravity * dt;
      pos = pos + vel * dt;
      vel.clampLength(SlingConsts.maxSpeed);
      if (i % 2 == 0) pts.add(pos);
    }
    return pts;
  }
}
