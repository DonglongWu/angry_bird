import 'dart:math';
import 'physics.dart';
import 'consts.dart';
import 'particle.dart';
import 'bird.dart';
import 'pig.dart';
import 'obstacle.dart';
import 'trajectory_helper.dart';

enum LevelStatus { playing, success, fail }

class GameWorld {
  // ----- world bounds -----
  late AABB world;

  // ----- actors -----
  final List<Bird> birds = [];
  final List<Pig> pigs = [];
  final List<Obstacle> obstacles = [];
  final List<ObstacleRot> beams = [];
  final List<Particle> particles = [];

  // ----- slingshot anchor -----
  late Vec2 slingAnchor;

  // ----- HUD/status -----
  int score = 0;
  int ballsLeft = GameConsts.ballsPerLevel;
  int get ballsPerLevel => GameConsts.ballsPerLevel;
  double timeLeft = GameConsts.levelTime;
  LevelStatus status = LevelStatus.playing;
  bool canShoot = true;

  // ----- drag / preview (for painter) -----
  bool dragging = false;
  Vec2 _dragPos = Vec2(0, 0);
  final List<Vec2> preview = <Vec2>[];
  List<Vec2> get previewPoints => preview;
  Vec2 get bandPoint => _dragPos;

  // predictor smooth dt
  double avgDt = 1 / 60.0;
  final TrajectoryHelper _traj = TrajectoryHelper();

  // launch grace (skip ground bounce first 0.1s)
  double _launchGrace = 0.0;
  static const double _launchGraceSec = 0.10;
  static const double _launchLift = 3.0;

  bool _bonusGranted = false;

  // ----- camera -----
  double cameraScale = GameConsts.cameraInitZoom;
  Vec2 cameraOffset = Vec2(0, 0); // world->screen: (pos - offset) * scale
  Vec2 _cameraTarget = Vec2(0, 0);

  BirdType nextBirdType = BirdType.normal; // 当前发射鸟的类型

  // ===== init =====
  void init({required double width, required double height}) {
    final pad = GameConsts.worldPadding;
    final extra = GameConsts.worldExtraWidth;
    world = AABB(left: pad, top: pad, right: width - pad + extra, bottom: height - pad);
    slingAnchor = Vec2(world.left + 110, world.bottom - 150);

    birds.clear();
    _spawnReadyBird(); // 创建待发射的鸟（在锚点处）

    pigs..clear()..addAll(_spawnPigs());
    obstacles..clear()..addAll(_buildHutBase());
    beams..clear()..addAll(_buildPillarsAndRoof()); // 注意：柱子改旋转版
    particles.clear();

    score = 0;
    ballsLeft = GameConsts.ballsPerLevel;
    timeLeft = GameConsts.levelTime;
    status = LevelStatus.playing;
    canShoot = true;
    _launchGrace = 0.0;
    _bonusGranted = false;

    dragging = false;
    preview.clear();

    // 相机初始化：看向弹弓附近
    _cameraTarget = Vec2(slingAnchor.x + 100, slingAnchor.y - 60);
    cameraOffset = Vec2(_cameraTarget.x - width / cameraScale / 2, _cameraTarget.y - height / cameraScale / 2);
  }

  Bird get _mainBird {
    // 当前“主视角”鸟：挑选场上速度最大且仍存活的那只；若都不动，选最后一只
    Bird? best;
    double bestSpd = -1;
    for (final b in birds) {
      if (!b.alive) continue;
      final s = b.vel.length;
      if (s > bestSpd) { bestSpd = s; best = b; }
    }
    return best ?? birds.last;
  }

