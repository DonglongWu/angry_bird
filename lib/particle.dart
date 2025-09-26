import 'dart:math' as math;
import 'package:flame_forge2d/flame_forge2d.dart'; // 提供 Vector2


/// 游戏用的自定义粒子
class GameParticle {
  Vector2 pos;
  Vector2 vel;
  double life;
  double maxLife;

  GameParticle({
    required this.pos,
    required this.vel,
    required double life,
  })  : life = life,
        maxLife = life;
}

class Effects {
  /// 普通猪死亡：绿色肉块喷射
  static List<GameParticle> pigBurst(Vector2 center, {int count = 18}) {
    final rnd = math.Random();
    final out = <GameParticle>[];
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final s = 60 + rnd.nextDouble() * 100;
      final v = Vector2(math.cos(a) * s, math.sin(a) * s);
      final life = 0.6 + rnd.nextDouble() * 0.4;
      out.add(GameParticle(pos: Vector2.copy(center), vel: v, life: life));
    }
    return out;
  }

  /// 玻璃破碎：碎片四散
  static List<GameParticle> glassShatter(Vector2 center, {int count = 25}) {
    final rnd = math.Random();
    final out = <GameParticle>[];
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final s = 100 + rnd.nextDouble() * 150;
      final v = Vector2(math.cos(a) * s, math.sin(a) * s);
      final life = 0.4 + rnd.nextDouble() * 0.3;
      out.add(GameParticle(pos: Vector2.copy(center), vel: v, life: life));
    }
    return out;
  }

  /// 爆炸鸟爆炸：火花+烟雾
  static List<GameParticle> bombExplosion(Vector2 center, {int count = 40}) {
    final rnd = math.Random();
    final out = <GameParticle>[];
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final s = 150 + rnd.nextDouble() * 200;
      final v = Vector2(math.cos(a) * s, math.sin(a) * s);
      final life = 0.8 + rnd.nextDouble() * 0.5;
      out.add(GameParticle(pos: Vector2.copy(center), vel: v, life: life));
    }
    return out;
  }

  /// Boss猪死亡：烟花特效
  static List<GameParticle> bossFireworks(Vector2 center, {int count = 60}) {
    final rnd = math.Random();
    final out = <GameParticle>[];
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final s = 200 + rnd.nextDouble() * 250;
      final v = Vector2(math.cos(a) * s, math.sin(a) * s);
      final life = 1.2 + rnd.nextDouble() * 0.5;
      out.add(GameParticle(pos: Vector2.copy(center), vel: v, life: life));
    }
    return out;
  }

  /// 木头折断：木屑四散
  static List<GameParticle> woodSplinters(Vector2 center, {int count = 30}) {
    final rnd = math.Random();
    final out = <GameParticle>[];
    for (int i = 0; i < count; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final s = 80 + rnd.nextDouble() * 120;
      final v = Vector2(math.cos(a) * s, math.sin(a) * s);
      final life = 0.5 + rnd.nextDouble() * 0.3;
      out.add(GameParticle(pos: Vector2.copy(center), vel: v, life: life));
    }
    return out;
  }
}
