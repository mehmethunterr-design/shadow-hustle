import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/shadow_game.dart';

void main() {
  runApp(const ShadowHustleApp());
}

class ShadowHustleApp extends StatelessWidget {
  const ShadowHustleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shadow Hustle',
      home: Scaffold(
        body: GameWidget(
          game: ShadowGame(),
        ),
      ),
    );
  }
}