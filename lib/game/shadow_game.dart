import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../npc/character_npc.dart';
import '../player/player.dart';
import 'game_state.dart';
import 'premium_ui.dart';
import 'world_components.dart';

enum _InteractionType {
  none,
  npc,
  shop,
  car,
  exitCar,
}

class ShadowGame extends FlameGame with KeyboardEvents {
  final Vector2 worldSize = Vector2(3200, 2200);
  final List<Rect> obstacles = [];
  final List<CharacterNpc> npcs = [];
  final List<ShopBuilding> shops = [];
  final List<ShadowChip> shadowChips = [];
  final List<Vector2> _treePositions = [];

  final GameProgress progress = GameProgress();

  late final Player player;
  late final JoystickComponent joystick;
  late final ParkedCar playerCar;
  late final DeliveryZone deliveryZone;

  late final PremiumHud hud;
  late final MiniMapComponent miniMap;
  late final ActionButton actionButton;
  late final DialogueBox dialogueBox;
  late final ShopPanel shopPanel;
  late final NotificationBanner notification;
  late final DayNightOverlay dayNightOverlay;

  _InteractionType _interactionType = _InteractionType.none;
  CharacterNpc? _activeNpc;
  ShopBuilding? _activeShop;
  ParkedCar? _activeCar;

  double worldClock = 0.34;
  bool _deliveryRewarded = false;

  bool get modalOpen => dialogueBox.visible || shopPanel.visible;

