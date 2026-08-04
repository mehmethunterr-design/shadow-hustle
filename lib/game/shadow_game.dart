import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../npc/character_npc.dart';
import '../player/player.dart';

class ShadowGame extends FlameGame with KeyboardEvents {
  late final Player player;
  late final JoystickComponent joystick;
  late final InteractionButton interactionButton;
  late final DialogueBox dialogueBox;

  final Vector2 worldSize = Vector2(1800, 1200);
  final List<Rect> obstacles = [];
  final List<CharacterNpc> npcs = [];

  CharacterNpc? activeNpc;
  bool dialogueOpen = false;

  @override
  Color backgroundColor() => const Color(0xFF79D96B);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await world.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: worldSize,
        paint: Paint()..color = const Color(0xFF79D96B),
        priority: -10,
      ),
    );

    _buildWorld();
    await _addNpcRoster();

    player = Player(position: Vector2(500, 400));
    player.obstacles = obstacles;
    await world.add(player);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 28,
        paint: Paint()..color = const Color(0xE6FFFFFF),
      ),
      background: CircleComponent(
        radius: 55,
        paint: Paint()..color = const Color(0x77341E25),
      ),
      margin: const EdgeInsets.only(left: 35, bottom: 35),
      priority: 100,
    );

    interactionButton = InteractionButton(onPressed: interactWithNpc);
    dialogueBox = DialogueBox(onClose: closeDialogue);

    await camera.viewport.add(joystick);
    await camera.viewport.add(interactionButton);
    await camera.viewport.add(dialogueBox);

    player.joystick = joystick;
    camera.follow(player);
    camera.viewfinder.zoom = 1.35;
  }

  Future<void> _addNpcRoster() async {
    npcs.addAll([
      CharacterNpc(
        position: Vector2(1050, 500),
        archetype: NpcArchetype.explorer,
        showQuestMarker: true,
      ),
      CharacterNpc(
        position: Vector2(570, 660),
        archetype: NpcArchetype.streetRunner,
      ),
      CharacterNpc(
        position: Vector2(1260, 390),
        archetype: NpcArchetype.farmer,
      ),
      CharacterNpc(
        position: Vector2(1470, 850),
        archetype: NpcArchetype.forestHunter,
      ),
      CharacterNpc(
        position: Vector2(850, 940),
        archetype: NpcArchetype.youngKnight,
      ),
      CharacterNpc(
        position: Vector2(390, 890),
        archetype: NpcArchetype.mageApprentice,
      ),
      CharacterNpc(
        position: Vector2(1510, 430),
        archetype: NpcArchetype.techSpecialist,
      ),
    ]);

    for (final npc in npcs) {
      await world.add(npc);
      obstacles.add(npc.collisionRect);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!player.isMounted) return;

    CharacterNpc? nearest;
    var nearestDistance = double.infinity;

    for (final npc in npcs) {
      if (!npc.isMounted) continue;
      final distance = player.position.distanceTo(npc.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = npc;
      }
    }

    activeNpc = nearestDistance < 145 ? nearest : null;
    interactionButton.enabled = activeNpc != null && !dialogueOpen;
    interactionButton.label = activeNpc == null ? '...' : 'KONUŞ';

    player.joystick = dialogueOpen ? null : joystick;
    if (dialogueOpen) player.updateKeyboard({});
  }

  void interactWithNpc() {
    final npc = activeNpc;
    if (npc == null || !interactionButton.enabled || dialogueOpen) return;

    dialogueOpen = true;
    dialogueBox.show(
      speaker: npc.displayName,
      message: npc.dialogue,
      accent: npc.archetype.accent,
    );
  }

  void closeDialogue() {
    dialogueOpen = false;
    dialogueBox.hide();
  }

  void _buildWorld() {
    world.add(
      RectangleComponent(
        position: Vector2(0, 560),
        size: Vector2(1800, 170),
        paint: Paint()..color = const Color(0xFFF3CF8B),
        priority: -5,
      ),
    );

    final treePositions = <Vector2>[
      Vector2(150, 130),
      Vector2(340, 220),
      Vector2(700, 120),
      Vector2(1050, 170),
      Vector2(1350, 250),
      Vector2(1550, 140),
      Vector2(230, 820),
      Vector2(700, 860),
      Vector2(1100, 810),
      Vector2(1450, 900),
    ];

    for (final position in treePositions) {
      world.add(TreeComponent(position: position));
      obstacles.add(
        Rect.fromCenter(
          center: Offset(position.x, position.y + 38),
          width: 50,
          height: 42,
        ),
      );
    }

    const housePosition = Offset(800, 330);
    world.add(
      HouseComponent(
        position: Vector2(housePosition.dx, housePosition.dy),
      ),
    );
    obstacles.add(
      Rect.fromCenter(
        center: Offset(housePosition.dx, housePosition.dy + 45),
        width: 210,
        height: 105,
      ),
    );
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (dialogueOpen) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        closeDialogue();
      }
      return KeyEventResult.handled;
    }

    player.updateKeyboard(keysPressed);
    return KeyEventResult.handled;
  }
}

