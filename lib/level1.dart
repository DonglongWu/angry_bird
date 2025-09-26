import 'package:flame_forge2d/flame_forge2d.dart';

import 'world.dart';
import 'obstacle.dart';
import 'pig.dart';
import 'level_api.dart';

class Level1 implements LevelAPI {
  @override
  void build(AngryWorld world) {
    final double baseX = 12;
    final double groundY = world.worldSize.y - 0.5;

    final double wallHeight = 6.0;
    final double wallHalfW = 0.3;

    // 左右墙
    world.add(Obstacle(Vector2(baseX - 3, groundY - wallHeight / 2),
        Vector2(wallHalfW, wallHeight / 2), ObstacleType.wood));
    world.add(Obstacle(Vector2(baseX + 3, groundY - wallHeight / 2),
        Vector2(wallHalfW, wallHeight / 2), ObstacleType.wood));

    // 地板
    world.add(Obstacle(Vector2(baseX, groundY - wallHeight),
        Vector2(3.3, 0.3), ObstacleType.stone));

    // 顶梁
    world.add(Obstacle(Vector2(baseX, groundY - wallHeight - 2.5),
        Vector2(3.3, 0.3), ObstacleType.stone));

    // 斜梁
    world.add(Obstacle(Vector2(baseX - 2, groundY - wallHeight - 2),
        Vector2(0.3, 2.5), ObstacleType.wood, angle: -0.6));
    world.add(Obstacle(Vector2(baseX + 2, groundY - wallHeight - 2),
        Vector2(0.3, 2.5), ObstacleType.wood, angle: 0.6));

    // 猪在房子里
    world.add(Pig(spawnPos: Vector2(baseX, groundY - 1.5), radius: 0.6));

    // 初始鸟
    world.spawnBird();
  }
}
