import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'world.dart';
import 'physics.dart';

class SlingshotGamePage extends StatefulWidget {
  final int levelIndex;
  const SlingshotGamePage({super.key, this.levelIndex = 1});

  @override
  State<SlingshotGamePage> createState() => _SlingshotGamePageState();
}

class _SlingshotGamePageState extends State<SlingshotGamePage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  final GameWorld _world = GameWorld();
  late _GamePainter _painter;

  bool _dragging = false;
  Vec2? _dragPoint;
  bool _initialized = false;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _painter = _GamePainter(_world);
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration now) {
    if (!_initialized) return;
    final dt = _last == Duration.zero
        ? 1 / 60.0
        : (now - _last).inMicroseconds / 1e6;
    _last = now;

    _world.tick(dt: dt, isDragging: _dragging, dragPoint: _dragPoint);
    if (mounted) setState(() {});
  }

  void _ensureInit(Size size) {
    if (_initialized) return;
    _lastSize = size;
    _world.init(width: size.width, height: size.height);
    _initialized = true;
  }

  // 拖拽发射
  void _onPanStart(DragStartDetails d) {
    if (_world.canShoot) {
      _dragging = true;
      _dragPoint = Vec2(d.localPosition.dx, d.localPosition.dy);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    _dragPoint = Vec2(d.localPosition.dx, d.localPosition.dy);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final (release, v0) = _world.computeReleaseAndVelocity(_dragPoint);
    _world.applyLaunch(release, v0);
    _dragPoint = null;
  }

  // 结算按钮点击 或 双击触发技能
  void _onTapUp(TapUpDetails d) {
    if (_world.status == LevelStatus.playing) return;
    final p = d.localPosition;

    if (_painter.nextButtonRect?.contains(p) == true) {
      _world.init(width: _lastSize.width, height: _lastSize.height); // 重开当前关
      setState(() {});
      return;
    }
    if (_painter.homeButtonRect?.contains(p) == true) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
  }

  void _onDoubleTap() {
    // 飞行中触发技能
    _world.triggerAbility();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1114),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          _lastSize = size;
          _ensureInit(size);

          return GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onTapUp: _onTapUp,
            onDoubleTap: _onDoubleTap,
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _painter,
                isComplex: true,
                willChange: true,
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ====================== 画笔（带相机） ======================

class _GamePainter extends CustomPainter {
  final GameWorld world;

  Rect? nextButtonRect;
  Rect? homeButtonRect;

  _GamePainter(this.world);

  @override
  void paint(Canvas canvas, Size size) {
    // 背景（不受相机缩放影响）
    final bg = Paint()..color = const Color(0xFF0F1114);
    canvas.drawRect(Offset.zero & size, bg);

    // 相机变换：world -> screen
    canvas.save();
    canvas.translate(-world.cameraOffset.x * world.cameraScale, -world.cameraOffset.y * world.cameraScale);
    canvas.scale(world.cameraScale, world.cameraScale);

    // 地面（世界）
    final ground = Paint()..color = const Color(0xFF1E2228);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 40, world.world.right, 40), ground);

    // 弹弓 & 轨迹（世界）
    _drawSling(canvas);
    _drawTrajectory(canvas);

    // 物体（世界）
    _drawObstacles(canvas);
    _drawBeams(canvas);
    _drawPigs(canvas);
    _drawBirds(canvas);
    _drawParticles(canvas);

    canvas.restore();

    // HUD（屏幕坐标）
    _drawHud(canvas, size);

    // 非 playing 状态时显示按钮（屏幕坐标）
    if (world.status != LevelStatus.playing) {
      const w = 120.0, h = 44.0, gap = 16.0;
      final y = 24.0;
      homeButtonRect = Rect.fromLTWH(24.0, y, w, h);
      nextButtonRect = Rect.fromLTWH(24.0 + w + gap, y, w, h);
      _drawButton(canvas, homeButtonRect!, 'Home');
      _drawButton(canvas, nextButtonRect!, 'Restart');
    } else {
      nextButtonRect = null;
      homeButtonRect = null;
    }
  }

  // ———— 世界绘制 ————
  void _drawSling(Canvas canvas) {
    final anchor = world.slingAnchor;
    final paint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(anchor.x, anchor.y), 6, Paint()..color = const Color(0xFF8D6E63));

    if (world.dragging) {
      final band = Paint()
        ..color = const Color(0xFFFFA726)
        ..strokeWidth = 3;
      final bp = world.bandPoint;
      canvas.drawLine(Offset(anchor.x, anchor.y), Offset(bp.x, bp.y), band);
    }
  }

  void _drawTrajectory(Canvas canvas) {
    if (world.previewPoints.isEmpty) return;
    final p = Paint()..color = const Color(0xFF90CAF9);
    for (final v in world.previewPoints) {
      canvas.drawCircle(Offset(v.x, v.y), 2, p);
    }
  }

  void _drawBirds(Canvas canvas) {
    for (final b in world.birds) {
      final alpha = (b.opacity.clamp(0.0, 1.0) * 255).toInt();
      final paint = Paint()..color = Color.fromARGB(alpha, 0x4C, 0xAF, 0x50);
      canvas.drawCircle(Offset(b.pos.x, b.pos.y), b.radius, paint);
      canvas.drawCircle(
        Offset(b.pos.x, b.pos.y),
        b.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withOpacity(0.25),
      );
    }
  }

  void _drawPigs(Canvas canvas) {
    for (final p in world.pigs) {
      final alpha = (p.opacity.clamp(0.0, 1.0) * 255).toInt();
      final paint = Paint()..color = Color.fromARGB(alpha, 0xF4, 0x43, 0x36);
      canvas.drawCircle(Offset(p.pos.x, p.pos.y), p.radius, paint);
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        p.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withOpacity(0.25),
      );
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final o in world.obstacles) {
      final alpha = (o.opacity.clamp(0.0, 1.0) * 255).toInt();
      final rectPaint = Paint()..color = Color.fromARGB(alpha, 0x8D, 0x6E, 0x63);
      final left = o.pos.x - o.halfSize.x;
      final top = o.pos.y - o.halfSize.y;
      final r = Rect.fromLTWH(left, top, o.halfSize.x * 2, o.halfSize.y * 2);
      canvas.drawRect(r, rectPaint);
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withOpacity(0.25),
      );
    }
  }

  void _drawBeams(Canvas canvas) {
    for (final b in world.beams) {
      final alpha = (b.opacity.clamp(0.0, 1.0) * 255).toInt();
      final paint = Paint()..color = Color.fromARGB(alpha, 0xA1, 0x88, 0x7F);

      canvas.save();
      canvas.translate(b.pos.x, b.pos.y);
      canvas.rotate(b.angle);
      final r = Rect.fromCenter(
        center: Offset.zero,
        width: b.halfSize.x * 2,
        height: b.halfSize.y * 2,
      );
      canvas.drawRect(r, paint);
      canvas.drawRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withOpacity(0.25),
      );
      canvas.restore();
    }
  }

  void _drawParticles(Canvas canvas) {
    if (world.particles.isEmpty) return;
    final p = Paint()..color = const Color(0xFFFFF59D);
    for (final pr in world.particles) {
      final a = ((pr.life.clamp(0.0, 1.0)) * 255).toInt();
      p.color = p.color.withAlpha(a);
      canvas.drawCircle(Offset(pr.pos.x, pr.pos.y), 2, p);
    }
  }

  // ———— HUD / Buttons（屏幕坐标） ————
  void _drawHud(Canvas canvas, Size size) {
    final style = const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600);
    final tp = TextPainter(
      text: TextSpan(
        text:
        'Score: ${world.score}   Balls: ${world.ballsLeft}/${world.ballsPerLevel}   Time: ${world.timeLeft.toStringAsFixed(1)}s',
        style: style,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, const Offset(16, 60));
  }

  void _drawButton(Canvas canvas, Rect r, String text) {
    final btn = Paint()..color = const Color(0xFF2A3139);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF3A424C);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), btn);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), border);

    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: r.width - 12);
    final off = Offset(r.left + (r.width - tp.width) / 2, r.top + (r.height - tp.height) / 2);
    tp.paint(canvas, off);
  }

  @override
  bool shouldRepaint(covariant _GamePainter oldDelegate) => true;
}
