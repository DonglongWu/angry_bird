// level_api.dart
import 'world.dart';

/// 每个关卡都要实现 build 方法
abstract class LevelAPI {
  void build(AngryWorld world);
}
