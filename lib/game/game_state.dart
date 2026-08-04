import 'package:flutter/material.dart';

enum GameItem {
  shadowChip,
  energyDrink,
  smokeBomb,
  repairKit,
  turboKit,
}

extension GameItemData on GameItem {
  String get label => switch (this) {
        GameItem.shadowChip => 'Gölge Çipi',
        GameItem.energyDrink => 'Enerji İçeceği',
        GameItem.smokeBomb => 'Duman Bombası',
        GameItem.repairKit => 'Tamir Kiti',
        GameItem.turboKit => 'Turbo Kiti',
      };

  Color get color => switch (this) {
        GameItem.shadowChip => const Color(0xFF9B5CFF),
        GameItem.energyDrink => const Color(0xFF38D9B0),
        GameItem.smokeBomb => const Color(0xFF7A8294),
        GameItem.repairKit => const Color(0xFFFFB347),
        GameItem.turboKit => const Color(0xFF35C7FF),
      };
}

enum QuestStage {
  talkToExplorer,
  collectShadowChips,
  talkToTech,
  buySmokeBomb,
  driveToDropZone,
  completed,
}

extension QuestStageData on QuestStage {
  String get title => switch (this) {
        QuestStage.talkToExplorer => 'İlk Temas',
        QuestStage.collectShadowChips => 'Kayıp Gölge Çipleri',
        QuestStage.talkToTech => 'Sistem Sızıntısı',
        QuestStage.buySmokeBomb => 'Hazırlık',
        QuestStage.driveToDropZone => 'Gece Teslimatı',
        QuestStage.completed => 'Bölüm Tamamlandı',
      };

  String get description => switch (this) {
        QuestStage.talkToExplorer =>
          'Şehir meydanındaki Kaşif Arda ile konuş.',
        QuestStage.collectShadowChips =>
          'Haritadaki 3 mor gölge çipini bul ve topla.',
        QuestStage.talkToTech =>
          'Topladığın çipleri Teknoloji Uzmanı Leo’ya götür.',
        QuestStage.buySmokeBomb =>
          'Ninja Market’ten bir duman bombası satın al.',
        QuestStage.driveToDropZone =>
          'Garajdaki araca bin ve limandaki teslimat bölgesine ulaş.',
        QuestStage.completed =>
          'İlk hikâye zincirini tamamladın. Şehir artık özgürce keşfedilebilir.',
      };

  int get rewardCoins => switch (this) {
        QuestStage.talkToExplorer => 120,
        QuestStage.collectShadowChips => 260,
        QuestStage.talkToTech => 380,
        QuestStage.buySmokeBomb => 220,
        QuestStage.driveToDropZone => 750,
        QuestStage.completed => 0,
      };

  int get rewardXp => switch (this) {
        QuestStage.talkToExplorer => 80,
        QuestStage.collectShadowChips => 140,
        QuestStage.talkToTech => 180,
        QuestStage.buySmokeBomb => 120,
        QuestStage.driveToDropZone => 320,
        QuestStage.completed => 0,
      };
}

class StoreProduct {
  const StoreProduct({
    required this.item,
    required this.price,
    required this.description,
  });

  final GameItem item;
  final int price;
  final String description;
}

class GameProgress {
  int coins = 350;
  int xp = 0;
  int level = 1;

  QuestStage questStage = QuestStage.talkToExplorer;
  int collectedShadowChips = 0;
  bool carUnlocked = false;
  bool storyCompleted = false;

  final Map<GameItem, int> inventory = {
    GameItem.shadowChip: 0,
    GameItem.energyDrink: 0,
    GameItem.smokeBomb: 0,
    GameItem.repairKit: 0,
    GameItem.turboKit: 0,
  };

  int get xpForNextLevel => 250 + (level - 1) * 140;

  double get xpProgress {
    final target = xpForNextLevel;
    return target == 0
        ? 0.0
        : (xp / target).clamp(0.0, 1.0).toDouble();
  }

  String get questProgressText => switch (questStage) {
        QuestStage.collectShadowChips => '$collectedShadowChips / 3',
        QuestStage.completed => 'Tamamlandı',
        _ => '0 / 1',
      };

  double get questProgress => switch (questStage) {
        QuestStage.collectShadowChips =>
          (collectedShadowChips / 3).clamp(0.0, 1.0).toDouble(),
        QuestStage.completed => 1.0,
        _ => 0.0,
      };

  int itemCount(GameItem item) => inventory[item] ?? 0;

  void addItem(GameItem item, [int amount = 1]) {
    inventory[item] = itemCount(item) + amount;
  }

  bool spendCoins(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    return true;
  }

  void addCoins(int amount) {
    coins += amount;
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpForNextLevel) {
      xp -= xpForNextLevel;
      level += 1;
    }
  }

  ({int coins, int xp}) completeCurrentQuest() {
    if (questStage == QuestStage.completed) {
      return (coins: 0, xp: 0);
    }

    final rewardCoins = questStage.rewardCoins;
    final rewardXp = questStage.rewardXp;
    addCoins(rewardCoins);
    addXp(rewardXp);

    questStage = switch (questStage) {
      QuestStage.talkToExplorer => QuestStage.collectShadowChips,
      QuestStage.collectShadowChips => QuestStage.talkToTech,
      QuestStage.talkToTech => QuestStage.buySmokeBomb,
      QuestStage.buySmokeBomb => QuestStage.driveToDropZone,
      QuestStage.driveToDropZone => QuestStage.completed,
      QuestStage.completed => QuestStage.completed,
    };

    if (questStage == QuestStage.buySmokeBomb) {
      carUnlocked = true;
    }
    if (questStage == QuestStage.completed) {
      storyCompleted = true;
    }

    return (coins: rewardCoins, xp: rewardXp);
  }

  bool collectShadowChip() {
    if (questStage != QuestStage.collectShadowChips) return false;

    collectedShadowChips += 1;
    addItem(GameItem.shadowChip);

    if (collectedShadowChips >= 3) {
      completeCurrentQuest();
      return true;
    }
    return false;
  }
}