  // ===== per-frame =====
  void tick({required double dt, required bool isDragging, Vec2? dragPoint}) {
    if (status == LevelStatus.playing) {
      timeLeft = (timeLeft - dt).clamp(0.0, 999.0);
      if (timeLeft <= 0 && !_allPigsDead()) _endFail();
    }

    // smooth dt for predictor
    avgDt = avgDt * 0.85 + dt * 0.15;

    if (_launchGrace > 0) {
      _launchGrace = (_launchGrace - dt).clamp(0, 10);
    }

    if (!isDragging) {
      // normal sim
      dragging = false;
      preview.clear();

      for (final b in birds) b.acc = SlingConsts.gravity;
      for (final p in pigs) p.acc = Vec2(0, 0);

      _integrAll(dt);
      _boundsAll();
      _collideAll();
      _particlesTick(dt);
      _postClamps(dt);

      _cleanupDead();
      if (status == LevelStatus.playing && _allPigsDead()) _endSuccess();
    } else if (dragPoint != null) {
      // drag branch: keep a light sim and build trajectory preview
      dragging = true;

      final clamped = _clampToCircleAboveGround(
        dragPoint, slingAnchor, SlingConsts.slingMaxStretch,
      );
      _dragPos = clamped;

      for (final o in obstacles) { integrate(o, dt); collideWithBoundsRect(o, world, SlingConsts.restitution, SlingConsts.floorFriction); }
      for (final p in pigs)      { integrate(p, dt); collideWithBoundsCircle(p, world, SlingConsts.restitution, SlingConsts.floorFriction); }
      for (final b in beams)     { integrate(b, dt); collideWithBoundsRotRect(b, world, SlingConsts.restitution, SlingConsts.floorFriction); }

      final releasePrev = Vec2(clamped.x, clamped.y - _launchLift);
      preview
        ..clear()
        ..addAll(_traj.predict(
          release: releasePrev,
          slingAnchor: slingAnchor,
          avgDt: avgDt,
          steps: 200,
        ));
    }

    _updateCamera(dt);
  }

  // ===== ability trigger =====
  void triggerAbility() {
    if (status != LevelStatus.playing) return;
    // 只允许对飞行中的速度>0的存活鸟触发
    final b = _mainBird;
    if (!b.alive) return;
    if (b.vel.length < 1) return;
    final spawned = b.triggerAbility();
    if (spawned.isNotEmpty) {
      for (final nb in spawned) {
        nb.onGone = _onAnyBirdGone;
        birds.add(nb);
      }
    }
  }

  // ===== launch helpers =====
  (Vec2 release, Vec2 v0) computeReleaseAndVelocity(Vec2? dragPoint) {
    final base = _clampToCircleAboveGround(
      dragPoint ?? _readyBird.pos, slingAnchor, SlingConsts.slingMaxStretch,
    );
    final release = Vec2(base.x, base.y - _launchLift);
    final drag = release - slingAnchor;
    final v0 = (drag * -SlingConsts.slingPower)..clampLength(SlingConsts.maxSpeed);
    return (release, v0);
  }

  void applyLaunch(Vec2 release, Vec2 v0) {
    if (status != LevelStatus.playing) return;
    if (!canShoot) return;
    if (ballsLeft <= 0) return;

    ballsLeft -= 1;
    canShoot = false;

    final b = _readyBird;
    b.pos = release;
    b.vel = v0;
    b.acc = SlingConsts.gravity;
    _launchGrace = _launchGraceSec;
  }

  Bird get _readyBird => birds.firstWhere((b) => b.vel.length == 0 && b.alive, orElse: () => birds.last);

  void _spawnReadyBird() {
    birds.add(Bird(
      center: slingAnchor,
      radius: 16,
      mass: 1.0,
      acc: Vec2(0, 0),
      restLinVel: GameConsts.restLinVel,
      restHoldSec: GameConsts.restHoldSec,
      onGone: _onAnyBirdGone,
      type: nextBirdType,
    ));
  }

  // ===== internal sim =====
  void _integrAll(double dt) {
    for (final b in birds) { integrate(b, dt); b.tick(dt); }
    for (final p in pigs) integrate(p, dt);
    for (final o in obstacles) { integrate(o, dt); o.tick(dt); }
    for (final r in beams)     { integrate(r, dt); r.tick(dt); }
  }

