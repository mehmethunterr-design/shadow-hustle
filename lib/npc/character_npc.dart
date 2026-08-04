import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum NpcArchetype {
  explorer,
  streetRunner,
  farmer,
  forestHunter,
  youngKnight,
  mageApprentice,
  techSpecialist,
}

extension NpcArchetypeData on NpcArchetype {
  String get displayName => switch (this) {
        NpcArchetype.explorer => 'Kaşif Arda',
        NpcArchetype.streetRunner => 'Koşucu Efe',
        NpcArchetype.farmer => 'Çiftçi Can',
        NpcArchetype.forestHunter => 'Avcı Bora',
        NpcArchetype.youngKnight => 'Şövalye Atlas',
        NpcArchetype.mageApprentice => 'Büyücü Mert',
        NpcArchetype.techSpecialist => 'Teknoloji Uzmanı Leo',
      };

  String get dialogue => switch (this) {
        NpcArchetype.explorer =>
          'Ormanın kuzeyinde eski bir sandık gördüm. Sessizce gidersen kimse seni fark etmez.',
        NpcArchetype.streetRunner =>
          'Şehirde hızlı olmak yetmez; doğru sokağı seçmek gerekir. Sana kestirme bir yol gösterebilirim.',
        NpcArchetype.farmer =>
          'Tarlanın yakınında garip ayak izleri var. Gece olunca ortaya çıkıyorlar.',
        NpcArchetype.forestHunter =>
          'Rüzgârın sesini dinle. Tehlike yaklaşırken kuşlar önce susar.',
        NpcArchetype.youngKnight =>
          'Köprünün ötesinde nöbet tutuyorum. Geçmek için cesaretini kanıtlamalısın.',
        NpcArchetype.mageApprentice =>
          'Kırmızı kristaller gölge enerjisi taşıyor. Üç tanesini bulursan onları etkisiz hale getirebilirim.',
        NpcArchetype.techSpecialist =>
          'Eski terminalleri onarırsan bölgedeki güvenlik kameralarını kısa süreliğine kapatabiliriz.',
      };

  Color get primary => switch (this) {
        NpcArchetype.explorer => const Color(0xFF416B3A),
        NpcArchetype.streetRunner => const Color(0xFF24272D),
        NpcArchetype.farmer => const Color(0xFF2F6D99),
        NpcArchetype.forestHunter => const Color(0xFF496B2B),
        NpcArchetype.youngKnight => const Color(0xFF6E8FB5),
        NpcArchetype.mageApprentice => const Color(0xFF4C2C6F),
        NpcArchetype.techSpecialist => const Color(0xFF202C36),
      };

  Color get accent => switch (this) {
        NpcArchetype.explorer => const Color(0xFFB07A3F),
        NpcArchetype.streetRunner => const Color(0xFFD33D36),
        NpcArchetype.farmer => const Color(0xFFD99A3A),
        NpcArchetype.forestHunter => const Color(0xFF8C5B2D),
        NpcArchetype.youngKnight => const Color(0xFF2D72B8),
        NpcArchetype.mageApprentice => const Color(0xFFD5952C),
        NpcArchetype.techSpecialist => const Color(0xFF18C8D8),
      };

  Color get hair => switch (this) {
        NpcArchetype.techSpecialist => const Color(0xFFE2E5F2),
        NpcArchetype.streetRunner => const Color(0xFF202124),
        _ => const Color(0xFF4B3024),
      };
}

class CharacterNpc extends PositionComponent {
  CharacterNpc({
    required super.position,
    required this.archetype,
    this.showQuestMarker = false,
  }) : super(
          size: Vector2(76, 96),
          anchor: Anchor.center,
          priority: 9,
        );

  final NpcArchetype archetype;
  final bool showQuestMarker;

  double _time = 0;
  double _blinkTimer = 1.8;

  String get displayName => archetype.displayName;
  String get dialogue => archetype.dialogue;

