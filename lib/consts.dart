import 'package:flame_forge2d/flame_forge2d.dart'; // 提供 Vector2

// consts.dart
const double pixelsPerMeter = 30.0; // 1 米 = 30 像素

class SlingConsts {
  static const double slingPower = 6.0;        // 发射力度
  static const double slingMaxPull = 320.0;    // 拉伸极限
  static const double maxSpeed = 1000.0;       // 初速度上限
  static final Vector2 gravity = Vector2(0, 20.0); // Forge2D 重力（Y+ 向下）
}

class PhysicsConsts {
  static const double defaultFriction = 0.6;
  static const double defaultRestitution = 0.35;
  static const double sleepLinVel = 0.5;
  static const double sleepAngVel = 0.02;
}

class GameConsts {
  static const int birdsPerLevel = 5;
  static const double levelTime = 60.0; // 秒

  static const double cameraInitZoom = 0.55;
  static const double cameraMinZoom = 0.3;
  static const double cameraMaxZoom = 1.0;

  static const int pigScore = 500;
}

class HpConsts {
  static const double pigNormal = 100;
  static const double pigBoss = 500;

  static const double wood = 60;
  static const double stone = 120;
  static const double glass = 1;
  static const double rock = double.infinity;
  static const double pole = double.infinity;
}

class DamageConsts {
  static const double birdImpactFactor = 0.5;
  static const double impulseFactor = 0.3;
  static const double obstacleMassFactor = 0.5;
}
