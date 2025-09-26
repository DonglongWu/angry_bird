import 'package:flame_forge2d/flame_forge2d.dart';

import 'world.dart';
import 'obstacle.dart';
import 'pig.dart';
import 'level_api.dart';

class Level3 extends LevelAPI {
  @override
  void build(AngryWorld world) {
    const baseX = 60.0;
    const baseY = 38.0;

    // ==== 地基 ====
    world.add(Obstacle(Vector2(baseX, baseY), Vector2(8, 0.5), ObstacleType.stone));

    // ==== 左右柱子 ====
    world.add(Obstacle(Vector2(baseX - 7, baseY - 6), Vector2(0.5, 6), ObstacleType.wood));
    world.add(Obstacle(Vector2(baseX + 7, baseY - 6), Vector2(0.5, 6), ObstacleType.wood));

    // ==== 中间横梁 ====
    world.add(Obstacle(Vector2(baseX, baseY - 12), Vector2(7, 0.5), ObstacleType.wood));

    // ==== 三角屋顶 ====
    world.add(Obstacle(Vector2(baseX - 3, baseY - 18), Vector2(0.5, 6), ObstacleType.wood, angle: -0.5));
    world.add(Obstacle(Vector2(baseX + 3, baseY - 18), Vector2(0.5, 6), ObstacleType.wood, angle: 0.5));

    // ==== 两只猪 ====
    world.add(Pig(spawnPos: Vector2(baseX - 2, baseY - 14), radius: 1.2));
    world.add(Pig(spawnPos: Vector2(baseX + 2, baseY - 14), radius: 1.2));

    // ==== 初始鸟 ====
    world.spawnBird();
  }
}
