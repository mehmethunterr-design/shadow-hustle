import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Player extends PositionComponent {
  Player({
    required super.position,
    Vector2? worldBounds,
  })  : worldBounds = worldBounds ?? Vector2(1800, 1200),
        super(
          size: Vector2(112, 100),
          anchor: Anchor.center,
          priority: 10,
        );

  final Vector2 movement = Vector2.zero();
  final Vector2 keyboardMovement = Vector2.zero();
  final Vector2 joystickMovement = Vector2.zero();
  final math.Random _random = math.Random();

  final double baseSpeed = 245;
  Vector2 worldBounds;

  List<Rect> obstacles = [];
  JoystickComponent? joystick;

  double animationTime = 0;
  double idleTime = 0;
  double blinkTimer = 2.4;
  double blinkAmount = 0;
  double speedBoostRemaining = 0;

  bool facingRight = true;
  bool vehicleMode = false;
  bool turboInstalled = false;

  bool get isMoving => !movement.isZero();

  double get currentSpeed {
    if (vehicleMode) return turboInstalled ? 585 : 500;
    return baseSpeed * (speedBoostRemaining > 0 ? 1.45 : 1);
  }

  void setVehicleMode(bool enabled) {
    vehicleMode = enabled;
    if (!enabled) movement.setZero();
  }

  void applySpeedBoost([double seconds = 20]) {
    speedBoostRemaining = math.max(speedBoostRemaining, seconds);
  }

  void installTurbo() {
    turboInstalled = true;
  }

  void updateKeyboard(Set<LogicalKeyboardKey> keys) {
    keyboardMovement.setZero();

    if (keys.contains(LogicalKeyboardKey.keyW) ||
        keys.contains(LogicalKeyboardKey.arrowUp)) {
      keyboardMovement.y -= 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyS) ||
        keys.contains(LogicalKeyboardKey.arrowDown)) {
      keyboardMovement.y += 1;
    }
    if (keys.contains(LogicalKeyboardKey.keyA) ||
        keys.contains(LogicalKeyboardKey.arrowLeft)) {
      keyboardMovement.x -= 1;
      facingRight = false;
    }
    if (keys.contains(LogicalKeyboardKey.keyD) ||
        keys.contains(LogicalKeyboardKey.arrowRight)) {
      keyboardMovement.x += 1;
      facingRight = true;
    }

    if (!keyboardMovement.isZero()) keyboardMovement.normalize();
  }

  Rect collisionRectAt(Vector2 newPosition) {
    return Rect.fromCenter(
      center: Offset(
        newPosition.x,
        newPosition.y + (vehicleMode ? 8 : 28),
      ),
      width: vehicleMode ? 92 : 36,
      height: vehicleMode ? 48 : 28,
    );
  }

  bool canMoveTo(Vector2 newPosition) {
    final playerRect = collisionRectAt(newPosition);
    for (final obstacle in obstacles) {
      if (playerRect.overlaps(obstacle)) return false;
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    idleTime += dt;
    if (speedBoostRemaining > 0) {
      speedBoostRemaining = math.max(0, speedBoostRemaining - dt);
    }

    blinkTimer -= dt;
    if (blinkTimer <= 0) {
      blinkAmount += dt * 13;
      if (blinkAmount >= 2) {
        blinkAmount = 0;
        blinkTimer = 2.2 + _random.nextDouble() * 2.8;
      }
    }

    joystickMovement.setZero();
    if (joystick != null && joystick!.direction != JoystickDirection.idle) {
      joystickMovement.setFrom(joystick!.relativeDelta);
      if (joystickMovement.x < -0.1) {
        facingRight = false;
      } else if (joystickMovement.x > 0.1) {
        facingRight = true;
      }
    }

    movement.setFrom(
      !joystickMovement.isZero() ? joystickMovement : keyboardMovement,
    );

    animationTime += dt * (isMoving ? (vehicleMode ? 15 : 11.5) : 2.0);

    final displacement = movement * currentSpeed * dt;
    final nextX = Vector2(position.x + displacement.x, position.y);
    if (canMoveTo(nextX)) position.x = nextX.x;

    final nextY = Vector2(position.x, position.y + displacement.y);
    if (canMoveTo(nextY)) position.y = nextY.y;

    final marginX = vehicleMode ? 62.0 : 35.0;
    final marginY = vehicleMode ? 45.0 : 45.0;
    position.x = position.x.clamp(marginX, worldBounds.x - marginX);
    position.y = position.y.clamp(marginY, worldBounds.y - marginY);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (vehicleMode) {
      _drawVehicle(canvas);
      return;
    }

    final walk = isMoving ? math.sin(animationTime) : 0.0;
    final bob = isMoving
        ? -walk.abs() * 3.6
        : math.sin(idleTime * 2) * 0.75;
    final tilt = isMoving
        ? walk * 0.04
        : math.sin(idleTime * 1.3) * 0.008;
    final breathe = isMoving
        ? 1.0
        : 1 + math.sin(idleTime * 2) * 0.014;
    final squashX = isMoving ? 1 + walk.abs() * 0.025 : 1.0;
    final squashY = isMoving ? 1 - walk.abs() * 0.025 : 1.0;

    _drawGroundShadow(canvas, walk);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + bob);
    canvas.rotate(tilt);
    canvas.scale(facingRight ? squashX : -squashX, squashY);
    canvas.translate(-size.x / 2, -size.y / 2);

    _drawCrossedSwords(canvas);
    _drawBackArm(canvas, walk);
    _drawLegs(canvas, walk);
    _drawBody(canvas, breathe);
    _drawFrontArm(canvas, walk);
    _drawHead(canvas);
    _drawHeadbandTails(canvas, walk);

    canvas.restore();
  }

  void _drawVehicle(Canvas canvas) {
    final bounce = isMoving ? math.sin(animationTime) * 1.2 : 0.0;
    canvas.save();
    canvas.translate(0, bounce);

    canvas.drawOval(
      const Rect.fromLTWH(5, 67, 102, 19),
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    if (!facingRight) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final bodyColor = turboInstalled
        ? const Color(0xFF166B8D)
        : const Color(0xFF8E1E23);
    final highlight = turboInstalled
        ? const Color(0xFF35C7FF)
        : const Color(0xFFE23A42);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 38, 104, 36),
        const Radius.circular(14),
      ),
      Paint()..color = bodyColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 19, 58, 33),
        const Radius.circular(13),
      ),
      Paint()..color = bodyColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 23, 42, 20),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF9EDAF0),
    );
    canvas.drawRect(
      const Rect.fromLTWH(55, 23, 4, 20),
      Paint()..color = const Color(0xFF29323B),
    );

    canvas.drawCircle(
      const Offset(36, 32),
      10,
      Paint()..color = const Color(0xFFC9966B),
    );
    canvas.drawArc(
      const Rect.fromLTWH(26, 21, 20, 19),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF171719),
    );
    canvas.drawRect(
      const Rect.fromLTWH(27, 31, 18, 6),
      Paint()..color = const Color(0xFF17191D),
    );

    final tire = Paint()..color = const Color(0xFF15171B);
    for (final x in <double>[25, 87]) {
      canvas.drawCircle(Offset(x, 72), 10, tire);
      canvas.drawCircle(
        Offset(x, 72),
        4,
        Paint()..color = const Color(0xFF9AA3AF),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 47, 12, 9),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFE38A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(99, 47, 9, 9),
        const Radius.circular(4),
      ),
      Paint()..color = highlight,
    );

    if (turboInstalled) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(76, 31, 24, 5),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF35C7FF),
      );
      canvas.drawCircle(
        const Offset(106, 57),
        7,
        Paint()
          ..color = const Color(0x6635C7FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.restore();
  }

  void _drawGroundShadow(Canvas canvas, double walk) {
    final center = Offset(size.x / 2, size.y - 5);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 54 - walk.abs() * 5,
        height: 16,
      ),
      Paint()..color = const Color(0x19000000),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 40 - walk.abs() * 4,
        height: 10,
      ),
      Paint()
        ..color = const Color(0x3B000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawCrossedSwords(Canvas canvas) {
    _drawSword(canvas, const Offset(47, 16), 0.58);
    _drawSword(canvas, const Offset(67, 16), -0.58);
  }

  void _drawSword(Canvas canvas, Offset origin, double angle) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final sheath = Paint()..color = const Color(0xFF20242C);
    final red = Paint()..color = const Color(0xFFB41F24);
    final gold = Paint()..color = const Color(0xFFC99B55);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, 0, 6, 55),
        const Radius.circular(3),
      ),
      sheath,
    );
    canvas.drawRect(const Rect.fromLTWH(-6, 7, 12, 4), gold);
    for (double y = 14; y < 48; y += 9) {
      canvas.drawRect(Rect.fromLTWH(-3, y, 6, 3), red);
    }
    canvas.restore();
  }

  void _drawLegs(Canvas canvas, double walk) {
    final step = isMoving ? walk * 5.8 : 0.0;
    _drawLeg(canvas, const Offset(47, 68), step);
    _drawLeg(canvas, const Offset(67, 68), -step);
  }

  void _drawLeg(Canvas canvas, Offset origin, double swing) {
    final trousers = Paint()..color = const Color(0xFF202329);
    final boots = Paint()..color = const Color(0xFF16181D);
    final red = Paint()..color = const Color(0xFF9F2024);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(swing * 0.034);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, 0, 10, 16),
        const Radius.circular(5),
      ),
      trousers,
    );
    canvas.drawRect(const Rect.fromLTWH(-5, 8, 10, 3), red);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, 13, 14, 8),
        const Radius.circular(4),
      ),
      boots,
    );
    canvas.drawRect(const Rect.fromLTWH(-5, 16, 12, 2), red);
    canvas.restore();
  }

  void _drawBackArm(Canvas canvas, double walk) {
    _drawArm(
      canvas,
      const Offset(37, 43),
      isMoving ? -walk * 0.38 : -0.06,
      false,
    );
  }

  void _drawFrontArm(Canvas canvas, double walk) {
    _drawArm(
      canvas,
      const Offset(77, 43),
      isMoving ? walk * 0.38 : 0.06,
      true,
    );
  }

  void _drawArm(Canvas canvas, Offset shoulder, double angle, bool front) {
    final sleeve = Paint()
      ..color = front
          ? const Color(0xFF25282F)
          : const Color(0xFF1B1D23);
    final glove = Paint()..color = const Color(0xFF17191E);
    final red = Paint()..color = const Color(0xFFB0262B);

    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, 0, 10, 27),
        const Radius.circular(6),
      ),
      sleeve,
    );
    canvas.drawRect(const Rect.fromLTWH(-5, 10, 10, 4), red);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5, 22, 10, 9),
        const Radius.circular(5),
      ),
      glove,
    );
    canvas.restore();
  }

  void _drawBody(Canvas canvas, double breathe) {
    canvas.save();
    canvas.translate(57, 53);
    canvas.scale(breathe, breathe);
    canvas.translate(-57, -53);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 32, 46, 43),
      const Radius.circular(17),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF202329));

    canvas.save();
    canvas.clipRRect(body);
    canvas.drawOval(
      const Rect.fromLTWH(34, 30, 25, 47),
      Paint()..color = const Color(0xFF343840),
    );
    canvas.drawOval(
      const Rect.fromLTWH(65, 31, 22, 47),
      Paint()..color = const Color(0xFF14161B),
    );
    canvas.restore();

    canvas.drawLine(
      const Offset(41, 34),
      const Offset(72, 68),
      Paint()
        ..color = const Color(0xFF8E1E23)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 61, 45, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB3262B),
    );
    canvas.drawCircle(
      const Offset(57, 65),
      5,
      Paint()..color = const Color(0xFFC69A58),
    );

    final hangingSash = Path()
      ..moveTo(58, 68)
      ..lineTo(68, 68)
      ..lineTo(65, 89)
      ..lineTo(56, 78)
      ..close();
    canvas.drawPath(
      hangingSash,
      Paint()..color = const Color(0xFF9B1F24),
    );

    canvas.restore();
  }

  void _drawHead(Canvas canvas) {
    final skin = Paint()..color = const Color(0xFFC9966B);
    canvas.drawCircle(const Offset(57, 23), 22, skin);
    canvas.drawCircle(
      const Offset(50, 17),
      12,
      Paint()..color = const Color(0xFFDDB184),
    );

    final hair = Paint()..color = const Color(0xFF171719);
    canvas.drawArc(
      const Rect.fromLTWH(35, 0, 44, 38),
      math.pi,
      math.pi,
      true,
      hair,
    );
    canvas.drawOval(const Rect.fromLTWH(36, 4, 18, 16), hair);
    canvas.drawOval(const Rect.fromLTWH(49, -1, 19, 17), hair);
    canvas.drawOval(const Rect.fromLTWH(63, 3, 17, 17), hair);

    final mask = Path()
      ..moveTo(37, 25)
      ..quadraticBezierTo(57, 18, 77, 25)
      ..lineTo(74, 39)
      ..quadraticBezierTo(57, 45, 40, 39)
      ..close();
    canvas.drawPath(mask, Paint()..color = const Color(0xFF17191D));
    canvas.drawLine(
      const Offset(40, 28),
      const Offset(74, 28),
      Paint()
        ..color = const Color(0xFFB4262B)
        ..strokeWidth = 2,
    );

    final closed = blinkTimer <= 0 && blinkAmount < 1;
    final eye = Paint()
      ..color = const Color(0xFF231811)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    if (closed) {
      canvas.drawLine(const Offset(48, 23), const Offset(53, 23), eye);
      canvas.drawLine(const Offset(62, 23), const Offset(67, 23), eye);
    } else {
      canvas.drawOval(const Rect.fromLTWH(48, 19, 5, 7), eye);
      canvas.drawOval(const Rect.fromLTWH(62, 19, 5, 7), eye);
      canvas.drawCircle(
        const Offset(49.6, 20.8),
        0.9,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(63.6, 20.8),
        0.9,
        Paint()..color = Colors.white,
      );
    }

    canvas.drawLine(
      const Offset(38, 14),
      const Offset(76, 14),
      Paint()
        ..color = const Color(0xFF9D2025)
        ..strokeWidth = 4,
    );
  }

  void _drawHeadbandTails(Canvas canvas, double walk) {
    final sway = isMoving ? walk * 3 : math.sin(idleTime * 2) * 1.2;
    final red = Paint()
      ..color = const Color(0xFFAA2227)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(76, 14),
      Offset(88, 18 + sway),
      red,
    );
    canvas.drawLine(
      const Offset(76, 16),
      Offset(86, 26 - sway * 0.5),
      red,
    );
  }
}
