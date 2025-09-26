import 'package:flame_forge2d/flame_forge2d.dart';

import 'world.dart';
import 'obstacle.dart';
import 'pig.dart';
import 'level_api.dart';

class Level2 extends LevelAPI {
  @override
  void build(AngryWorld world) {
    const baseX = 50.0;
    const baseY = 40.0;

    // ==== 地基 ====
    world.add(Obstacle(Vector2(baseX, baseY), Vector2(6, 0.5), ObstacleType.stone));

    // ==== 左右撑杆 ====
    world.add(Obstacle(Vector2(baseX - 5, baseY - 6), Vector2(0.5, 6), ObstacleType.wood));
    world.add(Obstacle(Vector2(baseX + 5, baseY - 6), Vector2(0.5, 6), ObstacleType.wood));

    // ==== 横梁 ====
    world.add(Obstacle(Vector2(baseX, baseY - 12), Vector2(6, 0.5), ObstacleType.wood));

    // ==== 放猪 ====
    world.add(Pig(spawnPos: Vector2(baseX, baseY - 14), radius: 1.2));

    // ==== 初始鸟 ====
    world.spawnBird();
  }
}
