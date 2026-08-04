import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'game_state.dart';
import 'world_components.dart';

class PremiumHud extends PositionComponent {
  PremiumHud({
    required this.progress,
    required this.timeLabel,
    required this.isDriving,
    required this.boostSeconds,
  }) : super(anchor: Anchor.topLeft, priority: 150);

  final GameProgress progress;
  final String Function() timeLabel;
  final bool Function() isDriving;
  final double Function() boostSeconds;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawStatusPanel(canvas);
    _drawQuestPanel(canvas);
  }

  void _drawStatusPanel(Canvas canvas) {
    final width = math.min(360.0, size.x - 24).toDouble();
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(14, 14, width, 106),
      const Radius.circular(22),
    );

    canvas.drawRRect(
      panel.shift(const Offset(0, 5)),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xE91A1E28));

    canvas.drawCircle(
      const Offset(55, 56),
      28,
      Paint()..color = const Color(0xFF8E1E23),
    );
    canvas.drawCircle(
      const Offset(55, 56),
      22,
      Paint()..color = const Color(0xFF15171C),
    );

    final levelText = _text(
      'LV ${progress.level}',
      13,
      Colors.white,
      FontWeight.w900,
    );
    levelText.paint(canvas, Offset(55 - levelText.width / 2, 49));

    _text(
      '${progress.coins} ₺',
      20,
      const Color(0xFFFFD768),
      FontWeight.w900,
    ).paint(canvas, const Offset(96, 28));

    _text(
      isDriving() ? 'ARAÇ MODU' : 'GİZEMLİ NİNJA',
      12,
      isDriving() ? const Color(0xFF5ED6FF) : Colors.white70,
      FontWeight.w700,
    ).paint(canvas, const Offset(96, 55));

    final boost = boostSeconds();
    final status = boost > 0
        ? 'Hız takviyesi: ${boost.ceil()} sn'
        : 'Saat ${timeLabel()}';
    _text(
      status,
      12,
      boost > 0 ? const Color(0xFF46E6B2) : Colors.white54,
      FontWeight.w600,
    ).paint(canvas, const Offset(96, 78));

    final barWidth = width - 110;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(96, 99, barWidth, 7),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF343A47),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(96, 99, barWidth * progress.xpProgress, 7),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB05CFF),
    );
  }

  void _drawQuestPanel(Canvas canvas) {
    if (size.x < 760) return;

    const width = 365.0;
    final left = size.x - width - 14;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 14, width, 130),
      const Radius.circular(22),
    );

    canvas.drawRRect(
      panel.shift(const Offset(0, 5)),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xE91A1E28));

    _text(
      'AKTİF GÖREV',
      11,
      const Color(0xFFE23A42),
      FontWeight.w900,
    ).paint(canvas, Offset(left + 20, 27));

    _text(
      progress.questStage.title,
      18,
      Colors.white,
      FontWeight.w900,
    ).paint(canvas, Offset(left + 20, 48));

    final description = TextPainter(
      text: TextSpan(
        text: progress.questStage.description,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: width - 40);

    description.paint(canvas, Offset(left + 20, 75));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + 20, 111, width - 92, 8),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF343A47),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left + 20,
          111,
          (width - 92) * progress.questProgress,
          8,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE23A42),
    );

    _text(
      progress.questProgressText,
      11,
      Colors.white70,
      FontWeight.w800,
    ).paint(canvas, Offset(left + width - 62, 106));
  }

  TextPainter _text(
    String value,
    double size,
    Color color,
    FontWeight weight,
  ) {
    return TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}

class MiniMapComponent extends PositionComponent {
  MiniMapComponent({
    required this.worldSize,
    required this.playerPosition,
    required this.npcPositions,
    required this.shopPositions,
  }) : super(
          size: Vector2(190, 132),
          anchor: Anchor.bottomLeft,
          priority: 145,
        );

  final Vector2 worldSize;
  final Vector2 Function() playerPosition;
  final List<Vector2> Function() npcPositions;
  final List<Vector2> Function() shopPositions;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(18, gameSize.y - 150);
  }

  Offset _map(Vector2 point) {
    return Offset(
      10 + (point.x / worldSize.x) * (size.x - 20),
      10 + (point.y / worldSize.y) * (size.y - 20),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xDB151821),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 5, size.x - 10, size.y - 10),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFF294A3B),
    );

    for (final shop in shopPositions()) {
      final p = _map(shop);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: p, width: 8, height: 8),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFFFC857),
      );
    }

    for (final npc in npcPositions()) {
      canvas.drawCircle(
        _map(npc),
        3,
        Paint()..color = const Color(0xFF8ED0FF),
      );
    }

    final player = _map(playerPosition());
    canvas.drawCircle(
      player,
      7,
      Paint()..color = const Color(0x66E23A42),
    );
    canvas.drawCircle(
      player,
      4,
      Paint()..color = const Color(0xFFE23A42),
    );
  }
}

