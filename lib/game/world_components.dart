import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'game_state.dart';

enum ShopKind {
  ninjaMarket,
  techStore,
  cafe,
  garage,
  arcade,
}

extension ShopKindData on ShopKind {
  String get title => switch (this) {
        ShopKind.ninjaMarket => 'Ninja Market',
        ShopKind.techStore => 'Neon Teknoloji',
        ShopKind.cafe => 'Gece Kafe',
        ShopKind.garage => 'Turbo Garaj',
        ShopKind.arcade => 'Pixel Arcade',
      };

  String get subtitle => switch (this) {
        ShopKind.ninjaMarket => 'Gizlilik ekipmanları',
        ShopKind.techStore => 'Elektronik ve tamir',
        ShopKind.cafe => 'Enerji ve dinlenme',
        ShopKind.garage => 'Araç geliştirmeleri',
        ShopKind.arcade => 'Ödüller ve eğlence',
      };

  Color get accent => switch (this) {
        ShopKind.ninjaMarket => const Color(0xFFE13A42),
        ShopKind.techStore => const Color(0xFF22D3EE),
        ShopKind.cafe => const Color(0xFFFFB24A),
        ShopKind.garage => const Color(0xFF45A3FF),
        ShopKind.arcade => const Color(0xFFB05CFF),
      };

  Color get wall => switch (this) {
        ShopKind.ninjaMarket => const Color(0xFF25232B),
        ShopKind.techStore => const Color(0xFF243747),
        ShopKind.cafe => const Color(0xFFFFD7A0),
        ShopKind.garage => const Color(0xFF445260),
        ShopKind.arcade => const Color(0xFF49355F),
      };

  List<StoreProduct> get products => switch (this) {
        ShopKind.ninjaMarket => const [
            StoreProduct(
              item: GameItem.smokeBomb,
              price: 150,
              description: 'Görevlerde dikkat dağıtmak için.',
            ),
            StoreProduct(
              item: GameItem.energyDrink,
              price: 80,
              description: '20 saniye boyunca daha hızlı koş.',
            ),
          ],
        ShopKind.techStore => const [
            StoreProduct(
              item: GameItem.repairKit,
              price: 190,
              description: 'Teknoloji görevlerinde kullanılabilir.',
            ),
            StoreProduct(
              item: GameItem.energyDrink,
              price: 95,
              description: 'Kısa süreli hareket desteği.',
            ),
          ],
        ShopKind.cafe => const [
            StoreProduct(
              item: GameItem.energyDrink,
              price: 55,
              description: 'Şehrin en ucuz hız takviyesi.',
            ),
          ],
        ShopKind.garage => const [
            StoreProduct(
              item: GameItem.turboKit,
              price: 420,
              description: 'Araca kalıcı turbo görünümü kazandırır.',
            ),
            StoreProduct(
              item: GameItem.repairKit,
              price: 160,
              description: 'Araç ve cihaz onarımları için.',
            ),
          ],
        ShopKind.arcade => const [
            StoreProduct(
              item: GameItem.energyDrink,
              price: 70,
              description: 'Arcade özel seri enerji içeceği.',
            ),
            StoreProduct(
              item: GameItem.smokeBomb,
              price: 180,
              description: 'Nadir mor duman efekti.',
            ),
          ],
      };
}

class RoadComponent extends PositionComponent {
  RoadComponent({
    required super.position,
    required super.size,
    required this.horizontal,
  }) : super(priority: -7);

  final bool horizontal;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF42464F),
    );

    canvas.drawRect(
      horizontal
          ? Rect.fromLTWH(0, 10, size.x, 8)
          : Rect.fromLTWH(10, 0, 8, size.y),
      Paint()..color = const Color(0xFF5A606B),
    );
    canvas.drawRect(
      horizontal
          ? Rect.fromLTWH(0, size.y - 18, size.x, 8)
          : Rect.fromLTWH(size.x - 18, 0, 8, size.y),
      Paint()..color = const Color(0xFF5A606B),
    );

    final lane = Paint()..color = const Color(0xFFE9D47A);
    if (horizontal) {
      for (double x = 24; x < size.x; x += 86) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.y / 2 - 3, 48, 6),
            const Radius.circular(3),
          ),
          lane,
        );
      }
    } else {
      for (double y = 24; y < size.y; y += 86) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(size.x / 2 - 3, y, 6, 48),
            const Radius.circular(3),
          ),
          lane,
        );
      }
    }
  }
}

class DistrictGround extends PositionComponent {
  DistrictGround({
    required super.position,
    required super.size,
    required this.color,
    required this.label,
  }) : super(priority: -8);