  Rect get collisionRect => Rect.fromCenter(
        center: Offset(position.x, position.y + 26),
        width: 38,
        height: 30,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _blinkTimer -= dt;
    if (_blinkTimer < -0.13) {
      _blinkTimer = 2.2 + (archetype.index * 0.31) % 1.8;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bob = math.sin(_time * 2.2 + archetype.index) * 0.9;
    final breathe = 1 + math.sin(_time * 2.0 + archetype.index) * 0.012;

    canvas.drawOval(
      const Rect.fromLTWH(14, 79, 48, 13),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.save();
    canvas.translate(0, bob);
    _drawBackAccessory(canvas);
    _drawLegs(canvas);
    _drawBody(canvas, breathe);
    _drawArms(canvas);
    _drawHead(canvas);
    _drawFrontAccessory(canvas);
    if (showQuestMarker) _drawQuestMarker(canvas);
    canvas.restore();
  }

  void _drawLegs(Canvas canvas) {
    final trousers = Paint()..color = const Color(0xFF303542);
    final boots = Paint()..color = const Color(0xFF22242B);

    for (final x in <double>[23, 43]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 63, 10, 18),
          const Radius.circular(5),
        ),
        trousers,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 1, 76, 13, 7),
          const Radius.circular(4),
        ),
        boots,
      );
    }
  }

  void _drawBody(Canvas canvas, double breathe) {
    canvas.save();
    canvas.translate(38, 49);
    canvas.scale(breathe, breathe);
    canvas.translate(-38, -49);

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(13, 31, 50, 40),
      const Radius.circular(17),
    );
    canvas.drawRRect(body, Paint()..color = archetype.primary);

    canvas.save();
    canvas.clipRRect(body);
    canvas.drawOval(
      const Rect.fromLTWH(13, 29, 27, 44),
      Paint()..color = const Color(0x21FFFFFF),
    );
    canvas.drawOval(
      const Rect.fromLTWH(45, 31, 24, 44),
      Paint()..color = const Color(0x2E000000),
    );
    canvas.restore();

    switch (archetype) {
      case NpcArchetype.explorer:
        canvas.drawRect(
          const Rect.fromLTWH(35, 33, 5, 36),
          Paint()..color = archetype.accent,
        );
        canvas.drawCircle(
          const Offset(28, 47),
          3,
          Paint()..color = const Color(0xFFE0B56E),
        );
        break;
      case NpcArchetype.streetRunner:
        final hoodPaint = Paint()
          ..color = archetype.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawArc(
          const Rect.fromLTWH(21, 28, 34, 22),
          math.pi,
          math.pi,
          false,
          hoodPaint,
        );
        break;
      case NpcArchetype.farmer:
        final blue = Paint()..color = const Color(0xFF3D7CA6);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 35, 28, 34),
            const Radius.circular(7),
          ),
          blue,
        );
        break;
      case NpcArchetype.forestHunter:
        final strap = Paint()
          ..color = archetype.accent
          ..strokeWidth = 6;
        canvas.drawLine(const Offset(21, 34), const Offset(52, 68), strap);
        break;
      case NpcArchetype.youngKnight:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(19, 33, 38, 30),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFFAFC0CF),
        );
        break;
      case NpcArchetype.mageApprentice:
        final robeTrim = Paint()
          ..color = archetype.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(17, 33, 42, 36),
            const Radius.circular(14),
          ),
          robeTrim,
        );
        canvas.drawCircle(
          const Offset(38, 48),
          4,
          Paint()..color = archetype.accent,
        );
        break;
      case NpcArchetype.techSpecialist:
        canvas.drawRect(
          const Rect.fromLTWH(19, 38, 4, 24),
          Paint()..color = archetype.accent,
        );
        canvas.drawRect(
          const Rect.fromLTWH(53, 38, 4, 24),
          Paint()..color = archetype.accent,
        );
        canvas.drawCircle(
          const Offset(38, 48),
          5,
          Paint()..color = archetype.accent,
        );
        break;
    }

    canvas.restore();
  }

  void _drawArms(Canvas canvas) {
    final skin = Paint()..color = const Color(0xFFFFC9A5);
    final sleeve = Paint()..color = archetype.primary;

    for (final side in <double>[-1, 1]) {
      final x = side < 0 ? 12.0 : 56.0;
      final sway = math.sin(_time * 1.8 + archetype.index) * 0.035 * side;
      canvas.save();
      canvas.translate(x, 39);
      canvas.rotate(sway);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 9, 24),
          const Radius.circular(5),
        ),
        sleeve,
      );
      canvas.drawCircle(const Offset(4.5, 24), 4.5, skin);
      canvas.restore();
    }
  }

  void _drawHead(Canvas canvas) {
    canvas.drawCircle(
      const Offset(38, 22),
      21,
      Paint()..color = const Color(0xFFFFC9A5),
    );
    canvas.drawCircle(
      const Offset(31, 16),
      12,
      Paint()..color = const Color(0xFFFFDFC7),
    );

    _drawHair(canvas);

    final closed = _blinkTimer <= 0;
    final eye = Paint()
      ..color = const Color(0xFF20232B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (closed) {
      canvas.drawLine(const Offset(30, 23), const Offset(34, 23), eye);
      canvas.drawLine(const Offset(42, 23), const Offset(46, 23), eye);
    } else {
      canvas.drawOval(const Rect.fromLTWH(30, 20, 4, 6), eye);
      canvas.drawOval(const Rect.fromLTWH(42, 20, 4, 6), eye);
      canvas.drawCircle(
        const Offset(31.4, 21.3),
        0.7,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        const Offset(43.4, 21.3),
        0.7,
        Paint()..color = Colors.white,
      );
    }

    final smile = Paint()
      ..color = const Color(0xFF8B4B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawArc(
      const Rect.fromLTWH(34, 26, 8, 6),
      0.2,
      math.pi - 0.4,
      false,
      smile,
    );
  }

  void _drawHair(Canvas canvas) {
    final hair = Paint()..color = archetype.hair;
    canvas.drawArc(
      const Rect.fromLTWH(17, 0, 42, 38),
      math.pi,
      math.pi,
      true,
      hair,
    );
    canvas.drawOval(const Rect.fromLTWH(18, 4, 17, 15), hair);
    canvas.drawOval(const Rect.fromLTWH(29, 0, 18, 15), hair);
    canvas.drawOval(const Rect.fromLTWH(42, 4, 16, 16), hair);

    if (archetype == NpcArchetype.farmer) {
      final straw = Paint()..color = const Color(0xFFD9A34B);
      canvas.drawOval(const Rect.fromLTWH(10, -3, 56, 13), straw);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(21, -15, 34, 17),
          const Radius.circular(8),
        ),
        straw,
      );
      canvas.drawRect(
        const Rect.fromLTWH(22, -1, 33, 3),
        Paint()..color = const Color(0xFFB64C36),
      );
    }

    if (archetype == NpcArchetype.techSpecialist) {
      final headphones = Paint()
        ..color = archetype.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        const Rect.fromLTWH(17, 4, 42, 33),
        math.pi,
        math.pi,
        false,
        headphones,
      );
      canvas.drawCircle(
        const Offset(18, 22),
        5,
        Paint()..color = archetype.accent,
      );
      canvas.drawCircle(
        const Offset(58, 22),
        5,
        Paint()..color = archetype.accent,
      );
    }
  }

  void _drawBackAccessory(Canvas canvas) {
    switch (archetype) {
      case NpcArchetype.explorer:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(50, 33, 18, 32),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFF745034),
        );
        break;
      case NpcArchetype.forestHunter:
        canvas.save();
        canvas.translate(58, 33);
        canvas.rotate(-0.35);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2, 0, 5, 48),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF6E4225),
        );
        canvas.restore();
        break;
      case NpcArchetype.youngKnight:
        canvas.save();
        canvas.translate(58, 27);
        canvas.rotate(-0.45);
        canvas.drawRect(
          const Rect.fromLTWH(-2, 0, 4, 48),
          Paint()..color = const Color(0xFFC8D2DC),
        );
        canvas.drawRect(
          const Rect.fromLTWH(-7, 8, 14, 4),
          Paint()..color = const Color(0xFF8D6B2E),
        );
        canvas.restore();
        break;
      case NpcArchetype.mageApprentice:
        canvas.save();
        canvas.translate(61, 18);
        canvas.rotate(-0.12);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2, 0, 5, 60),
            const Radius.circular(3),
          ),
          Paint()..color = const Color(0xFF6D4829),
        );
        canvas.drawCircle(
          const Offset(0, 0),
          7,
          Paint()..color = archetype.accent,
        );
        canvas.restore();
        break;
      default:
        break;
    }
  }

  void _drawFrontAccessory(Canvas canvas) {
    switch (archetype) {
      case NpcArchetype.streetRunner:
        final scarf = Path()
          ..moveTo(21, 31)
          ..lineTo(54, 31)
          ..lineTo(48, 38)
          ..lineTo(26, 38)
          ..close();
        canvas.drawPath(scarf, Paint()..color = archetype.accent);
        break;
      case NpcArchetype.youngKnight:
        canvas.drawCircle(
          const Offset(16, 53),
          12,
          Paint()..color = const Color(0xFF546B85),
        );
        canvas.drawCircle(
          const Offset(16, 53),
          8,
          Paint()..color = archetype.accent,
        );
        break;
      case NpcArchetype.techSpecialist:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 45, 22, 10),
            const Radius.circular(4),
          ),
          Paint()..color = archetype.accent,
        );
        break;
      default:
        break;
    }
  }

  void _drawQuestMarker(Canvas canvas) {
    canvas.drawCircle(
      const Offset(38, -18),
      13,
      Paint()..color = const Color(0xFFFFD84A),
    );
    final marker = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Color(0xFF4A3816),
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    marker.paint(canvas, Offset(38 - marker.width / 2, -30));
  }
}
