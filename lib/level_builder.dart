// level_builder.dart
import 'world.dart';
import 'level1.dart';
import 'level2.dart';
import 'level3.dart';
import 'level_api.dart';

class LevelBuilder {
  static LevelAPI getLevel(int index) {
    switch (index) {
      case 1:
        return Level1();
      case 2:
        return Level2();
      case 3:
        return Level3();
      default:
        throw Exception("关卡 $index 未定义");
    }
  }

  static void loadLevel(AngryWorld world, int index) {
    final level = getLevel(index);
    level.build(world);
  }
}
