// physics.dart
// ------------------------------------------------------------
// Minimal 2D physics with rotation for oriented rectangles.
// - CircleBody, RectBody (AABB), RotRectBody(支持旋转)
// - Integrate linear + angular
// - Circle↔Circle / Circle↔AABB / AABB↔AABB
// - Circle↔OBB / OBB↔AABB / OBB↔OBB  (OBB = RotRectBody)
// - Bounds for OBB 采用世界AABB近似
// - Rest clamp & sleeping
// ------------------------------------------------------------
import 'dart:math' as math;

// ---------------- Vec2 ----------------
class Vec2 {
  double x, y;
  Vec2(this.x, this.y);

  Vec2 operator +(Vec2 o) => Vec2(x + o.x, y + o.y);
  Vec2 operator -(Vec2 o) => Vec2(x - o.x, y - o.y);
  Vec2 operator *(double s) => Vec2(x * s, y * s);
  Vec2 operator /(double s) => Vec2(x / s, y / s);

  double get length => math.sqrt(x * x + y * y);
  void clampLength(double maxLen) {
    final len = length;
    if (len > maxLen && len > 0) {
      final k = maxLen / len;
      x *= k; y *= k;
    }
  }
}

double _dot(Vec2 a, Vec2 b) => a.x * b.x + a.y * b.y;
double _cross(Vec2 a, Vec2 b) => a.x * b.y - a.y * b.x; // z 分量标量
Vec2 _perp(Vec2 v) => Vec2(-v.y, v.x);

// --------------- AABB -----------------
class AABB {
  final double left, top, right, bottom;
  const AABB({required this.left, required this.top, required this.right, required this.bottom});
}

// --------------- Bodies ---------------
abstract class Body {
  Vec2 pos;
  Vec2 vel;
  Vec2 acc;
  double mass;

  Body({required this.pos, Vec2? vel, Vec2? acc, required this.mass})
      : vel = vel ?? Vec2(0, 0),
        acc = acc ?? Vec2(0, 0);
}

class CircleBody extends Body {
  double radius;
  CircleBody({required super.pos, required this.radius, super.vel, super.acc, required super.mass});
}

class RectBody extends Body {
  Vec2 halfSize; // AABB
  RectBody({required super.pos, required this.halfSize, super.vel, super.acc, required super.mass});
}

/// 可旋转的矩形（屋梁等）
class RotRectBody extends Body {
  Vec2 halfSize;
  double angle;         // 弧度
  double angVel;        // 角速度 (rad/s)
  double angAcc;        // 角加速度（由力矩产生）
  final double inertia; // 转动惯量
  final bool fixedRotation;
  double angularDamping;

  RotRectBody({
    required super.pos,
    required this.halfSize,
    required this.angle,
    super.vel,
    super.acc,
    required super.mass,
    this.angVel = 0,
    this.angAcc = 0,
    this.fixedRotation = false,
    this.angularDamping = 0.10, // 较轻的角阻尼
  }) : inertia = (mass * (((halfSize.x * 2) * (halfSize.x * 2)) +
      ((halfSize.y * 2) * (halfSize.y * 2)))) /
      12.0;
}

