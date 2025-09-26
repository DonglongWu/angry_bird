// registry.dart
import 'world.dart';
import 'level_api.dart';
import 'level1.dart';
import 'level2.dart';
import 'level3.dart';

/// 用来集中管理和构建关卡
class LevelRegistry {
  static void buildLevel(AngryWorld world, int levelIndex) {
    switch (levelIndex) {
      case 1:
        Level1().build(world);
        break;
      case 2:
        Level2().build(world);
        break;
      case 3:
        Level3().build(world);
        break;
      default:
        Level1().build(world);
    }
  }
}
