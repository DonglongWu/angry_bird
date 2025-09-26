// camera.dart
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class CameraController {
  final CameraComponent camera;
  final Vector2 worldSize;
  final double baseZoom;
  final Vector2 gameSize; // 屏幕像素大小

  Vector2? _target;
  double _targetZoom;
  double _lockTime = 0;

  CameraController(this.camera, this.worldSize, this.gameSize, {required this.baseZoom})
      : _targetZoom = baseZoom;

  void update(double dt) {
    if (_lockTime > 0) {
      _lockTime -= dt;
    }

    if (_target != null) {
      final camPos = camera.viewfinder.position;
      var newPos = camPos + (_target! - camPos) * 0.1;

      // 限制相机不跑出边界
      final halfW = (gameSize.x / camera.viewfinder.zoom) / 2;
      final halfH = (gameSize.y / camera.viewfinder.zoom) / 2;

      if (worldSize.x > halfW * 2 && worldSize.y > halfH * 2) {
        newPos = Vector2(
          newPos.x.clamp(halfW, worldSize.x - halfW),
          newPos.y.clamp(halfH, worldSize.y - halfH),
        );
      }

      camera.viewfinder.position = newPos;

      // 平滑缩放
      final camZoom = camera.viewfinder.zoom;
      final newZoom = camZoom + (_targetZoom - camZoom) * 0.1;
      camera.viewfinder.zoom = newZoom;
    }
  }

  /// 跟随鸟（轻微放大）
  void followBird(Body body, {double zoomFactor = 1.1}) {
    if (_lockTime > 0) return;
    _target = body.position;
    _targetZoom = baseZoom * zoomFactor;
  }

  /// 聚焦特效（强烈放大 + 短暂锁定）
  void focusOnEffect(Vector2 pos, {double zoomFactor = 1.5, double lock = 0.8}) {
    _target = pos;
    _targetZoom = baseZoom * zoomFactor;
    _lockTime = lock;
  }

  /// 聚焦弹弓
  void focusOnSlingshot(Vector2 slingPos, {double zoomFactor = 1.0}) {
    if (_lockTime > 0) return;
    _target = slingPos;
    _targetZoom = baseZoom * zoomFactor;
  }

  /// 拉远全局视角
  void resetToOverview() {
    _target = worldSize / 2;
    _targetZoom = baseZoom * 0.8;
  }

  /// 停止跟随
  void stop() {
    _target = null;
  }
}
