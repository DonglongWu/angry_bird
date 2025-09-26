import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';  // 提供 Vector2
import 'package:flutter/scheduler.dart' show Ticker;

import 'world.dart';
import 'bird.dart';
import 'menu.dart';
import 'trajectory_helper.dart';
import 'consts.dart';

class SlingshotGamePage extends StatefulWidget {
  const SlingshotGamePage({super.key, required this.levelIndex});
  final int levelIndex;

  @override
  State<SlingshotGamePage> createState() => _SlingshotGamePageState();
}

class _SlingshotGamePageState extends State<SlingshotGamePage>
    with TickerProviderStateMixin {
  late AngryWorld world;
  late Ticker _ticker;
  Timer? _countdown;
  int _timeLeft = 60;

  Vector2? _dragPointWorld; // 拖拽点（米）
  Vector2? _dragPointScreen; // 拖拽点（像素）

  @override
  void initState() {
    super.initState();

    world = AngryWorld();

    // 游戏循环
    _ticker = createTicker((_) {
      setState(() {
        world.updateTree(1 / 60);
        world.camCtrl.update(1 / 60);
      });
      if (_timeLeft <= 0) _endGame();
    })..start();

    // 倒计时
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft <= 0) {
        _endGame();
        return;
      }
      setState(() => _timeLeft -= 1);
    });
  }

  void _restart() {
    _countdown?.cancel();
    setState(() {
      world = AngryWorld();
      _timeLeft = 60;
      _dragPointWorld = null;
    });
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft <= 0) {
        _endGame();
        return;
      }
      setState(() => _timeLeft -= 1);
    });
  }

  void _endGame() {
    _countdown?.cancel();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Time Up'),
        content: Text('Score: ${world.score}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restart();
            },
            child: const Text('Restart'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuPage()),
                    (r) => false,
              );
            },
            child: const Text('Home'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1114),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: (d) {
                final px = d.localPosition.dx;
                final py = d.localPosition.dy;

                // 像素转米
                final worldX = px / pixelsPerMeter;
                final worldY = py / pixelsPerMeter;

                setState(() {
                  _dragPointWorld = Vector2(worldX, worldY);
                  _dragPointScreen = Vector2(px, py);
                });
              },
              onPanEnd: (_) {
                if (_dragPointWorld != null) {
                  final bird = world.activeBird;
                  if (bird != null) {
                    final slingAnchor = world.slingshotPos;
                    final force = (slingAnchor - _dragPointWorld!) * SlingConsts.slingPower;
                    bird.launch(force);
                    world.camCtrl.followBird(bird.body);
                  }
                  setState(() {
                    _dragPointWorld = null;
                    _dragPointScreen = null;
                  });
                }
              },
              onTap: () {
                final bird = world.activeBird;
                bird?.onTapSkill();
              },
              child: CustomPaint(
                foregroundPainter: _SlingPainter(
                  world: world,
                  dragPoint: _dragPointWorld,
                ),
                child: GameWidget(game: world),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  _hudChip(Icons.timer, '${_timeLeft}s'),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _restart, child: const Text('Restart')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MenuPage()),
                            (r) => false,
                      );
                    },
                    child: const Text('Home'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _SlingPainter extends CustomPainter {
  final AngryWorld world;
  final Vector2? dragPoint;

  _SlingPainter({required this.world, this.dragPoint});

  @override
  void paint(Canvas canvas, Size size) {
    final ppm = pixelsPerMeter;
    final slingAnchor = world.slingshotPos;
    final anchorPx = Offset(slingAnchor.x * ppm, slingAnchor.y * ppm);

    final paint = Paint()
      ..color = Colors.brown
      ..strokeWidth = 3;

    // 橡皮筋
    if (dragPoint != null) {
      final dragPx = Offset(dragPoint!.x * ppm, dragPoint!.y * ppm);
      canvas.drawLine(anchorPx + const Offset(-10, -40), dragPx, paint);
      canvas.drawLine(anchorPx + const Offset(10, -40), dragPx, paint);

      // 辅助线
      final points = TrajectoryHelper.predict(
        dragPoint!,
        slingAnchor,
        1 / 60,
      );
      final dotPaint = Paint()..color = Colors.yellow;
      for (final p in points) {
        canvas.drawCircle(
          Offset(p.x * ppm, p.y * ppm),
          2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