  @override
  Color backgroundColor() => const Color(0xFF17372B);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await world.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: worldSize,
        paint: Paint()..color = const Color(0xFF5FC76B),
        priority: -10,
      ),
    );

    await _buildExpandedWorld();
    await _addNpcRoster();
    await _addMissionObjects();

    player = Player(
      position: Vector2(360, 360),
      worldBounds: worldSize,
    );
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
      priority: 180,
    );

    actionButton = ActionButton(onPressed: _performInteraction);
    dialogueBox = DialogueBox(onClose: closeDialogue);
    shopPanel = ShopPanel(
      progress: progress,
      onPurchase: _purchaseProduct,
      onClose: closeShop,
    );
    notification = NotificationBanner();

    hud = PremiumHud(
      progress: progress,
      timeLabel: _timeLabel,
      isDriving: () => player.vehicleMode,
      boostSeconds: () => player.speedBoostRemaining,
    );

    miniMap = MiniMapComponent(
      worldSize: worldSize,
      playerPosition: () => Vector2(player.position.x, player.position.y),
      npcPositions: () => npcs
          .map((npc) => Vector2(npc.position.x, npc.position.y))
          .toList(),
      shopPositions: () => shops
          .map((shop) => Vector2(shop.position.x, shop.position.y))
          .toList(),
    );

    dayNightOverlay = DayNightOverlay(dayProgress: () => worldClock);

    await camera.viewport.add(dayNightOverlay);
    await camera.viewport.add(hud);
    await camera.viewport.add(miniMap);
    await camera.viewport.add(joystick);
    await camera.viewport.add(actionButton);
    await camera.viewport.add(dialogueBox);
    await camera.viewport.add(shopPanel);
    await camera.viewport.add(notification);

    player.joystick = joystick;

    camera.follow(player);
    camera.viewfinder.zoom = 1.12;

    notification.show(
      'Shadow City’ye hoş geldin. Kaşif Arda’yı bul ve ilk görevi başlat.',
      accent: const Color(0xFFE23A42),
      seconds: 5,
    );
  }

  Future<void> _buildExpandedWorld() async {
    await world.addAll([
      DistrictGround(
        position: Vector2(60, 60),
        size: Vector2(1280, 760),
        color: const Color(0xFF62C96E),
        label: 'Eski Mahalle',
      ),
      DistrictGround(
        position: Vector2(1730, 80),
        size: Vector2(1390, 720),
        color: const Color(0xFF4CBF76),
        label: 'Neon Bölge',
      ),
      DistrictGround(
        position: Vector2(80, 1280),
        size: Vector2(1320, 820),
        color: const Color(0xFF72C46B),
        label: 'Park ve Çarşı',
      ),
      DistrictGround(
        position: Vector2(1730, 1320),
        size: Vector2(1390, 780),
        color: const Color(0xFF4BAE70),
        label: 'Liman',
      ),
      RoadComponent(
        position: Vector2(0, 900),
        size: Vector2(3200, 240),
        horizontal: true,
      ),
      RoadComponent(
        position: Vector2(1450, 0),
        size: Vector2(240, 2200),
        horizontal: false,
      ),
      RoadComponent(
        position: Vector2(0, 1760),
        size: Vector2(3200, 190),
        horizontal: true,
      ),
      RoadComponent(
        position: Vector2(2460, 880),
        size: Vector2(190, 1320),
        horizontal: false,
      ),
    ]);

    shops.addAll([
      ShopBuilding(
        position: Vector2(570, 700),
        kind: ShopKind.garage,
      ),
      ShopBuilding(
        position: Vector2(1120, 700),
        kind: ShopKind.cafe,
      ),
      ShopBuilding(
        position: Vector2(2050, 680),
        kind: ShopKind.ninjaMarket,
      ),
      ShopBuilding(
        position: Vector2(2700, 680),
        kind: ShopKind.techStore,
      ),
      ShopBuilding(
        position: Vector2(1030, 1510),
        kind: ShopKind.arcade,
      ),
      ShopBuilding(
        position: Vector2(2070, 1510),
        kind: ShopKind.techStore,
      ),
    ]);

    for (final shop in shops) {
      await world.add(shop);
      obstacles.add(shop.collisionRect);
    }

    final fountain = FountainComponent(position: Vector2(1040, 1180));
    await world.add(fountain);
    obstacles.add(fountain.collisionRect);

    _treePositions.addAll([
      Vector2(170, 170),
      Vector2(340, 210),
      Vector2(650, 170),
      Vector2(940, 230),
      Vector2(1250, 190),
      Vector2(1840, 190),
      Vector2(2180, 210),
      Vector2(2940, 200),
      Vector2(180, 690),
      Vector2(1330, 700),
      Vector2(1820, 730),
      Vector2(3050, 730),
      Vector2(180, 1320),
      Vector2(380, 1450),
      Vector2(620, 1380),
      Vector2(1350, 1450),
      Vector2(1810, 1370),
      Vector2(2260, 1380),
      Vector2(2920, 1390),
      Vector2(200, 2070),
      Vector2(720, 2070),
      Vector2(1320, 2050),
      Vector2(1840, 2070),
      Vector2(2300, 2070),
      Vector2(3000, 2050),
    ]);

    for (final position in _treePositions) {
      await world.add(DecorativeTree(position: position));
      obstacles.add(
        Rect.fromCenter(
          center: Offset(position.x, position.y + 34),
          width: 48,
          height: 38,
        ),
      );
    }

    for (double x = 120; x < worldSize.x; x += 310) {
      await world.add(StreetLight(position: Vector2(x, 875)));
      await world.add(StreetLight(position: Vector2(x + 145, 1165)));
      await world.add(StreetLight(position: Vector2(x, 1735)));
      await world.add(StreetLight(position: Vector2(x + 150, 1980)));
    }

    final traffic = <TrafficCar>[
      TrafficCar(
        position: Vector2(50, 960),
        horizontal: true,
        min: -120,
        max: 3320,
        speed: 155,
        bodyColor: const Color(0xFF3F8DD8),
      ),
      TrafficCar(
        position: Vector2(1280, 1060),
        horizontal: true,
        min: -120,
        max: 3320,
        speed: 120,
        bodyColor: const Color(0xFFE0A43E),
      ),
      TrafficCar(
        position: Vector2(1550, 250),
        horizontal: false,
        min: -120,
        max: 2320,
        speed: 105,
        bodyColor: const Color(0xFFCE4D55),
      ),
      TrafficCar(
        position: Vector2(2560, 1300),
        horizontal: false,
        min: 850,
        max: 2320,
        speed: 135,
        bodyColor: const Color(0xFF62B878),
      ),
      TrafficCar(
        position: Vector2(300, 1820),
        horizontal: true,
        min: -120,
        max: 3320,
        speed: 180,
        bodyColor: const Color(0xFF8A67D5),
      ),
    ];

    await world.addAll(traffic);
  }

  Future<void> _addNpcRoster() async {
    npcs.addAll([
      CharacterNpc(
        position: Vector2(930, 820),
        archetype: NpcArchetype.explorer,
        showQuestMarker: true,
      ),
      CharacterNpc(
        position: Vector2(1320, 1210),
        archetype: NpcArchetype.streetRunner,
      ),
      CharacterNpc(
        position: Vector2(420, 1640),
        archetype: NpcArchetype.farmer,
      ),
      CharacterNpc(
        position: Vector2(2850, 1550),
        archetype: NpcArchetype.forestHunter,
      ),
      CharacterNpc(
        position: Vector2(1900, 1210),
        archetype: NpcArchetype.youngKnight,
      ),
      CharacterNpc(
        position: Vector2(1120, 1640),
        archetype: NpcArchetype.mageApprentice,
      ),
      CharacterNpc(
        position: Vector2(2700, 830),
        archetype: NpcArchetype.techSpecialist,
      ),
    ]);

    for (final npc in npcs) {
      await world.add(npc);
      obstacles.add(npc.collisionRect);
    }
  }

  Future<void> _addMissionObjects() async {
    shadowChips.addAll([
      ShadowChip(position: Vector2(1880, 420)),
      ShadowChip(position: Vector2(2320, 1240)),
      ShadowChip(position: Vector2(660, 1540)),
    ]);
    await world.addAll(shadowChips);

    playerCar = ParkedCar(
      position: Vector2(620, 860),
      modelName: 'Shadow GT',
      bodyColor: const Color(0xFF8E1E23),
    );
    await world.add(playerCar);

    deliveryZone = DeliveryZone(position: Vector2(2860, 1650));
    await world.add(deliveryZone);
  }

  @override
  void update(double dt) {
    super.update(dt);

    worldClock = (worldClock + dt / 240) % 1;
    deliveryZone.active =
        progress.questStage == QuestStage.driveToDropZone;

    if (!player.isMounted) return;

    _collectNearbyChips();
    _checkDeliveryMission();
    _updateInteraction();

    final controlsEnabled = !modalOpen;
    player.joystick = controlsEnabled ? joystick : null;
    if (!controlsEnabled) player.updateKeyboard({});
  }

  void _collectNearbyChips() {
    if (progress.questStage != QuestStage.collectShadowChips) return;

    for (final chip in shadowChips) {
      if (chip.collected || !chip.isMounted) continue;
      if (player.position.distanceTo(chip.position) < 68) {
        chip.collected = true;
        chip.removeFromParent();

        final questFinished = progress.collectShadowChip();
        if (questFinished) {
          notification.show(
            'Tüm çipler toplandı! Leo’ya götür. Ödül hesabına eklendi.',
            accent: const Color(0xFF9B5CFF),
            seconds: 4,
          );
        } else {
          notification.show(
            'Gölge çipi alındı: ${progress.collectedShadowChips} / 3',
            accent: const Color(0xFF9B5CFF),
          );
        }
      }
    }
  }

  void _checkDeliveryMission() {
    if (_deliveryRewarded ||
        progress.questStage != QuestStage.driveToDropZone ||
        !player.vehicleMode) {
      return;
    }

    if (deliveryZone.containsPoint(player.position)) {
      _deliveryRewarded = true;
      final reward = progress.completeCurrentQuest();
      notification.show(
        'Bölüm tamamlandı! +${reward.coins} ₺  +${reward.xp} XP',
        accent: const Color(0xFFFFD768),
        seconds: 6,
      );
      dialogueBox.show(
        speaker: 'Görev Kontrol',
        message:
            'Teslimat başarıyla tamamlandı. Shadow City artık serbest dolaşıma açık. Mağazaları keşfedebilir, ekipman toplayabilir ve aracını geliştirebilirsin.',
        accent: const Color(0xFFFFD768),
      );
    }
  }

  void _updateInteraction() {
    _interactionType = _InteractionType.none;
    _activeNpc = null;
    _activeShop = null;
    _activeCar = null;

    if (modalOpen) {
      actionButton.enabled = false;
      actionButton.label = '...';
      actionButton.icon = '●';
      return;
    }

    if (player.vehicleMode) {
      _interactionType = _InteractionType.exitCar;
      actionButton.enabled = true;
      actionButton.label = 'ARAÇTAN İN';
      actionButton.icon = '↘';
      return;
    }

    var nearestDistance = double.infinity;

    for (final npc in npcs) {
      if (!npc.isMounted) continue;
      final distance = player.position.distanceTo(npc.position);
      if (distance < 150 && distance < nearestDistance) {
        nearestDistance = distance;
        _interactionType = _InteractionType.npc;
        _activeNpc = npc;
      }
    }

    for (final shop in shops) {
      final distance = player.position.distanceTo(shop.interactionPoint);
      if (distance < 175 && distance < nearestDistance) {
        nearestDistance = distance;
        _interactionType = _InteractionType.shop;
        _activeShop = shop;
        _activeNpc = null;
      }
    }

    if (!playerCar.occupied) {
      final distance = player.position.distanceTo(playerCar.position);
      if (distance < 145 && distance < nearestDistance) {
        _interactionType = _InteractionType.car;
        _activeCar = playerCar;
        _activeNpc = null;
        _activeShop = null;
      }
    }

    actionButton.enabled = _interactionType != _InteractionType.none;
    switch (_interactionType) {
      case _InteractionType.npc:
        actionButton.label = 'KONUŞ';
        actionButton.icon = '●';
      case _InteractionType.shop:
        actionButton.label = 'MAĞAZA';
        actionButton.icon = '₺';
      case _InteractionType.car:
        actionButton.label =
            progress.carUnlocked ? 'ARACA BİN' : 'KİLİTLİ';
        actionButton.icon = '◆';
      case _InteractionType.exitCar:
        actionButton.label = 'ARAÇTAN İN';
        actionButton.icon = '↘';
      case _InteractionType.none:
        actionButton.label = '...';
        actionButton.icon = '●';
    }
  }

  void _performInteraction() {
    switch (_interactionType) {
      case _InteractionType.npc:
        _talkToNpc();
      case _InteractionType.shop:
        _openShop();
      case _InteractionType.car:
        _enterCar();
      case _InteractionType.exitCar:
        _exitCar();
      case _InteractionType.none:
        break;
    }
  }

  void _talkToNpc() {
    final npc = _activeNpc;
    if (npc == null) return;

    var message = npc.dialogue;

    if (npc.archetype == NpcArchetype.explorer &&
        progress.questStage == QuestStage.talkToExplorer) {
      final reward = progress.completeCurrentQuest();
      message =
          'Shadow City’de üç kayıp gölge çipi var. Onları bulup Leo’ya götür. İlk görevin başladı. +${reward.coins} ₺ ve +${reward.xp} XP kazandın.';
      notification.show(
        'Yeni görev: Kayıp Gölge Çipleri',
        accent: const Color(0xFF9B5CFF),
      );
    } else if (npc.archetype == NpcArchetype.techSpecialist &&
        progress.questStage == QuestStage.talkToTech) {
      final reward = progress.completeCurrentQuest();
      message =
          'Çipler sağlam. Garajdaki Shadow GT’nin kilidini açtım. Önce Ninja Market’ten duman bombası al, sonra gece teslimatına çık. +${reward.coins} ₺ ve +${reward.xp} XP.';
      notification.show(
        'Shadow GT aracının kilidi açıldı!',
        accent: const Color(0xFF35C7FF),
      );
    } else if (npc.archetype == NpcArchetype.techSpecialist &&
        progress.questStage == QuestStage.collectShadowChips) {
      message =
          'Henüz üç çipin tamamı sende değil. Mor parıltıları takip et.';
    }

    dialogueBox.show(
      speaker: npc.displayName,
      message: message,
      accent: npc.archetype.accent,
    );
  }

  void _openShop() {
    final shop = _activeShop;
    if (shop == null) return;
    shopPanel.show(shop.kind);
  }

  void _purchaseProduct(StoreProduct product) {
    if (!progress.spendCoins(product.price)) {
      notification.show(
        'Yetersiz bakiye. Bu ürün için ${product.price} ₺ gerekiyor.',
        accent: const Color(0xFFE23A42),
      );
      return;
    }

    progress.addItem(product.item);

    switch (product.item) {
      case GameItem.energyDrink:
        player.applySpeedBoost();
      case GameItem.turboKit:
        player.installTurbo();
      case GameItem.smokeBomb:
        if (progress.questStage == QuestStage.buySmokeBomb) {
          final reward = progress.completeCurrentQuest();
          notification.show(
            'Hazırlık tamamlandı! Araca bin ve limana git. +${reward.coins} ₺',
            accent: const Color(0xFFE23A42),
            seconds: 4,
          );
          return;
        }
      case GameItem.repairKit:
      case GameItem.shadowChip:
        break;
    }

    notification.show(
      '${product.item.label} satın alındı.',
      accent: product.item.color,
    );
  }

  void _enterCar() {
    final car = _activeCar;
    if (car == null) return;

    if (!progress.carUnlocked) {
      notification.show(
        'Araç kilitli. Önce çipleri Leo’ya teslim et.',
        accent: const Color(0xFFE23A42),
      );
      return;
    }

    car.occupied = true;
    player.position.setFrom(car.position);
    player.setVehicleMode(true);
    notification.show(
      'Shadow GT aktif. Araçtan inmek için sağdaki düğmeye dokun.',
      accent: const Color(0xFF35C7FF),
    );
  }

  void _exitCar() {
    player.setVehicleMode(false);
    playerCar.position = Vector2(
      (player.position.x + 100).clamp(70, worldSize.x - 70),
      player.position.y,
    );
    playerCar.occupied = false;
    notification.show('Araç park edildi.');
  }

  void closeDialogue() {
    dialogueBox.hide();
  }

  void closeShop() {
    shopPanel.hide();
  }

  String _timeLabel() {
    final totalMinutes = (worldClock * 24 * 60).floor();
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (dialogueBox.visible) {
        closeDialogue();
        return KeyEventResult.handled;
      }
      if (shopPanel.visible) {
        closeShop();
        return KeyEventResult.handled;
      }
    }

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      if (!modalOpen) {
        _performInteraction();
        return KeyEventResult.handled;
      }
    }

    if (modalOpen) {
      player.updateKeyboard({});
      return KeyEventResult.handled;
    }

    player.updateKeyboard(keysPressed);
    return KeyEventResult.handled;
  }
}
