import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../player/player.dart';

class ShadowGame extends FlameGame with KeyboardEvents {
  late final Player player;
  late final JoystickComponent joystick;
  late final NpcComponent firstNpc;
  late final InteractionButton interactionButton;
  late final DialogueBox dialogueBox;

  final Vector2 worldSize = Vector2(1800, 1200);
  final List<Rect> obstacles = [];

  bool dialogueOpen = false;

  @override
  Color backgroundColor() {
    return const Color(0xFF79D96B);
  }

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

    firstNpc = NpcComponent(
      position: Vector2(1050, 500),
    );

    await world.add(firstNpc);

    obstacles.add(
      Rect.fromCenter(
        center: const Offset(1050, 520),
        width: 38,
        height: 32,
      ),
    );

    player = Player(
      position: Vector2(500, 400),
    );

    player.obstacles = obstacles;

    await world.add(player);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 28,
        paint: Paint()..color = const Color(0xDDFFFFFF),
      ),
      background: CircleComponent(
        radius: 55,
        paint: Paint()..color = const Color(0x663B2C66),
      ),
      margin: const EdgeInsets.only(
        left: 35,
        bottom: 35,
      ),
      priority: 100,
    );

    interactionButton = InteractionButton(
      onPressed: interactWithNpc,
    );

    dialogueBox = DialogueBox(
      onClose: closeDialogue,
    );

    await camera.viewport.add(joystick);
    await camera.viewport.add(interactionButton);
    await camera.viewport.add(dialogueBox);

    player.joystick = joystick;

    camera.follow(player);
    camera.viewfinder.zoom = 1.35;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!player.isMounted || !firstNpc.isMounted) {
      return;
    }

    final distance = player.position.distanceTo(firstNpc.position);
    final nearNpc = distance < 145;

    interactionButton.enabled = nearNpc && !dialogueOpen;
    interactionButton.label = nearNpc ? 'KONUŞ' : '...';

    player.joystick = dialogueOpen ? null : joystick;

    if (dialogueOpen) {
      player.updateKeyboard({});
    }
  }

  void interactWithNpc() {
    if (!interactionButton.enabled || dialogueOpen) {
      return;
    }

    dialogueOpen = true;
    dialogueBox.show(
      speaker: 'Murat Usta',
      message:
          'Selam genç! Yeni geldiğini duydum. Para kazanmak istiyorsan sana bir iş verebilirim. Mahallede 3 hurda telefon bulup bana getir.',
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
      world.add(
        TreeComponent(
          position: position,
        ),
      );

      obstacles.add(
        Rect.fromCenter(
          center: Offset(
            position.x,
            position.y + 38,
          ),
          width: 50,
          height: 42,
        ),
      );
    }

    const housePosition = Offset(800, 330);

    world.add(
      HouseComponent(
        position: Vector2(
          housePosition.dx,
          housePosition.dy,
        ),
      ),
    );

    obstacles.add(
      Rect.fromCenter(
        center: Offset(
          housePosition.dx,
          housePosition.dy + 45,
        ),
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
  InteractionButton({
    required this.onPressed,
  }) : super(
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

    position = Vector2(
      size.x - 35,
      size.y - 35,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (enabled) {
      onPressed();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final outerPaint = Paint()
      ..color = enabled
          ? const Color(0xFF7D55FF)
          : const Color(0x775D6170);

    final innerPaint = Paint()
      ..color = enabled
          ? const Color(0xFF9A7BFF)
          : const Color(0x665D6170);

    canvas.drawCircle(
      const Offset(52.5, 52.5),
      50,
      outerPaint,
    );

    canvas.drawCircle(
      const Offset(52.5, 52.5),
      40,
      innerPaint,
    );

    final iconPaint = Paint()
      ..color = Colors.white;

    canvas.drawCircle(
      const Offset(52.5, 39),
      9,
      iconPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 51, 33, 18),
        const Radius.circular(9),
      ),
      iconPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        77,
      ),
    );
  }
}

class DialogueBox extends PositionComponent with TapCallbacks {
  DialogueBox({
    required this.onClose,
  }) : super(
          anchor: Anchor.bottomCenter,
          priority: 200,
        );

  final VoidCallback onClose;

  bool visible = false;
  String speaker = '';
  String message = '';

 
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _resize(size);
  }

  void _resize(Vector2 screenSize) {
    final width = screenSize.x > 700
        ? 620.0
        : screenSize.x - 30;

    size = Vector2(width, 190);

    position = Vector2(
      screenSize.x / 2,
      screenSize.y - 20,
    );
  }

  void show({
    required String speaker,
    required String message,
  }) {
    this.speaker = speaker;
    this.message = message;
    visible = true;
  }

  void hide() {
    visible = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (visible) {
      onClose();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!visible) {
      return;
    }

    super.render(canvas);

    final shadowPaint = Paint()
      ..color = const Color(0x55000000);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          6,
          7,
          size.x - 6,
          size.y - 7,
        ),
        const Radius.circular(26),
      ),
      shadowPaint,
    );

    final backgroundPaint = Paint()
      ..color = const Color(0xF21B2030);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          0,
          size.x - 6,
          size.y - 10,
        ),
        const Radius.circular(26),
      ),
      backgroundPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF9A7BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          0,
          size.x - 6,
          size.y - 10,
        ),
        const Radius.circular(26),
      ),
      borderPaint,
    );

    final avatarPaint = Paint()
      ..color = const Color(0xFFFFC94D);

    canvas.drawCircle(
      const Offset(62, 67),
      38,
      avatarPaint,
    );

    final headPaint = Paint()
      ..color = const Color(0xFFFFD6B9);

    canvas.drawCircle(
      const Offset(62, 57),
      20,
      headPaint,
    );

    final bodyPaint = Paint()
      ..color = const Color(0xFFEF9B32);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 76, 48, 26),
        const Radius.circular(13),
      ),
      bodyPaint,
    );

    final speakerPainter = TextPainter(
      text: TextSpan(
        text: speaker,
        style: const TextStyle(
          color: Color(0xFFFFD75E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    speakerPainter.layout();

    speakerPainter.paint(
      canvas,
      const Offset(115, 25),
    );

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
    );

    messagePainter.layout(
      maxWidth: size.x - 145,
    );

    messagePainter.paint(
      canvas,
      const Offset(115, 58),
    );

    final closePainter = TextPainter(
      text: const TextSpan(
        text: 'Devam etmek için dokun',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    closePainter.layout();

    closePainter.paint(
      canvas,
      Offset(
        size.x - closePainter.width - 25,
        size.y - 37,
      ),
    );
  }
}

class NpcComponent extends PositionComponent {
  NpcComponent({
    required super.position,
  }) : super(
          size: Vector2(70, 90),
          anchor: Anchor.center,
          priority: 9,
        );

  double animationTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bob = animationTime % 2 < 1 ? 0.0 : -1.0;

    canvas.save();
    canvas.translate(0, bob);

    final shadowPaint = Paint()
      ..color = const Color(0x33000000);

    canvas.drawOval(
      const Rect.fromLTWH(12, 75, 46, 14),
      shadowPaint,
    );

    final legPaint = Paint()
      ..color = const Color(0xFF3B445E);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 65, 12, 18),
        const Radius.circular(5),
      ),
      legPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 65, 12, 18),
        const Radius.circular(5),
      ),
      legPaint,
    );

    final bodyPaint = Paint()
      ..color = const Color(0xFFFFB93F);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 31, 50, 42),
        const Radius.circular(18),
      ),
      bodyPaint,
    );

    final vestPaint = Paint()
      ..color = const Color(0xFFEF7D32);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 32, 13, 36),
        const Radius.circular(5),
      ),
      vestPaint,
    );

    final headPaint = Paint()
      ..color = const Color(0xFFFFD1AF);

    canvas.drawCircle(
      const Offset(35, 22),
      21,
      headPaint,
    );

    final hairPaint = Paint()
      ..color = const Color(0xFF553D2E);

    canvas.drawArc(
      const Rect.fromLTWH(14, 1, 42, 36),
      3.15,
      3.15,
      true,
      hairPaint,
    );

    final eyePaint = Paint()
      ..color = const Color(0xFF242733);

    canvas.drawCircle(
      const Offset(28, 22),
      2.3,
      eyePaint,
    );

    canvas.drawCircle(
      const Offset(42, 22),
      2.3,
      eyePaint,
    );

    final markerPaint = Paint()
      ..color = const Color(0xFFFFE05B);

    canvas.drawCircle(
      const Offset(35, -17),
      13,
      markerPaint,
    );

    final markerText = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Color(0xFF503D1D),
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    markerText.layout();

    markerText.paint(
      canvas,
      Offset(
        35 - markerText.width / 2,
        -29,
      ),
    );

    canvas.restore();
  }
}

