import 'dart:ui';
import 'package:flame/components.dart';
import 'particle.dart';

/// 单个粒子的渲染组件
class ParticleComponent extends PositionComponent {
  final GameParticle data;
  final Paint _paint;

  ParticleComponent(this.data, {Color? color})
      : _paint = Paint()..color = color ?? const Color(0xFFFFFFFF);

  @override
  void update(double dt) {
    super.update(dt);

    // 更新位置
    data.pos += data.vel * dt;
    data.life -= dt;

    // 透明度衰减
    final alpha = (data.life / data.maxLife).clamp(0.0, 1.0);
    _paint.color = _paint.color.withOpacity(alpha);

    if (data.life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final size = (2.0 + 4.0 * (data.life / data.maxLife)); // 粒子大小随时间变化
    canvas.drawCircle(Offset(data.pos.x, data.pos.y), size, _paint);
  }
}