  void _boundsAll() {
    if (_launchGrace <= 0) {
      for (final b in birds) collideWithBoundsCircle(b, world, SlingConsts.restitution, SlingConsts.floorFriction);
    }
    for (final p in pigs) collideWithBoundsCircle(p, world, SlingConsts.restitution, SlingConsts.floorFriction);
    for (final o in obstacles) collideWithBoundsRect(o, world, SlingConsts.restitution, SlingConsts.floorFriction);
    for (final r in beams) collideWithBoundsRotRect(r, world, SlingConsts.restitution, SlingConsts.floorFriction);
  }

  void _collideAll() {
    // birds vs pigs/obstacles/beams
    for (final b in birds) {
      for (final p in pigs) {
        final j = resolveCircleCircle(b, p, 0.65);
        if (j > SlingConsts.pigKillImpulse && p.alive) _killPig(p);
      }
      for (final o in obstacles) {
        if (!o.alive) continue;
        final j = resolveCircleRect(b, o, 0.6);
        if (j > 0) o.onImpact(j);
        if (j > SlingConsts.obstacleWakeImpulse) _wakeObstacle(o, b);
      }
      for (final r in beams) {
        if (!r.alive) continue;
        final j = resolveCircleRotRect(b, r, 0.6);
        if (j > 0) r.onImpact(j);
        if (j > SlingConsts.obstacleWakeImpulse) _wakeRotObstacle(r, b);
      }
    }

    // pigs vs obstacles/beams
    for (final p in pigs) {
      for (final o in obstacles) {
        if (!o.alive) continue;
        final j = resolveCircleRect(p, o, 0.5);
        if (j > SlingConsts.pigKillImpulse && p.alive) _killPig(p);
        if (p.alive && (o.vel.y > SlingConsts.crushSpeed)) _killPig(p);
        if (j > 0) o.onImpact(j);
        if (j > SlingConsts.obstacleWakeImpulse) _wakeObstacle(o, p);
      }
      for (final r in beams) {
        if (!r.alive) continue;
        final j = resolveCircleRotRect(p, r, 0.5);
        if (j > SlingConsts.pigKillImpulse && p.alive) _killPig(p);
        if (p.alive && (r.vel.y > SlingConsts.crushSpeed)) _killPig(p);
        if (j > 0) r.onImpact(j);
        if (j > SlingConsts.obstacleWakeImpulse) _wakeRotObstacle(r, p);
      }
    }

    // obstacles vs obstacles
    for (int i = 0; i < obstacles.length; i++) {
      for (int j = i + 1; j < obstacles.length; j++) {
        if (!obstacles[i].alive || !obstacles[j].alive) continue;
        final jj = resolveRectRect(obstacles[i], obstacles[j], 0.45);
        if (jj > 0) {
          obstacles[i].onImpact(jj);
          obstacles[j].onImpact(jj);
        }
        if (jj > SlingConsts.obstacleWakeImpulse) {
          _wakeObstacle(obstacles[i], obstacles[j]);
          _wakeObstacle(obstacles[j], obstacles[i]);
        }
      }
    }

    // beams vs obstacles（可选：已在你的 physics 里实现的话可以打开）
    // for (final r in beams) {
    //   for (final o in obstacles) {
    //     if (!r.alive || !o.alive) continue;
    //     final j1 = resolveRotRectRect(r, o, 0.5);
    //     if (j1 > 0) { r.onImpact(j1); o.onImpact(j1); }
    //   }
    // }
  }