class InteractionButton extends PositionComponent with TapCallbacks {
  InteractionButton({required this.onPressed})
      : super(
          size: Vector2(105, 105),
          anchor: Anchor.bottomRight,
          priority: 110,
        );

  final VoidCallback onPressed;
  bool enabled = false;
  String label = '...';

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x - 35, size.y - 35);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (enabled) onPressed();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawCircle(
      const Offset(52.5, 52.5),
      50,
      Paint()
        ..color = enabled
            ? const Color(0xFF8E1E23)
            : const Color(0x775D6170),
    );
    canvas.drawCircle(
      const Offset(52.5, 52.5),
      40,
      Paint()
        ..color = enabled
            ? const Color(0xFFBC2B31)
            : const Color(0x665D6170),
    );

    final icon = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(52.5, 39), 9, icon);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 51, 33, 18),
        const Radius.circular(9),
      ),
      icon,
    );

    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset((size.x - text.width) / 2, 77));
  }
}

class DialogueBox extends PositionComponent with TapCallbacks {
  DialogueBox({required this.onClose})
      : super(anchor: Anchor.bottomCenter, priority: 200);

  final VoidCallback onClose;
  bool visible = false;
  String speaker = '';
  String message = '';
  Color accent = const Color(0xFFBC2B31);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _resize(size);
  }

  void _resize(Vector2 screenSize) {
    final width = screenSize.x > 700 ? 620.0 : screenSize.x - 30;
    size = Vector2(width, 190);
    position = Vector2(screenSize.x / 2, screenSize.y - 20);
  }

  void show({
    required String speaker,
    required String message,
    required Color accent,
  }) {
    this.speaker = speaker;
    this.message = message;
    this.accent = accent;
    visible = true;
  }

  void hide() => visible = false;

  @override
  void onTapDown(TapDownEvent event) {
    if (visible) onClose();
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    super.render(canvas);

    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x - 6, size.y - 10),
      const Radius.circular(26),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 7, size.x - 6, size.y - 7),
        const Radius.circular(26),
      ),
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawRRect(box, Paint()..color = const Color(0xF21B2030));
    canvas.drawRRect(
      box,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(const Offset(62, 67), 38, Paint()..color = accent);
    canvas.drawCircle(
      const Offset(62, 56),
      20,
      Paint()..color = const Color(0xFFFFC9A5),
    );
    canvas.drawArc(
      const Rect.fromLTWH(42, 36, 40, 34),
      3.14,
      3.14,
      true,
      Paint()..color = const Color(0xFF3A2A25),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 76, 48, 26),
        const Radius.circular(13),
      ),
      Paint()..color = accent,
    );

    final speakerPainter = TextPainter(
      text: TextSpan(
        text: speaker,
        style: TextStyle(
          color: accent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    speakerPainter.paint(canvas, const Offset(115, 25));

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
    )..layout(maxWidth: size.x - 145);
    messagePainter.paint(canvas, const Offset(115, 58));

    final closePainter = TextPainter(
      text: const TextSpan(
        text: 'Devam etmek için dokun',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    closePainter.paint(
      canvas,
      Offset(size.x - closePainter.width - 25, size.y - 37),
    );
  }
}

class TreeComponent extends PositionComponent {
  TreeComponent({required super.position})
      : super(
          size: Vector2(110, 140),
          anchor: Anchor.center,
          priority: 2,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawOval(
      const Rect.fromLTWH(16, 110, 80, 22),
      Paint()..color = const Color(0x28000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 68, 22, 54),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF915E38),
    );
    canvas.drawCircle(
      const Offset(55, 50),
      44,
      Paint()..color = const Color(0xFF2EAA52),
    );
    canvas.drawCircle(
      const Offset(36, 39),
      29,
      Paint()..color = const Color(0xFF50D86D),
    );
    canvas.drawCircle(
      const Offset(74, 35),
      27,
      Paint()..color = const Color(0xFF50D86D),
    );
  }
}

class HouseComponent extends PositionComponent {
  HouseComponent({required super.position})
      : super(
          size: Vector2(260, 210),
          anchor: Anchor.center,
          priority: 2,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawOval(
      const Rect.fromLTWH(20, 180, 220, 25),
      Paint()..color = const Color(0x28000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 72, 205, 116),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFFFD86C),
    );

    final roof = Path()
      ..moveTo(10, 85)
      ..lineTo(130, 8)
      ..lineTo(250, 85)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFEC6262));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(103, 124, 54, 64),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFF5C8FF3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 105, 42, 42),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF8BE4FF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(169, 105, 42, 42),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF8BE4FF),
    );
  }
}