class TreeComponent extends PositionComponent {
  TreeComponent({
    required super.position,
  }) : super(
          size: Vector2(110, 140),
          anchor: Anchor.center,
          priority: 2,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final shadowPaint = Paint()
      ..color = const Color(0x28000000);

    canvas.drawOval(
      const Rect.fromLTWH(16, 110, 80, 22),
      shadowPaint,
    );

    final trunkPaint = Paint()
      ..color = const Color(0xFF915E38);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 68, 22, 54),
        const Radius.circular(8),
      ),
      trunkPaint,
    );

    final darkLeaves = Paint()
      ..color = const Color(0xFF2EAA52);

    final lightLeaves = Paint()
      ..color = const Color(0xFF50D86D);

    canvas.drawCircle(
      const Offset(55, 50),
      44,
      darkLeaves,
    );

    canvas.drawCircle(
      const Offset(36, 39),
      29,
      lightLeaves,
    );

    canvas.drawCircle(
      const Offset(74, 35),
      27,
      lightLeaves,
    );
  }
}

class HouseComponent extends PositionComponent {
  HouseComponent({
    required super.position,
  }) : super(
          size: Vector2(260, 210),
          anchor: Anchor.center,
          priority: 2,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final shadowPaint = Paint()
      ..color = const Color(0x28000000);

    canvas.drawOval(
      const Rect.fromLTWH(20, 180, 220, 25),
      shadowPaint,
    );

    final wallPaint = Paint()
      ..color = const Color(0xFFFFD86C);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(28, 72, 205, 116),
        const Radius.circular(18),
      ),
      wallPaint,
    );

    final roofPaint = Paint()
      ..color = const Color(0xFFEC6262);

    final roof = Path()
      ..moveTo(10, 85)
      ..lineTo(130, 8)
      ..lineTo(250, 85)
      ..close();

    canvas.drawPath(roof, roofPaint);

    final doorPaint = Paint()
      ..color = const Color(0xFF5C8FF3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(103, 124, 54, 64),
        const Radius.circular(9),
      ),
      doorPaint,
    );

    final windowPaint = Paint()
      ..color = const Color(0xFF8BE4FF);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 105, 42, 42),
        const Radius.circular(8),
      ),
      windowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(169, 105, 42, 42),
        const Radius.circular(8),
      ),
      windowPaint,
    );
  }
}