  final Color color;
  final String label;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(36),
      ),
      Paint()..color = color,
    );

    final text = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.22),
          fontSize: 38,
          fontWeight: FontWeight.w900,
          letterSpacing: 5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    text.paint(canvas, const Offset(30, 24));
  }
}

class ShopBuilding extends PositionComponent {
  ShopBuilding({
    required super.position,
    required this.kind,
  }) : super(
          size: Vector2(260, 190),
          anchor: Anchor.center,
          priority: 3,
        );

  final ShopKind kind;

  Rect get collisionRect => Rect.fromCenter(
        center: Offset(position.x, position.y + 32),
        width: 226,
        height: 116,
      );

  Vector2 get interactionPoint => Vector2(position.x, position.y + 94);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawOval(
      const Rect.fromLTWH(18, 165, 224, 22),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 54, 224, 118),
        const Radius.circular(18),
      ),
      Paint()..color = kind.wall,
    );

    final roof = Path()
      ..moveTo(8, 66)
      ..lineTo(38, 18)
      ..lineTo(222, 18)
      ..lineTo(252, 66)
      ..close();
    canvas.drawPath(roof, Paint()..color = kind.accent);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(53, 72, 154, 38),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xEE151821),
    );

    final title = TextPainter(
      text: TextSpan(
        text: kind.title,
        style: TextStyle(
          color: kind.accent,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 145);

    title.paint(canvas, Offset(130 - title.width / 2, 81));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(103, 116, 54, 56),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF252C38),
    );

    for (final x in <double>[38, 171]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 119, 48, 34),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xFF9DE6FF),
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 22, 119, 4, 34),
        Paint()..color = const Color(0x66FFFFFF),
      );
    }

    canvas.drawCircle(
      const Offset(146, 145),
      3,
      Paint()..color = kind.accent,
    );
  }
}

class ParkedCar extends PositionComponent {
  ParkedCar({
    required super.position,
    required this.modelName,
    required this.bodyColor,
  }) : super(
          size: Vector2(118, 66),
          anchor: Anchor.center,
          priority: 7,
        );

  final String modelName;
  final Color bodyColor;
  bool occupied = false;

  Rect get collisionRect => Rect.fromCenter(
        center: Offset(position.x, position.y + 8),
        width: 100,
        height: 50,
      );

  @override
  void render(Canvas canvas) {
    if (occupied) return;

    canvas.drawOval(
      const Rect.fromLTWH(8, 44, 102, 18),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    _drawCar(canvas, bodyColor);
  }
}

class TrafficCar extends PositionComponent {
  TrafficCar({
    required super.position,
    required this.horizontal,
    required this.min,
    required this.max,
    required this.speed,
    required this.bodyColor,
  }) : super(
          size: Vector2(108, 60),
          anchor: Anchor.center,
          priority: 6,
        );

  final bool horizontal;
  final double min;
  final double max;
  final double speed;
  final Color bodyColor;

  @override
  void update(double dt) {
    super.update(dt);
    if (horizontal) {
      position.x += speed * dt;
      if (position.x > max) position.x = min;
    } else {
      position.y += speed * dt;
      if (position.y > max) position.y = min;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (!horizontal) {
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(math.pi / 2);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    _drawCar(canvas, bodyColor, compact: true);
    canvas.restore();
  }
}

void _drawCar(Canvas canvas, Color bodyColor, {bool compact = false}) {
  final width = compact ? 102.0 : 110.0;
  final left = compact ? 3.0 : 4.0;

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 20, width, 32),
      const Radius.circular(13),
    ),
    Paint()..color = bodyColor,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 22, 7, width - 44, 30),
      const Radius.circular(12),
    ),
    Paint()..color = bodyColor,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 30, 11, width - 60, 17),
      const Radius.circular(7),
    ),
    Paint()..color = const Color(0xFF9EDAF0),
  );
  canvas.drawRect(
    Rect.fromLTWH(left + width / 2 - 2, 11, 4, 17),
    Paint()..color = const Color(0xFF29323B),
  );

  final tire = Paint()..color = const Color(0xFF17191E);
  canvas.drawCircle(Offset(left + 22, 50), 9, tire);
  canvas.drawCircle(Offset(left + width - 22, 50), 9, tire);
  canvas.drawCircle(
    Offset(left + 22, 50),
    4,
    Paint()..color = const Color(0xFF9AA3AF),
  );
  canvas.drawCircle(
    Offset(left + width - 22, 50),
    4,
    Paint()..color = const Color(0xFF9AA3AF),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left + 4, 28, 10, 8),
      const Radius.circular(4),
    ),
    Paint()..color = const Color(0xFFFFE38A),
  );
}

