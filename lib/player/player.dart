import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Player extends PositionComponent {
  Player({
    required super.position,
  }) : super(
          size: Vector2(58, 76),
          anchor: Anchor.center,
          priority: 10,
        );

  final Vector2 movement = Vector2.zero();
  final Vector2 keyboardMovement = Vector2.zero();
  final Vector2 joystickMovement = Vector2.zero();

  final double speed = 230;

  List<Rect> obstacles = [];

  JoystickComponent? joystick;

  double animationTime = 0;
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
      center: Offset(
        newPosition.x,
        newPosition.y + 22,
      ),
      width: 34,
      height: 26,
    );
  }

  bool canMoveTo(Vector2 newPosition) {
    final playerRect = collisionRectAt(newPosition);

    for (final obstacle in obstacles) {
      if (playerRect.overlaps(obstacle)) {
        return false;
      }
    }

    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    joystickMovement.setZero();

    if (joystick != null &&
        joystick!.direction != JoystickDirection.idle) {
      joystickMovement.setFrom(joystick!.relativeDelta);

      if (joystickMovement.x < -0.1) {
        facingRight = false;
      } else if (joystickMovement.x > 0.1) {
        facingRight = true;
      }
    }

    if (!joystickMovement.isZero()) {
      movement.setFrom(joystickMovement);
    } else {
      movement.setFrom(keyboardMovement);
    }

    if (isMoving) {
      animationTime += dt * 10;
    } else {
      animationTime = 0;
    }

    final displacement = movement * speed * dt;

    final nextX = Vector2(
      position.x + displacement.x,
      position.y,
    );

    if (canMoveTo(nextX)) {
      position.x = nextX.x;
    }

    final nextY = Vector2(
      position.x,
      position.y + displacement.y,
    );

    if (canMoveTo(nextY)) {
      position.y = nextY.y;
    }

    position.x = position.x.clamp(30, 1770);
    position.y = position.y.clamp(40, 1160);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bob = isMoving
        ? math.sin(animationTime) * 3
        : 0.0;

    final tilt = isMoving
        ? math.sin(animationTime) * 0.05
        : 0.0;

    canvas.save();

    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(tilt);

    if (!facingRight) {
      canvas.scale(-1, 1);
    }

    canvas.translate(
      -size.x / 2,
      -size.y / 2 + bob,
    );

    _drawShadow(canvas);
    _drawLegs(canvas);
    _drawBody(canvas);
    _drawHead(canvas);

    canvas.restore();
  }

  void _drawShadow(Canvas canvas) {
    final shadowPaint = Paint()
      ..color = const Color(0x33000000);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          size.x / 2,
          size.y - 3,
        ),
        width: isMoving ? 42 : 46,
        height: 15,
      ),
      shadowPaint,
    );
  }

  void _drawLegs(Canvas canvas) {
    final legPaint = Paint()
      ..color = const Color(0xFF3A3550);

    final step = isMoving
        ? math.sin(animationTime) * 4
        : 0.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          17,
          60 + step,
          9,
          13,
        ),
        const Radius.circular(4),
      ),
      legPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          32,
          60 - step,
          9,
          13,
        ),
        const Radius.circular(4),
      ),
      legPaint,
    );
  }

  void _drawBody(Canvas canvas) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF7D55FF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          7,
          30,
          44,
          38,
        ),
        const Radius.circular(17),
      ),
      bodyPaint,
    );

    final shirtHighlight = Paint()
      ..color = const Color(0xFF9A7BFF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          14,
          34,
          12,
          22,
        ),
        const Radius.circular(8),
      ),
      shirtHighlight,
    );
  }

  void _drawHead(Canvas canvas) {
    final headPaint = Paint()
      ..color = const Color(0xFFFFD6B9);

    canvas.drawCircle(
      const Offset(29, 21),
      19,
      headPaint,
    );

    final hairPaint = Paint()
      ..color = const Color(0xFF49372E);

    canvas.drawArc(
      const Rect.fromLTWH(
        10,
        1,
        38,
        35,
      ),
      3.15,
      3.15,
      true,
      hairPaint,
    );

    final eyePaint = Paint()
      ..color = const Color(0xFF20222B);

    canvas.drawCircle(
      const Offset(23, 21),
      2.2,
      eyePaint,
    );

    canvas.drawCircle(
      const Offset(36, 21),
      2.2,
      eyePaint,
    );

    final cheekPaint = Paint()
      ..color = const Color(0xFFFFA8A8);

    canvas.drawCircle(
      const Offset(18, 27),
      2.5,
      cheekPaint,
    );

    canvas.drawCircle(
      const Offset(40, 27),
      2.5,
      cheekPaint,
    );
  }
}