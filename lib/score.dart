import 'dart:math' as math;

enum BirdKind { normal, splitter, dasher, bomb, heavy }
enum PigKind { normal, boss }
enum ObstacleKind { wood, stone, glass }

class ScoreConfig {
  final int timeLimitSec;
  final int timePerSecond;

  final int normalBirdBonus;
  final int splitterBirdBonus;
  final int dasherBirdBonus;
  final int bombBirdBonus;
  final int heavyBirdBonus;

  final int pigScore;
  final int bossPigScore;

  final int woodScore;
  final int stoneScore;
  final int glassScore;

  final int star1, star2, star3;

  const ScoreConfig({
    this.timeLimitSec = 100,
    this.timePerSecond = 10,

    this.normalBirdBonus = 500,
    this.splitterBirdBonus = 700,
    this.dasherBirdBonus = 800,
    this.bombBirdBonus = 1000,
    this.heavyBirdBonus = 900,

    this.pigScore = 500,
    this.bossPigScore = 2000,

    this.woodScore = 50,
    this.stoneScore = 100,
    this.glassScore = 30,

    this.star1 = 2000,
    this.star2 = 4000,
    this.star3 = 6000,
  });
}

class ScoreState {
  final ScoreConfig cfg;
  int elapsedMs = 0;
  bool frozen = false;

  // 未使用的鸟
  int unusedNormal = 0;
  int unusedSplitter = 0;
  int unusedDasher = 0;
  int unusedBomb = 0;
  int unusedHeavy = 0;

  // 击杀/破坏记录
  int killedPigs = 0;
  int killedBossPigs = 0;
  int destroyedWood = 0;
  int destroyedStone = 0;
  int destroyedGlass = 0;

  ScoreState(this.cfg);

  void tickMs(int dtMs) {
    if (!frozen) elapsedMs += dtMs;
  }

  int get remainingSec =>
      math.max(0, cfg.timeLimitSec - (elapsedMs / 1000).floor());

  int get timeScore => remainingSec * cfg.timePerSecond;

  int get birdScore =>
      unusedNormal * cfg.normalBirdBonus +
          unusedSplitter * cfg.splitterBirdBonus +
          unusedDasher * cfg.dasherBirdBonus +
          unusedBomb * cfg.bombBirdBonus +
          unusedHeavy * cfg.heavyBirdBonus;

  int get killScore =>
      killedPigs * cfg.pigScore +
          killedBossPigs * cfg.bossPigScore;

  int get obstacleScore =>
      destroyedWood * cfg.woodScore +
          destroyedStone * cfg.stoneScore +
          destroyedGlass * cfg.glassScore;

  int get total => timeScore + birdScore + killScore + obstacleScore;

  int get stars {
    final s = total;
    if (s >= cfg.star3) return 3;
    if (s >= cfg.star2) return 2;
    if (s >= cfg.star1) return 1;
    return 0;
  }

  void freeze() => frozen = true;

  void consumeBird(BirdKind k) {
    switch (k) {
      case BirdKind.normal:
        if (unusedNormal > 0) unusedNormal--;
        break;
      case BirdKind.splitter:
        if (unusedSplitter > 0) unusedSplitter--;
        break;
      case BirdKind.dasher:
        if (unusedDasher > 0) unusedDasher--;
        break;
      case BirdKind.bomb:
        if (unusedBomb > 0) unusedBomb--;
        break;
      case BirdKind.heavy:
        if (unusedHeavy > 0) unusedHeavy--;
        break;
    }
  }

  void killPig(PigKind k) {
    if (k == PigKind.normal) killedPigs++;
    if (k == PigKind.boss) killedBossPigs++;
  }

  void destroyObstacle(ObstacleKind k) {
    switch (k) {
      case ObstacleKind.wood:
        destroyedWood++;
        break;
      case ObstacleKind.stone:
        destroyedStone++;
        break;
      case ObstacleKind.glass:
        destroyedGlass++;
        break;
    }
  }
}
