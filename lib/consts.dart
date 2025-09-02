import 'physics.dart';

class SlingConsts {
  // Physics
  static const double restitution = 0.65;
  static const double floorFriction = 0.12;
  static const double maxSpeed = 1500.0;
  static final Vec2 gravity = Vec2(0.0, 980.0); // 稍小的重力，飞行更长

  // Launch feel
  static const double slingMaxStretch = 260.0; // px
  static const double slingPower = 8.5;        // drag-to-speed

  // Damage & FX
  static const double pigKillImpulse = 160.0;
  static const double crushSpeed = 220.0;
  static const double pigDeathDuration = 0.28;
  static const int pigBurstParticles = 18;

  // Wake-up thresholds
  static const double obstacleWakeImpulse = 14.0;
  static const double obstacleNudge = 20.0;
}

class GameConsts {
  // 关卡与计分
  static const double levelTime = 75.0;
  static const int ballsPerLevel = 5;
  static const int pigScore = 100;
  static const int remainBallBonus = 100;

  // 静止判定阈值（线/角）
  static const double restLinVel = 0.10;
  static const double restHoldSec = 0.60;
  static const double restAngVel = 0.18; // rad/s

  // 世界与相机
  static const double worldPadding = 16.0;
  static const double worldExtraWidth = 2400.0; // 额外向右扩展的长度
  static const double cameraInitZoom = 0.9;     // 初始缩放(1=不缩放)
  static const double cameraMinZoom = 0.65;
  static const double cameraMaxZoom = 1.2;
  static const double cameraFollowLerp = 0.12;  // 跟随平滑
  static const double cameraLead = 120.0;       // 视野领先量（朝鸟速度方向）
  static const double cameraBirdEdgeInset = 140.0; // 自动拉远时的边距

  // 技能鸟
  static const double dashMultiplier = 1.65; // 冲刺倍率
  static const double splitAngleDeg = 16.0;  // 分裂两翼角度
  static const double splitSpeedFactor = 0.92;
  static const double splitRadius = 12.0;    // 分身半径

}