// ------------ local/world helpers ------------
Vec2 _rot(Vec2 v, double a) {
  final c = math.cos(a), s = math.sin(a);
  return Vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

Vec2 _invRot(Vec2 v, double a) {
  final c = math.cos(a), s = math.sin(a);
  return Vec2(c * v.x + s * v.y, -s * v.x + c * v.y);
}

Vec2 _toLocal(Vec2 world, RotRectBody r) => _invRot(world - r.pos, r.angle);
Vec2 _toWorld(Vec2 local, RotRectBody r) => r.pos + _rot(local, r.angle);

// --------------- Integrate ----------------
void clampVelocity(Body b, double maxSpeed) => b.vel.clampLength(maxSpeed);

void integrate(Body b, double dt) {
  // 线性
  b.vel = b.vel + b.acc * dt;
  b.pos = b.pos + b.vel * dt;

  // 角度（仅 RotRect）
  if (b is RotRectBody && !b.fixedRotation) {
    b.angVel += b.angAcc * dt;
    // 简单角阻尼
    final damp = (1.0 - (b.angularDamping * dt)).clamp(0.0, 1.0);
    b.angVel *= damp;
    b.angle += b.angVel * dt;
    b.angAcc = 0; // 每帧清零，由碰撞产生新的力矩
  }
}

// --------------- Bounds ----------------
void collideWithBoundsCircle(CircleBody b, AABB box, double restitution, double floorFriction) {
  if (b.pos.x - b.radius < box.left)  { b.pos.x = box.left + b.radius;  b.vel.x = -b.vel.x * restitution; }
  if (b.pos.x + b.radius > box.right) { b.pos.x = box.right - b.radius; b.vel.x = -b.vel.x * restitution; }
  if (b.pos.y - b.radius < box.top)   { b.pos.y = box.top + b.radius;   b.vel.y = -b.vel.y * restitution; }
  if (b.pos.y + b.radius > box.bottom){
    b.pos.y = box.bottom - b.radius;  b.vel.y = -b.vel.y * restitution;
    b.vel.x *= (1.0 - floorFriction).clamp(0.0, 1.0);
    if (b.vel.length < 0.5) b.vel = Vec2(0, 0);
  }
}

void collideWithBoundsRect(RectBody r, AABB box, double restitution, double floorFriction) {
  final left   = r.pos.x - r.halfSize.x;
  final right  = r.pos.x + r.halfSize.x;
  final top    = r.pos.y - r.halfSize.y;
  final bottom = r.pos.y + r.halfSize.y;

  if (left < box.left)     { r.pos.x = box.left + r.halfSize.x;   r.vel.x = -r.vel.x * restitution; }
  if (right > box.right)   { r.pos.x = box.right - r.halfSize.x;  r.vel.x = -r.vel.x * restitution; }
  if (top < box.top)       { r.pos.y = box.top + r.halfSize.y;    r.vel.y = -r.vel.y * restitution; }
  if (bottom > box.bottom) {
    r.pos.y = box.bottom - r.halfSize.y; r.vel.y = -r.vel.y * restitution;
    r.vel.x *= (1.0 - floorFriction).clamp(0.0, 1.0);
    if (r.vel.length < 0.5) r.vel = Vec2(0, 0);
  }
}

/// OBB 的边界用其世界AABB近似
void collideWithBoundsRotRect(RotRectBody r, AABB box, double restitution, double floorFriction) {
  final cornersLocal = <Vec2>[
    Vec2(-r.halfSize.x, -r.halfSize.y),
    Vec2( r.halfSize.x, -r.halfSize.y),
    Vec2( r.halfSize.x,  r.halfSize.y),
    Vec2(-r.halfSize.x,  r.halfSize.y),
  ];
  double minX = double.infinity, maxX = -double.infinity;
  double minY = double.infinity, maxY = -double.infinity;
  for (final c in cornersLocal) {
    final w = _toWorld(c, r);
    if (w.x < minX) minX = w.x; if (w.x > maxX) maxX = w.x;
    if (w.y < minY) minY = w.y; if (w.y > maxY) maxY = w.y;
  }

  if (minX < box.left)  { final dx = box.left - minX;  r.pos.x += dx; r.vel.x = -r.vel.x * restitution; }
  if (maxX > box.right) { final dx = maxX - box.right; r.pos.x -= dx; r.vel.x = -r.vel.x * restitution; }
  if (minY < box.top)   { final dy = box.top - minY;   r.pos.y += dy; r.vel.y = -r.vel.y * restitution; }
  if (maxY > box.bottom){
    final dy = maxY - box.bottom; r.pos.y -= dy; r.vel.y = -r.vel.y * restitution;
    r.vel.x *= (1.0 - floorFriction).clamp(0.0, 1.0);
    if (r.vel.length < 0.5) r.vel = Vec2(0, 0);
  }
}

// --------------- Collisions (returns impulse j>=0) ---------------
double resolveCircleCircle(CircleBody a, CircleBody b, double e) {
  final n = b.pos - a.pos;
  final dist = n.length;
  final r = a.radius + b.radius;
  if (dist == 0 || dist >= r) return 0.0;

  final normal = dist == 0 ? Vec2(1, 0) : n / dist;
  final penetration = r - dist;

  final totalMass = a.mass + b.mass;
  final corrA = normal * (-penetration * (b.mass / totalMass));
  final corrB = normal * ( penetration * (a.mass / totalMass));
  a.pos = a.pos + corrA;
  b.pos = b.pos + corrB;

  final relVel = b.vel - a.vel;
  final vn = _dot(relVel, normal);
  if (vn > 0) return 0.0;

  final j = -(1 + e) * vn / (1 / a.mass + 1 / b.mass);
  final impulse = normal * j;
  a.vel = a.vel - impulse * (1 / a.mass);
  b.vel = b.vel + impulse * (1 / b.mass);
  return j.abs();
}

double resolveCircleRect(CircleBody c, RectBody r, double e) {
  final dx = (c.pos.x - r.pos.x).clamp(-r.halfSize.x, r.halfSize.x);
  final dy = (c.pos.y - r.pos.y).clamp(-r.halfSize.y, r.halfSize.y);
  final closest = Vec2(r.pos.x + dx, r.pos.y + dy);
  final n = c.pos - closest;
  final dist = n.length;
  if (dist >= c.radius || dist == 0) return 0.0;

  final normal = n / dist;
  final penetration = c.radius - dist;

  final totalMass = c.mass + r.mass;
  final corrC = normal * ( penetration * (r.mass / totalMass));
  final corrR = normal * (-penetration * (c.mass / totalMass));
  c.pos = c.pos + corrC;
  r.pos = r.pos + corrR;

  final relVel = r.vel - c.vel;
  final vn = _dot(relVel, normal);
  if (vn > 0) return 0.0;

  final j = -(1 + e) * vn / (1 / c.mass + 1 / r.mass);
  final impulse = normal * j;
  c.vel = c.vel - impulse * (1 / c.mass);
  r.vel = r.vel + impulse * (1 / r.mass);
  return j.abs();
}

double resolveRectRect(RectBody a, RectBody b, double e) {
  final dx = b.pos.x - a.pos.x;
  final px = (a.halfSize.x + b.halfSize.x) - dx.abs();
  if (px <= 0) return 0.0;

  final dy = b.pos.y - a.pos.y;
  final py = (a.halfSize.y + b.halfSize.y) - dy.abs();
  if (py <= 0) return 0.0;

  Vec2 normal;
  double penetration;
  if (px < py) {
    normal = Vec2(dx < 0 ? -1 : 1, 0);
    penetration = px;
  } else {
    normal = Vec2(0, dy < 0 ? -1 : 1);
    penetration = py;
  }

  final totalMass = a.mass + b.mass;
  final corrA = normal * (-penetration * (b.mass / totalMass));
  final corrB = normal * ( penetration * (a.mass / totalMass));
  a.pos = a.pos + corrA;
  b.pos = b.pos + corrB;

  final relVel = b.vel - a.vel;
  final vn = _dot(relVel, normal);
  if (vn > 0) return 0.0;

  final j = -(1 + e) * vn / (1 / a.mass + 1 / b.mass);
  final impulse = normal * j;
  a.vel = a.vel - impulse * (1 / a.mass);
  b.vel = b.vel + impulse * (1 / b.mass);

  return j.abs();
}

/// Circle ↔ OBB（带力矩 -> 梁会旋转）
double resolveCircleRotRect(CircleBody c, RotRectBody r, double e) {
  final cLocal = _toLocal(c.pos, r);
  final dx = cLocal.x.clamp(-r.halfSize.x, r.halfSize.x);
  final dy = cLocal.y.clamp(-r.halfSize.y, r.halfSize.y);
  final closestLocal = Vec2(dx, dy);
  final nLocal = cLocal - closestLocal;
  final dist = nLocal.length;
  if (dist == 0 || dist >= c.radius) return 0.0;

  final normalLocal = nLocal / dist;
  final normalWorld = _rot(normalLocal, r.angle);
  final penetration = c.radius - dist;

  final totalMass = c.mass + r.mass;
  final corrC = normalWorld * ( penetration * (r.mass / totalMass));
  final corrR = normalWorld * (-penetration * (c.mass / totalMass));
  c.pos = c.pos + corrC;
  r.pos = r.pos + corrR;

  final relVel = r.vel - c.vel;
  final vn = _dot(relVel, normalWorld);
  if (vn > 0) return 0.0;

  final j = -(1 + e) * vn / (1 / c.mass + 1 / r.mass);
  final impulse = normalWorld * j;

  // 线性
  c.vel = c.vel - impulse * (1 / c.mass);
  r.vel = r.vel + impulse * (1 / r.mass);

  // 力矩 -> 角速度（用接触点）
  final contactWorld = _toWorld(closestLocal, r);
  final lever = contactWorld - r.pos;                 // r 向量
  final tau = _cross(lever, impulse);                 // τ = r × J
  if (!r.fixedRotation && r.inertia > 0) {
    r.angVel += tau / r.inertia;
  }
  return j.abs();
}

// 计算 OBB 在某轴上的投影半径
double _projRadiusOBB(RotRectBody a, Vec2 axis) {
  final ux = Vec2(math.cos(a.angle), math.sin(a.angle));
  final uy = Vec2(-math.sin(a.angle), math.cos(a.angle));
  return a.halfSize.x * _dot(ux, axis).abs() + a.halfSize.y * _dot(uy, axis).abs();
}

/// OBB ↔ AABB
double resolveRotRectRect(RotRectBody a, RectBody b, double e) {
  // 轴集合：a 的两个局部轴 + 世界 x/y
  final axes = <Vec2>[
    Vec2(math.cos(a.angle), math.sin(a.angle)),
    Vec2(-math.sin(a.angle), math.cos(a.angle)),
    Vec2(1, 0),
    Vec2(0, 1),
  ];

  double minOverlap = double.infinity;
  Vec2? bestAxis;
  double bestSign = 1.0;

  for (final axis in axes) {
    final L = axis; // axis 已经是单位向量
    final c1 = _dot(a.pos, L);
    final c2 = _dot(b.pos, L);
    final r1 = _projRadiusOBB(a, L);
    final r2 = b.halfSize.x * L.x.abs() + b.halfSize.y * L.y.abs();
    final dist = (c2 - c1).abs();
    final overlap = (r1 + r2) - dist;
    if (overlap <= 0) return 0.0;
    if (overlap < minOverlap) {
      minOverlap = overlap;
      bestAxis = L;
      bestSign = (c2 >= c1) ? 1.0 : -1.0;
    }
  }

  final normal = Vec2(bestAxis!.x * bestSign, bestAxis.y * bestSign);
  final penetration = minOverlap;

  // 质量分担位置修正
  final totalMass = a.mass + b.mass;
  a.pos = a.pos - normal * (penetration * (b.mass / totalMass));
  b.pos = b.pos + normal * (penetration * (a.mass / totalMass));

  // 速度沿法线
  final relVel = b.vel - a.vel;
  final vn = _dot(relVel, normal);
  if (vn > 0) return 0.0;

  final j = -(1 + e) * vn / (1 / a.mass + 1 / b.mass);
  final impulse = normal * j;

  a.vel = a.vel - impulse * (1 / a.mass);
  b.vel = b.vel + impulse * (1 / b.mass);

  // 给 OBB 一个力矩：接触点取 b 的中心在 a 的最近点
  final ux = Vec2(math.cos(a.angle), math.sin(a.angle));
  final uy = Vec2(-math.sin(a.angle), math.cos(a.angle));
  final d = b.pos - a.pos;
  final lx = _dot(d, ux).clamp(-a.halfSize.x, a.halfSize.x);
  final ly = _dot(d, uy).clamp(-a.halfSize.y, a.halfSize.y);
  final contactLocal = Vec2(lx, ly);
  final contactWorld = _toWorld(contactLocal, a);
  final lever = contactWorld - a.pos;
  final tau = _cross(lever, impulse);
  if (!a.fixedRotation && a.inertia > 0) {
    a.angVel += tau / a.inertia;
  }
  return j.abs();
}

/// OBB ↔ OBB
double resolveRotRectRotRect(RotRectBody a, RotRectBody b, double e) {
  final axes = <Vec2>[
    Vec2(math.cos(a.angle), math.sin(a.angle)),
    Vec2(-math.sin(a.angle), math.cos(a.angle)),
    Vec2(math.cos(b.angle), math.sin(b.angle)),
    Vec2(-math.sin(b.angle), math.cos(b.angle)),
  ];

  double minOverlap = double.infinity;
  Vec2? bestAxis;
  double bestSign = 1.0;

  for (final axis in axes) {
    final L = axis; // 单位向量
    final c1 = _dot(a.pos, L);
    final c2 = _dot(b.pos, L);
    final r1 = _projRadiusOBB(a, L);
    final r2 = _projRadiusOBB(b, L);
    final dist = (c2 - c1).abs();
    final overlap = (r1 + r2) - dist;
    if (overlap <= 0) return 0.0;
    if (overlap < minOverlap) {
      minOverlap = overlap;
      bestAxis = L;
      bestSign = (c2 >= c1) ? 1.0 : -1.0;
    }
  }

  final normal = Vec2(bestAxis!.x * bestSign, bestAxis.y * bestSign);
  final penetration = minOverlap;

  // 位置修正
  final totalMass = a.mass + b.mass;
  a.pos = a.pos - normal * (penetration * (b.mass / totalMass));
  b.pos = b.pos + normal * (penetration * (a.mass / totalMass));

  // 冲量
  final relVel = b.vel - a.vel;
  final vn = _dot(relVel, normal);
  if (vn > 0) return 0.0;

  final j = -(1 + e) * vn / (1 / a.mass + 1 / b.mass);
  final impulse = normal * j;

  a.vel = a.vel - impulse * (1 / a.mass);
  b.vel = b.vel + impulse * (1 / b.mass);

  // 力矩：接触点粗略取“对方中心在本OBB的最近点”
  Vec2 contactOnA() {
    final ux = Vec2(math.cos(a.angle), math.sin(a.angle));
    final uy = Vec2(-math.sin(a.angle), math.cos(a.angle));
    final d = b.pos - a.pos;
    final lx = _dot(d, ux).clamp(-a.halfSize.x, a.halfSize.x);
    final ly = _dot(d, uy).clamp(-a.halfSize.y, a.halfSize.y);
    return _toWorld(Vec2(lx, ly), a);
  }

  Vec2 contactOnB() {
    final ux = Vec2(math.cos(b.angle), math.sin(b.angle));
    final uy = Vec2(-math.sin(b.angle), math.cos(b.angle));
    final d = a.pos - b.pos;
    final lx = _dot(d, ux).clamp(-b.halfSize.x, b.halfSize.x);
    final ly = _dot(d, uy).clamp(-b.halfSize.y, b.halfSize.y);
    return _toWorld(Vec2(lx, ly), b);
  }

  final ca = contactOnA();
  final cb = contactOnB();
  final ra = ca - a.pos;
  final rb = cb - b.pos;

  final tauA = _cross(ra, impulse);
  final tauB = _cross(rb, impulse * -1); // 对 B 方向相反

  if (!a.fixedRotation && a.inertia > 0) a.angVel += tauA / a.inertia;
  if (!b.fixedRotation && b.inertia > 0) b.angVel += tauB / b.inertia;

  return j.abs();
}

// --------------- Rest clamp & sleeping ---------------
void clampToRest(Body b, {required AABB box, double threshold = 1.0, double eps = 0.5}) {
  bool touchingBoundary = false;

  if (b is CircleBody) {
    touchingBoundary = (b.pos.y + b.radius >= box.bottom - eps) ||
        (b.pos.y - b.radius <= box.top + eps)    ||
        (b.pos.x - b.radius <= box.left + eps)   ||
        (b.pos.x + b.radius >= box.right + eps);
  } else if (b is RectBody) {
    final left   = b.pos.x - b.halfSize.x;
    final right  = b.pos.x + b.halfSize.x;
    final top    = b.pos.y - b.halfSize.y;
    final bottom = b.pos.y + b.halfSize.y;
    touchingBoundary = (bottom >= box.bottom - eps) ||
        (top    <= box.top + eps)    ||
        (left   <= box.left + eps)   ||
        (right  >= box.right - eps);
  } else if (b is RotRectBody) {
    final corners = <Vec2>[
      Vec2(-b.halfSize.x, -b.halfSize.y),
      Vec2( b.halfSize.x, -b.halfSize.y),
      Vec2( b.halfSize.x,  b.halfSize.y),
      Vec2(-b.halfSize.x,  b.halfSize.y),
    ].map((c) => _toWorld(c, b));
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final w in corners) {
      if (w.x < minX) minX = w.x; if (w.x > maxX) maxX = w.x;
      if (w.y < minY) minY = w.y; if (w.y > maxY) maxY = w.y;
    }
    touchingBoundary = (maxY >= box.bottom - eps) ||
        (minY <= box.top + eps)    ||
        (minX <= box.left + eps)   ||
        (maxX >= box.right - eps);
  }

  final isSlow = b.vel.length < threshold;
  if (isSlow && touchingBoundary) {
    b.vel = Vec2(0, 0);
    if (b is RotRectBody && b.angVel.abs() < 0.2) {
      b.angVel = 0;
    }
  }
}

