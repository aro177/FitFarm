// objects/tree_sprite.dart
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/farming_simulation/farm_game.dart';

class TreeSprite extends SpriteAnimationComponent
    with HasGameReference<FarmGame> {
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
    await _loadIdleAnimation();
    return super.onLoad();
  }

  Future<void> _loadIdleAnimation() async {
    final frames = <Sprite>[];

    for (int i = 0; i < 14; i++) {
      final frameNumber = i.toString().padLeft(2, '0');
      final framePath = _getFramePath(treeType, frameNumber);
      final sprite = await game.loadSprite(framePath);
      frames.add(sprite);
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: 0.1,
      loop: true,
    );
  }

  String _getFramePath(String treeType, String frameNumber) {
    switch (treeType) {
      case "Cây táo":
        return "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_$frameNumber.png";
      case "Cây xoài":
        return "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_$frameNumber.png";
      default:
        return "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_$frameNumber.png";
    }
  }

  String _getAssetPathForTreeType(String type) {
    switch (type) {
      case "Cây táo":
        return "Cây táo";
      case "Cây xoài":
        return "Cây xoài";
      default:
        return "Cây táo";
    }
  }
}