// objects/seed_sprite.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/farming_simulation/farm_game.dart';
import 'package:fit_farm/objects/tree_sprite.dart';

class SeedSprite extends SpriteComponent with HasGameReference<FarmGame> {
  final String treeType;
  final Vector2 targetPosition;
  final Rect plantSlot;

  SeedSprite({
    required this.treeType,
    required this.targetPosition,
    required this.plantSlot,
  }) : super(
    position: targetPosition,
    size: Vector2(32, 32),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite("game/images/resources/plants/Tomato/p_tomato/p_tomato_s1/seed.png");

    _startGrowthTimer();

    return super.onLoad();
  }

  void _startGrowthTimer() {
    Future.delayed(Duration(seconds: 2), () {
      _replaceWithTree();
    });
  }

  void _replaceWithTree() {
    final tree = TreeSprite(
      position: targetPosition,
      treeType: treeType,
    );

    game.add(tree);

    (game as FarmGame).plantedTrees[plantSlot] = tree;

    removeFromParent();

    debugPrint("🌱 Seed grew into tree at $targetPosition");
  }
}