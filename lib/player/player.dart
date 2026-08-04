import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Player extends PositionComponent {
  Player({required super.position})
      : super(
          size: Vector2(68, 88),
          anchor: Anchor.center,
          priority: 10,
        );

  final Vector2 movement = Vector2.zero();
  final Vector2 keyboardMovement = Vector2.zero();
  final Vector2 joystickMovement = Vector2.zero();

  final double speed = 230;
  final math.Random _random = math.Random();

  List<Rect> obstacles = [];
  JoystickComponent? joystick;

  double animationTime = 0;
  double idleTime = 0;
  double blinkTimer = 2.4;
  double blinkAmount = 0;
  bool facingRight = true;

  bool get isMoving => !movement.isZero();

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

    if (!keyboardMovement.isZero()) {
      keyboardMovement.normalize();
    }
  }

  Rect collisionRectAt(Vector2 newPosition) {
    return Rect.fromCenter(
      center: Offset(newPosition.x, newPosition.y + 25),
      width: 34,
      height: 26,
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

    if (isMoving) {
      animationTime += dt * 10;
    } else {
      animationTime += dt * 2.2;
    }

    final displacement = movement * speed * dt;
    final nextX = Vector2(position.x + displacement.x, position.y);
    if (canMoveTo(nextX)) position.x = nextX.x;

    final nextY = Vector2(position.x, position.y + displacement.y);
    if (canMoveTo(nextY)) position.y = nextY.y;

    position.x = position.x.clamp(30, 1770);
    position.y = position.y.clamp(40, 1160);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final walk = isMoving ? math.sin(animationTime) : 0.0;
    final bob = isMoving ? walk.abs() * -3.2 : math.sin(idleTime * 2) * 0.8;
    final tilt = isMoving ? walk * 0.045 : math.sin(idleTime * 1.4) * 0.008;
    final breathe = isMoving ? 1.0 : 1 + math.sin(idleTime * 2) * 0.018;
    final squashX = isMoving ? 1 + walk.abs() * 0.025 : 1.0;
    final squashY = isMoving ? 1 - walk.abs() * 0.025 : 1.0;

    _drawGroundShadow(canvas, walk);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + bob);
    canvas.rotate(tilt);
    canvas.scale(facingRight ? squashX : -squashX, squashY);
    canvas.translate(-size.x / 2, -size.y / 2);

    _drawBackArm(canvas, walk);
    _drawLegs(canvas, walk);
    _drawBody(canvas, breathe);
    _drawFrontArm(canvas, walk);
    _drawHead(canvas);

    canvas.restore();
  }

  void _drawGroundShadow(Canvas canvas, double walk) {
    final center = Offset(size.x / 2, size.y - 4);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 50 - walk.abs() * 4, height: 16),
      Paint()..color = const Color(0x18000000),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 38 - walk.abs() * 3, height: 10),
      Paint()
        ..color = const Color(0x30000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawLegs(Canvas canvas, double walk) {
    final step = isMoving ? walk * 5.5 : 0.0;
    final legPaint = Paint()..color = const Color(0xFF35324B);
    final shoePaint = Paint()..color = const Color(0xFF20202A);

    _drawLimb(canvas, const Offset(24, 62), 13, step, legPaint, shoePaint);
    _drawLimb(canvas, const Offset(42, 62), 13, -step, legPaint, shoePaint);
  }

  void _drawLimb(
    Canvas canvas,
    Offset origin,
    double length,
    double swing,
    Paint limb,
    Paint shoe,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(swing * 0.035);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-4.5, 0, 9, length), const Radius.circular(5)),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-5, length - 2, 12, 6), const Radius.circular(4)),
      shoe,
    );
    canvas.restore();
  }

  void _drawBackArm(Canvas canvas, double walk) {
    _drawArm(canvas, const Offset(14, 41), isMoving ? -walk * 0.36 : -0.05, false);
  }

  void _drawFrontArm(Canvas canvas, double walk) {
    _drawArm(canvas, const Offset(54, 41), isMoving ? walk * 0.36 : 0.05, true);
  }

  void _drawArm(Canvas canvas, Offset shoulder, double angle, bool front) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, 0, 10, 25), const Radius.circular(6)),
      Paint()..color = front ? const Color(0xFF6D45E8) : const Color(0xFF5937C7),
    );
    canvas.drawCircle(const Offset(0, 25), 5, Paint()..color = const Color(0xFFFFCBAA));
    canvas.restore();
  }

  void _drawBody(Canvas canvas, double breathe) {
    canvas.save();
    canvas.translate(34, 48);
    canvas.scale(breathe, breathe);
    canvas.translate(-34, -48);

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 31, 44, 39),
      const Radius.circular(18),
    );
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF754CFA));

    canvas.save();
    canvas.clipRRect(bodyRect);
    canvas.drawOval(
      const Rect.fromLTWH(13, 30, 25, 42),
      Paint()..color = const Color(0xFF9A7DFF),
    );
    canvas.drawOval(
      const Rect.fromLTWH(40, 32, 21, 40),
      Paint()..color = const Color(0xFF5E38D8),
    );
    canvas.restore();

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(28, 35, 12, 23), const Radius.circular(8)),
      Paint()..color = const Color(0xFFB29CFF),
    );
    canvas.restore();
  }

  void _drawHead(Canvas canvas) {
    canvas.drawCircle(const Offset(34, 22), 21, Paint()..color = const Color(0xFFFFCFAF));
    canvas.drawCircle(const Offset(27, 17), 12, Paint()..color = const Color(0xFFFFE0C8));

    final hair = Paint()..color = const Color(0xFF3A2A25);
    canvas.drawArc(const Rect.fromLTWH(13, 0, 42, 38), math.pi, math.pi, true, hair);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(15, 7, 11, 19), const Radius.circular(7)),
      hair,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(46, 8, 8, 16), const Radius.circular(6)),
      hair,
    );

    final closed = blinkTimer <= 0 && blinkAmount < 1;
    final eyePaint = Paint()
      ..color = const Color(0xFF20222B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (closed) {
      canvas.drawLine(const Offset(27, 23), const Offset(31, 23), eyePaint);
      canvas.drawLine(const Offset(39, 23), const Offset(43, 23), eyePaint);
    } else {
      canvas.drawOval(const Rect.fromLTWH(27, 20, 4, 6), eyePaint);
      canvas.drawOval(const Rect.fromLTWH(39, 20, 4, 6), eyePaint);
      canvas.drawCircle(const Offset(29, 21.5), 0.8, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(41, 21.5), 0.8, Paint()..color = Colors.white);
    }

    final cheek = Paint()..color = const Color(0xFFFF9D9D);
    canvas.drawOval(const Rect.fromLTWH(20, 27, 7, 4), cheek);
    canvas.drawOval(const Rect.fromLTWH(43, 27, 7, 4), cheek);

    canvas.drawArc(
      const Rect.fromLTWH(31, 25, 8, 7),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFF9B4D4D)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
}
