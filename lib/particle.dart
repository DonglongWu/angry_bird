// particle.dart
import 'dart:math' as math;
import 'physics.dart';

class Particle {
  Vec2 pos;
  Vec2 vel;
  double life; // seconds
  Particle({required this.pos, required this.vel, required this.life});
}

/// 简单的特效集合
class Effects {
  // 猪死亡时的喷射粒子
  static List<Particle> pigBurst(Vec2 center, {int count = 18}) {
    final rnd = math.Random();
    final out = <Particle>[];
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final s = 80 + rnd.nextDouble() * 120;
      final v = Vec2(math.cos(a) * s, math.sin(a) * s * -0.3);
      out.add(
        Particle(
          pos: Vec2(center.x, center.y),
          vel: v,
          life: 0.6 + rnd.nextDouble() * 0.4,
        ),
      );
    }
    return out;
  }
}