  void _particlesTick(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      final pr = particles[i];
      pr.life -= dt;
      if (pr.life <= 0) { particles.removeAt(i); continue; }
      pr.vel = pr.vel + SlingConsts.gravity * (dt * 0.2);
      pr.pos = pr.pos + pr.vel * dt;
    }
  }

  // 更自然的 rest clamp + sleep 计时
  double _sleepO = 0, _sleepR = 0;
  void _postClamps(double dt) {
    for (final b in birds) {
      clampVelocity(b, SlingConsts.maxSpeed);
    }

    for (final p in pigs) {
      clampVelocity(p, SlingConsts.maxSpeed * 0.85);
      clampToRest(p, box: world);
    }

    for (final o in obstacles) {
      clampVelocity(o, SlingConsts.maxSpeed * 0.6);
      clampToRest(
        o, box: world,
        angThreshold: GameConsts.restAngVel,
        sleepTimerSec: 0.18,
        onSleep: () => _sleepO += dt,
      );
      if (_sleepO >= 0.18) {
        o.vel = Vec2(0,0);
        _sleepO = 0;
      }
      o.tickSleep(dt);
    }

    for (final r in beams) {
      clampVelocity(r, SlingConsts.maxSpeed * 0.6);
      clampToRest(
        r, box: world,
        angThreshold: GameConsts.restAngVel,
        sleepTimerSec: 0.18,
        onSleep: () => _sleepR += dt,
      );
      if (_sleepR >= 0.18) {
        r.vel = Vec2(0,0);
        r.angVel = 0;
        _sleepR = 0;
      }
      r.tickSleep(dt);
    }
  }

  void _wakeObstacle(Obstacle o, Body hitter) {
    if (o.acc.x == 0 && o.acc.y == 0) {
      o.acc = SlingConsts.gravity;
      final dir = (o.pos.x - hitter.pos.x) >= 0 ? 1.0 : -1.0;
      o.vel = o.vel + Vec2(dir * SlingConsts.obstacleNudge, 0);
    }
  }

  void _wakeRotObstacle(ObstacleRot r, Body hitter) {
    if (r.acc.x == 0 && r.acc.y == 0) {
      r.acc = SlingConsts.gravity;
      final dir = (r.pos.x - hitter.pos.x) >= 0 ? 1.0 : -1.0;
      r.vel = r.vel + Vec2(dir * SlingConsts.obstacleNudge, 0);
    }
  }

  void _killPig(Pig pig) {
    pig.markDead();
    particles.addAll(Effects.pigBurst(pig.pos, count: SlingConsts.pigBurstParticles));
    score += GameConsts.pigScore;
  }

  void _cleanupDead() {
    // 猪淡出
    for (int i = pigs.length - 1; i >= 0; i--) {
      final p = pigs[i];
      if (!p.alive && p.tickDeath(avgDt, SlingConsts.pigDeathDuration)) {
        pigs.removeAt(i);
      }
    }
    // 障碍删除
    for (int i = obstacles.length - 1; i >= 0; i--) {
      if (!obstacles[i].alive) obstacles.removeAt(i);
    }
    for (int i = beams.length - 1; i >= 0; i--) {
      if (!beams[i].alive) beams.removeAt(i);
    }
    // 鸟 gone
    birds.removeWhere((b) => !b.alive && b.opacity == 0);
    // 没有活跃鸟了：如果还有球，补充一只待发射；否则结算（失败/成功上面会处理）
    final hasActive = birds.any((b) => b.alive && b.vel.length > 0.01);
    if (!hasActive && canShoot == false && ballsLeft > 0 && status == LevelStatus.playing) {
      canShoot = true;
      nextBirdType = BirdType.normal; // 你也可以在 UI 中切换
      _spawnReadyBird();
    }
  }

  // ===== level builder =====
  List<Pig> _spawnPigs() => [
    Pig(pos: Vec2(world.right - 450, world.bottom - 140), radius: 18),
    Pig(pos: Vec2(world.right - 400, world.bottom - 140), radius: 18),
  ];

  List<Obstacle> _buildHutBase() {
    final os = <Obstacle>[];
    final beamHalfWide = Vec2(80, 10); // 更宽的地基
    os.add(_groundedStick(centerX: world.right - 420, half: beamHalfWide, mass: 5.0));
    return os;
  }

  List<ObstacleRot> _buildPillarsAndRoof() {
    final list = <ObstacleRot>[];

    // 两根柱子（可旋转）
    final pillarHalf = Vec2(10, 70);
    final leftX  = world.right - 460;
    final rightX = world.right - 380;
    final baseY  = world.bottom - pillarHalf.y;
    list.add(ObstacleRot(center: Vec2(leftX,  baseY), halfSize: pillarHalf, angleRadians: 0, mass: 3.8));
    list.add(ObstacleRot(center: Vec2(rightX, baseY), halfSize: pillarHalf, angleRadians: 0, mass: 3.8));

    // 人字屋顶
    const pitchDeg = 28.0, thickness = 9.0, overhang = 12.0, lift = 2.0;
    final span     = rightX - leftX;
    final midX     = (leftX + rightX) / 2;
    final halfSpan = span / 2 + overhang;
    final pitchRad = pitchDeg * pi / 180.0;
    final beamLen  = halfSpan / cos(pitchRad);
    final halfSize = Vec2(beamLen, thickness);

    final topY = baseY - (pillarHalf.y);
    final leftCenter  = Vec2(midX - halfSpan / 2, topY - sin(pitchRad) * (beamLen / 2) - lift);
    final rightCenter = Vec2(midX + halfSpan / 2, topY - sin(pitchRad) * (beamLen / 2) - lift);

    list.add(ObstacleRot(center: leftCenter,  halfSize: halfSize, angleRadians: -pitchRad, mass: 3.6));
    list.add(ObstacleRot(center: rightCenter, halfSize: halfSize, angleRadians:  pitchRad, mass: 3.6));
    return list;
  }

  Obstacle _groundedStick({required double centerX, required Vec2 half, required double mass}) {
    final centerY = world.bottom - half.y;
    return Obstacle(pos: Vec2(centerX, centerY), halfSize: half, mass: mass, vel: Vec2(0, 0), acc: Vec2(0, 0));
  }

  // ===== misc =====
  Vec2 _clampToCircleAboveGround(Vec2 p, Vec2 center, double r) {
    final v = p - center;
    final len = v.length;
    final n = len == 0 ? Vec2(1, 0) : v / len;
    Vec2 res = (len <= r) ? p : center + n * r;

    const double eps = 0.001;
    final double minY = world.bottom - 16 - eps;
    if (res.y > minY) res = Vec2(res.x, minY);
    return res;
  }

  bool _allPigsDead() => pigs.every((p) => !p.alive);

  void _onAnyBirdGone() {
    // 留空即可：清理在 _cleanupDead 里做
  }

  void _endSuccess() {
    status = LevelStatus.success;
    if (!_bonusGranted) {
      score += ballsLeft * GameConsts.remainBallBonus;
      _bonusGranted = true;
    }
  }

  void _endFail() {
    status = LevelStatus.fail;
    if (!_bonusGranted) {
      score += ballsLeft * GameConsts.remainBallBonus;
      _bonusGranted = true;
    }
  }

  // ===== camera =====
  void _updateCamera(double dt) {
    final b = _mainBird;
    // 让相机往鸟的速度方向领航一点
    final lead = (b.vel.length > 1)
        ? Vec2(b.vel.x, b.vel.y) * (GameConsts.cameraLead / (b.vel.length + 1e-3))
        : Vec2(0, 0);

    _cameraTarget = Vec2(b.pos.x + lead.x, b.pos.y + lead.y);

    // 平滑
    cameraOffset = Vec2(
      cameraOffset.x + ( _cameraTarget.x - cameraOffset.x - 360.0 / cameraScale) * GameConsts.cameraFollowLerp,
      cameraOffset.y + ( _cameraTarget.y - cameraOffset.y - 640.0 / cameraScale) * GameConsts.cameraFollowLerp,
    );

    // 简易自动缩放：鸟接近屏幕边缘时拉远
    final inset = GameConsts.cameraBirdEdgeInset;
    // 这里你也可以接入手势缩放，先给出简单的自适应：
    // （可选：保持不超过 min/max）
    cameraScale = cameraScale.clamp(GameConsts.cameraMinZoom, GameConsts.cameraMaxZoom);
  }
}