class ActionButton extends PositionComponent with TapCallbacks {
  ActionButton({required this.onPressed})
      : super(
          size: Vector2(108, 108),
          anchor: Anchor.bottomRight,
          priority: 170,
        );

  final VoidCallback onPressed;
  bool enabled = false;
  String label = '...';
  String icon = '●';

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = Vector2(gameSize.x - 28, gameSize.y - 28);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (enabled) onPressed();
  }

  @override
  void render(Canvas canvas) {
    final outer = enabled
        ? const Color(0xFF8E1E23)
        : const Color(0x775D6170);
    final inner = enabled
        ? const Color(0xFFCB3038)
        : const Color(0x665D6170);

    canvas.drawCircle(
      const Offset(54, 54),
      52,
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawCircle(const Offset(54, 51), 49, Paint()..color = outer);
    canvas.drawCircle(const Offset(54, 51), 38, Paint()..color = inner);

    final iconPainter = _text(
      icon,
      24,
      enabled ? Colors.white : Colors.white38,
      FontWeight.w900,
    );
    iconPainter.paint(
      canvas,
      Offset(54 - iconPainter.width / 2, 30),
    );

    final labelPainter = _text(
      label,
      10,
      enabled ? Colors.white : Colors.white38,
      FontWeight.w900,
    );
    labelPainter.paint(
      canvas,
      Offset(54 - labelPainter.width / 2, 70),
    );
  }

  TextPainter _text(
    String text,
    double size,
    Color color,
    FontWeight weight,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}

class DialogueBox extends PositionComponent with TapCallbacks {
  DialogueBox({required this.onClose})
      : super(anchor: Anchor.bottomCenter, priority: 220);

  final VoidCallback onClose;
  bool visible = false;
  String speaker = '';
  String message = '';
  Color accent = const Color(0xFFE23A42);

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    final width = gameSize.x > 760 ? 680.0 : gameSize.x - 26;
    size = Vector2(width, 190);
    position = Vector2(gameSize.x / 2, gameSize.y - 18);
  }

  void show({
    required String speaker,
    required String message,
    Color accent = const Color(0xFFE23A42),
  }) {
    this.speaker = speaker;
    this.message = message;
    this.accent = accent;
    visible = true;
  }

  void hide() {
    visible = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (visible) onClose();
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y - 8),
      const Radius.circular(26),
    );
    canvas.drawRRect(
      rect.shift(const Offset(0, 7)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xF51A1E28));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      const Offset(62, 72),
      40,
      Paint()..color = accent,
    );
    canvas.drawCircle(
      const Offset(62, 64),
      21,
      Paint()..color = const Color(0xFFFFC9A5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 85, 46, 27),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF242933),
    );

    _text(
      speaker,
      20,
      accent,
      FontWeight.w900,
    ).paint(canvas, const Offset(120, 27));

    final messagePainter = TextPainter(
      text: TextSpan(
        text: message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
    )..layout(maxWidth: size.x - 155);

    messagePainter.paint(canvas, const Offset(120, 62));

    _text(
      'Devam etmek için dokun',
      11,
      Colors.white38,
      FontWeight.w600,
    ).paint(canvas, Offset(size.x - 185, size.y - 35));
  }

  TextPainter _text(
    String text,
    double size,
    Color color,
    FontWeight weight,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}

class ShopPanel extends PositionComponent with TapCallbacks {
  ShopPanel({
    required this.progress,
    required this.onPurchase,
    required this.onClose,
  }) : super(anchor: Anchor.center, priority: 230);

  final GameProgress progress;
  final void Function(StoreProduct product) onPurchase;
  final VoidCallback onClose;