void clampToRest(
    Body b, {
      required AABB box,
      double threshold = 1.0,
      double eps = 0.5,
      double angThreshold = 0.2,     // 新增：角速度阈值
      double? sleepTimerSec,         // 可选：休眠计时秒数（传 null 则与原一致）
      double? sleepLinearThreshold,  // 可选：配合 sleepTimer 使用的线速度阈值
      void Function()? onSleep,      // 可选回调：进入 sleep
    }) {
  bool touchingBoundary = false;

  if (b is CircleBody) {
    touchingBoundary = (b.pos.y + b.radius >= box.bottom - eps) ||
        (b.pos.y - b.radius <= box.top + eps)    ||
        (b.pos.x - b.radius <= box.left + eps)   ||
        (b.pos.x + b.radius >= box.right - eps);
  } else if (b is RectBody) {
    final left   = b.pos.x - b.halfSize.x;
    final right  = b.pos.x + b.halfSize.x;
    final top    = b.pos.y - b.halfSize.y;
    final bottom = b.pos.y + b.halfSize.y;
    touchingBoundary = (bottom >= box.bottom - eps) ||
        (top    <= box.top + eps)    ||
        (left   <= box.left + eps)   ||
        (right  >= box.right - eps);
  } else if (b is RotRectBody) {
    final corners = <Vec2>[
      Vec2(-b.halfSize.x, -b.halfSize.y),
      Vec2( b.halfSize.x, -b.halfSize.y),
      Vec2( b.halfSize.x,  b.halfSize.y),
      Vec2(-b.halfSize.x,  b.halfSize.y),
    ].map((c) => _toWorld(c, b));
    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;
    for (final w in corners) {
      if (w.x < minX) minX = w.x; if (w.x > maxX) maxX = w.x;
      if (w.y < minY) minY = w.y; if (w.y > maxY) maxY = w.y;
    }
    touchingBoundary = (maxY >= box.bottom - eps) ||
        (minY <= box.top + eps)    ||
        (minX <= box.left + eps)   ||
        (maxX >= box.right - eps);
  }

  final isSlow = b.vel.length < threshold;
  bool angSlow = true;
  if (b is RotRectBody) {
    angSlow = b.angVel.abs() < angThreshold;
  }

  // 原逻辑：只要“慢且触边”就清零
  if (sleepTimerSec == null) {
    if (isSlow && angSlow && touchingBoundary) {
      b.vel = Vec2(0, 0);
      if (b is RotRectBody) b.angVel = 0;
    }
    return;
  }

  // 可选：更自然的 sleep 计时（调用处维护计时器）
  if (isSlow && angSlow && touchingBoundary) {
    // 交给上层：在 world 里积累 sleep 时间，达到秒数再清零
    onSleep?.call();
  }
}
