// objects/tree_sprite.dart
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/farming_simulation/farm_game.dart';

class TreeSprite extends SpriteComponent with HasGameReference<FarmGame> {
  final String treeType;

  TreeSprite({
    required Vector2 position,
    required this.treeType,
  }) : super(
    position: position,
    size: Vector2(64, 80),
    anchor: Anchor.bottomCenter,
  );

  @override
  FutureOr<void> onLoad() async {
    sprite = await game.loadSprite(_getTreeAssetPath(treeType));

    debugPrint("🌳 Tree displayed: $treeType at $position");
    return super.onLoad();
  }

  String _getTreeAssetPath(String type) {
    switch (type) {
      case "Cây táo":
        return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_00.png";
      case "Cây xoài":
        return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_00.png";
      default:
        return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_00.png";
    }
  }
}