class ShadowChip extends PositionComponent {
  ShadowChip({required super.position})
      : super(
          size: Vector2.all(48),
          anchor: Anchor.center,
          priority: 5,
        );

  bool collected = false;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final pulse = 1 + math.sin(_time * 4) * 0.08;
    canvas.save();
    canvas.translate(24, 24);
    canvas.scale(pulse, pulse);
    canvas.translate(-24, -24);

    canvas.drawCircle(
      const Offset(24, 24),
      20,
      Paint()
        ..color = const Color(0x449B5CFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final gem = Path()
      ..moveTo(24, 4)
      ..lineTo(40, 17)
      ..lineTo(34, 39)
      ..lineTo(14, 39)
      ..lineTo(8, 17)
      ..close();
    canvas.drawPath(gem, Paint()..color = const Color(0xFF9B5CFF));
    canvas.drawPath(
      Path()
        ..moveTo(24, 7)
        ..lineTo(24, 36)
        ..lineTo(11, 18)
        ..close(),
      Paint()..color = const Color(0xFFC8A8FF),
    );
    canvas.restore();
  }
}

class DeliveryZone extends PositionComponent {
  DeliveryZone({required super.position})
      : super(
          size: Vector2(210, 145),
          anchor: Anchor.center,
          priority: 1,
        );

  double _time = 0;
  bool active = false;

  bool containsPoint(Vector2 point) {
    return Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x,
      height: size.y,
    ).contains(Offset(point.x, point.y));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final alpha = active ? (90 + math.sin(_time * 3) * 30).round() : 24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(24),
      ),
      Paint()..color = Color.fromARGB(alpha, 226, 58, 66),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(24),
      ),
      Paint()
        ..color = active
            ? const Color(0xFFE23A42)
            : const Color(0x557F858F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final text = TextPainter(
      text: TextSpan(
        text: active ? 'TESLİMAT BÖLGESİ' : 'LİMAN',
        style: TextStyle(
          color: active ? Colors.white : Colors.white54,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    text.paint(
      canvas,
      Offset((size.x - text.width) / 2, (size.y - text.height) / 2),
    );
  }
}

class DecorativeTree extends PositionComponent {
  DecorativeTree({required super.position})
      : super(
          size: Vector2(105, 135),
          anchor: Anchor.center,
          priority: 2,
        );

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTWH(15, 108, 78, 20),
      Paint()..color = const Color(0x28000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 65, 20, 55),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF8B5A36),
    );
    canvas.drawCircle(
      const Offset(52, 45),
      41,
      Paint()..color = const Color(0xFF258F50),
    );
    canvas.drawCircle(
      const Offset(34, 35),
      27,
      Paint()..color = const Color(0xFF42C66D),
    );
    canvas.drawCircle(
      const Offset(72, 31),
      25,
      Paint()..color = const Color(0xFF56D77B),
    );
  }
}

class StreetLight extends PositionComponent {
  StreetLight({required super.position})
      : super(
          size: Vector2(42, 112),
          anchor: Anchor.bottomCenter,
          priority: 4,
        );

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(19, 22, 5, 84),
      Paint()..color = const Color(0xFF3D4652),
    );
    canvas.drawCircle(
      const Offset(21.5, 17),
      12,
      Paint()
        ..color = const Color(0x55FFE992)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      const Offset(21.5, 17),
      7,
      Paint()..color = const Color(0xFFFFE992),
    );
    canvas.drawOval(
      const Rect.fromLTWH(12, 103, 19, 6),
      Paint()..color = const Color(0xFF303741),
    );
  }
}

class FountainComponent extends PositionComponent {
  FountainComponent({required super.position})
      : super(
          size: Vector2(180, 135),
          anchor: Anchor.center,
          priority: 2,
        );

  double _time = 0;

  Rect get collisionRect => Rect.fromCenter(
        center: Offset(position.x, position.y + 20),
        width: 150,
        height: 80,
      );

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      const Rect.fromLTWH(10, 55, 160, 65),
      Paint()..color = const Color(0xFF9DA8B4),
    );
    canvas.drawOval(
      const Rect.fromLTWH(20, 60, 140, 48),
      Paint()..color = const Color(0xFF56C8E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(78, 28, 24, 54),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFB8C1CB),
    );
    final splash = math.sin(_time * 5).abs() * 8;
    canvas.drawLine(
      const Offset(90, 28),
      Offset(90, 5 + splash),
      Paint()
        ..color = const Color(0xFFB7F0FF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }
}
