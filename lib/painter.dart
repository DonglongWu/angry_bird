import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'consts.dart';

class SimplePainter {
  /// 太阳
  static void drawSun(Canvas canvas, Vector2 pos, double radius, {double time = 0}) {
    final ppm = pixelsPerMeter;
    double scale = 1 + 0.05 * sin(time * 2);
    final paint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(
      Offset(pos.x * ppm, pos.y * ppm),
      radius * ppm * scale,
      paint,
    );

    final haloPaint = Paint()
      ..color = const Color(0x88FFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      double a = time + i * 2 * pi / 12;
      double x = pos.x * ppm + cos(a) * (radius * ppm + 15);
      double y = pos.y * ppm + sin(a) * (radius * ppm + 15);
      canvas.drawCircle(Offset(x, y), 3, haloPaint);
    }
  }

  /// 云朵
  static void drawCloud(Canvas canvas, Vector2 pos, double size) {
    final ppm = pixelsPerMeter;
    final cx = pos.x * ppm;
    final cy = pos.y * ppm;
    final s = size * ppm;

    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: s * 2, height: s * 1.2), paint);
    canvas.drawCircle(Offset(cx - s, cy), s * 0.7, paint);
    canvas.drawCircle(Offset(cx + s, cy), s * 0.7, paint);
  }

  /// 草地
  static void drawGrass(Canvas canvas, Vector2 pos, double width, double height) {
    final ppm = pixelsPerMeter;
    final rect = Rect.fromLTWH(
      pos.x * ppm,
      pos.y * ppm,
      width * ppm,
      height * ppm,
    );

    final basePaint = Paint()..color = const Color(0xFF228B22);
    canvas.drawRect(rect, basePaint);

    final stripePaint = Paint()
      ..color = const Color(0xFF006400)
      ..strokeWidth = 1;
    for (double x = rect.left; x < rect.right; x += 4) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), stripePaint);
    }
  }

  /// 花
  static void drawFlower(Canvas canvas, Vector2 pos, double size, {double time = 0}) {
    final ppm = pixelsPerMeter;
    final cx = pos.x * ppm;
    final cy = pos.y * ppm;
    final s = size * ppm;

    double sway = 0.2 * sin(time * 3 + pos.x * 0.05);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(sway);

    final petalPaint = Paint()..color = const Color(0xFFFF69B4);
    for (int i = 0; i < 5; i++) {
      final angle = i * 72 * pi / 180;
      final dx = s * 1.6 * cos(angle);
      final dy = s * 1.6 * sin(angle);
      canvas.drawOval(Rect.fromCircle(center: Offset(dx, dy), radius: s * 0.9), petalPaint);
    }

    final centerPaint = Paint()..color = const Color(0xFFFFFF00);
    canvas.drawCircle(Offset.zero, s * 0.9, centerPaint);

    canvas.restore();
  }

  /// 石头
  static void drawRock(Canvas canvas, Vector2 pos, double radius, {int edges = 12, int seed = 42}) {
    final ppm = pixelsPerMeter;
    final rnd = Random(seed);
    final path = Path();
    final paint = Paint()..color = const Color(0xFF808080);

    final cx = pos.x * ppm;
    final cy = pos.y * ppm;
    final r0 = radius * ppm;

    for (int i = 0; i < edges; i++) {
      final angle = (i / edges) * 2 * pi;
      final r = r0 * (0.85 + rnd.nextDouble() * 0.3);
      final dx = cx + r * cos(angle);
      final dy = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 弹弓（米制，height 为高度）
  static void drawSlingshot(Canvas canvas, Vector2 pos, double heightMeters, {Vector2? pullPoint}) {
    final ppm = pixelsPerMeter;
    final cx = pos.x * ppm;
    final cy = pos.y * ppm;
    final height = heightMeters * ppm;

    final polePaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..strokeWidth = 0.1 * ppm
      ..strokeCap = StrokeCap.round;

    final bandPaint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 0.05 * ppm;

    final leftPole = Offset(cx - 0.1 * ppm, cy - height);
    final rightPole = Offset(cx + 0.1 * ppm, cy - height);
    final base = Offset(cx, cy);

    canvas.drawLine(base, leftPole, polePaint);
    canvas.drawLine(base, rightPole, polePaint);

    if (pullPoint != null) {
      final pull = Offset(pullPoint.x * ppm, pullPoint.y * ppm);
      canvas.drawLine(leftPole, pull, bandPaint);
      canvas.drawLine(rightPole, pull, bandPaint);
    } else {
      canvas.drawLine(leftPole, rightPole, bandPaint);
    }

    final basePaint = Paint()..color = const Color(0xFF5C3317);
    canvas.drawCircle(base, 0.2 * ppm, basePaint);
  }
}