  bool visible = false;
  ShopKind? shop;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    final width = math.min(620.0, gameSize.x - 28).toDouble();
    final height = math.min(460.0, gameSize.y - 28).toDouble();
    size = Vector2(width, height);
    position = Vector2(gameSize.x / 2, gameSize.y / 2);
  }

  void show(ShopKind kind) {
    shop = kind;
    visible = true;
  }

  void hide() {
    visible = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!visible || shop == null) return;

    final local = event.localPosition;
    if (local.x > size.x - 62 && local.y < 62) {
      onClose();
      return;
    }

    final products = shop!.products;
    for (var i = 0; i < products.length; i++) {
      final top = 130.0 + i * 105;
      final rect = Rect.fromLTWH(30, top, size.x - 60, 82);
      if (rect.contains(Offset(local.x, local.y))) {
        onPurchase(products[i]);
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible || shop == null) return;

    final kind = shop!;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(28),
    );
    canvas.drawRRect(
      panel.shift(const Offset(0, 8)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xFA171B24));
    canvas.drawRRect(
      panel,
      Paint()
        ..color = kind.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _text(
      kind.title,
      27,
      Colors.white,
      FontWeight.w900,
    ).paint(canvas, const Offset(30, 25));
    _text(
      kind.subtitle,
      13,
      kind.accent,
      FontWeight.w700,
    ).paint(canvas, const Offset(31, 62));
    _text(
      '${progress.coins} ₺',
      18,
      const Color(0xFFFFD768),
      FontWeight.w900,
    ).paint(canvas, Offset(size.x - 150, 31));

    canvas.drawCircle(
      Offset(size.x - 34, 34),
      20,
      Paint()..color = const Color(0xFF2D333F),
    );
    final close = _text('×', 23, Colors.white, FontWeight.w900);
    close.paint(canvas, Offset(size.x - 34 - close.width / 2, 20));

    final products = kind.products;
    for (var i = 0; i < products.length; i++) {
      final product = products[i];
      final top = 130.0 + i * 105;
      final card = RRect.fromRectAndRadius(
        Rect.fromLTWH(30, top, size.x - 60, 82),
        const Radius.circular(18),
      );
      canvas.drawRRect(card, Paint()..color = const Color(0xFF252B36));
      canvas.drawCircle(
        Offset(70, top + 41),
        25,
        Paint()..color = product.item.color.withValues(alpha: 0.2),
      );
      canvas.drawCircle(
        Offset(70, top + 41),
        12,
        Paint()..color = product.item.color,
      );

      _text(
        product.item.label,
        17,
        Colors.white,
        FontWeight.w900,
      ).paint(canvas, Offset(110, top + 17));
      _text(
        product.description,
        12,
        Colors.white54,
        FontWeight.w500,
      ).paint(canvas, Offset(110, top + 46));

      const priceWidth = 92.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.x - priceWidth - 48,
            top + 20,
            priceWidth,
            42,
          ),
          const Radius.circular(12),
        ),
        Paint()..color = kind.accent,
      );
      final price = _text(
        '${product.price} ₺',
        14,
        Colors.white,
        FontWeight.w900,
      );
      price.paint(
        canvas,
        Offset(
          size.x - priceWidth - 48 + (priceWidth - price.width) / 2,
          top + 31,
        ),
      );
    }

    _text(
      'Bir ürüne dokunarak satın al.',
      11,
      Colors.white38,
      FontWeight.w600,
    ).paint(canvas, Offset(30, size.y - 35));
  }

  TextPainter _text(
    String text,
    double size,
    Color color,
    FontWeight weight,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}

class NotificationBanner extends PositionComponent {
  NotificationBanner()
      : super(
          size: Vector2(440, 62),
          anchor: Anchor.topCenter,
          priority: 260,
        );

  String message = '';
  Color accent = const Color(0xFF46E6B2);
  double _remaining = 0;

  void show(
    String message, {
    Color accent = const Color(0xFF46E6B2),
    double seconds = 3,
  }) {
    this.message = message;
    this.accent = accent;
    _remaining = seconds;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size.x = math.min(440.0, gameSize.x - 30).toDouble();
    position = Vector2(gameSize.x / 2, 18);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_remaining > 0) _remaining -= dt;
  }

  @override
  void render(Canvas canvas) {
    if (_remaining <= 0) return;

    final appear = _remaining < 0.25 ? _remaining / 0.25 : 1.0;
    canvas.save();
    canvas.translate(0, -18 * (1 - appear));
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(18),
    );
    canvas.drawRRect(panel, Paint()..color = const Color(0xF51A1E28));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 7, 62),
        const Radius.circular(4),
      ),
      Paint()..color = accent,
    );

    final painter = _text(
      message,
      14,
      Colors.white,
      FontWeight.w800,
    );
    painter.paint(canvas, Offset(24, (size.y - painter.height) / 2));
    canvas.restore();
  }

  TextPainter _text(
    String text,
    double size,
    Color color,
    FontWeight weight,
  ) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 45);
  }
}

class DayNightOverlay extends PositionComponent {
  DayNightOverlay({required this.dayProgress}) : super(priority: 130);

  final double Function() dayProgress;

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    size = gameSize;
    position = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final phase = dayProgress();
    final nightStrength = phase < 0.23
        ? 1 - phase / 0.23
        : phase > 0.72
            ? (phase - 0.72) / 0.28
            : 0.0;

    if (nightStrength <= 0) return;

    final alpha = (nightStrength.clamp(0.0, 1.0) * 115).round();
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Color.fromARGB(alpha, 18, 25, 61),
    );
  }
}
