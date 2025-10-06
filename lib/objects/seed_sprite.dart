import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/farming_simulation/farm_game.dart';
import 'package:fit_farm/objects/tree_sprite.dart';

class SeedSprite extends SpriteComponent with HasGameReference<FarmGame> {
  final String treeType;
  final Vector2 targetPosition;
  final Rect plantSlot;
  final Function(TreeSprite, Rect)? onTreeGrown;

  // Biến để theo dõi số lần tưới nước cho stage 1
  int waterCount = 0;
  final int requiredWaters = 3; // Stage 1 → Stage 2 cần 3 nước

  SeedSprite({
    required this.treeType,
    required this.targetPosition,
    required this.plantSlot,
    this.onTreeGrown,
  }) : super(
    position: targetPosition,
    size: Vector2(32, 32),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    // Load sprite cho stage 1 (seed)
    sprite = await game.loadSprite("game/images/resources/plants/Tomato/p_tomato/p_tomato_s1/p_tomato_s1_00.png");

    return super.onLoad();
  }

  // Phương thức để tưới nước cho stage 1
  void water() {
    if (waterCount >= requiredWaters) return; // Đã đủ nước

    waterCount++;
    debugPrint("💧 Watered seed (Stage 1). Current water count: $waterCount/$requiredWaters");

    // Có thể thêm hiệu ứng visual khi tưới nước
    _showWateringEffect();

    // Kiểm tra nếu đã tưới đủ nước để lên stage 2
    if (waterCount >= requiredWaters) {
      _growToNextStage();
    }
  }

  void _showWateringEffect() {
    debugPrint("💦 Stage 1 received water! $waterCount/$requiredWaters");
    _updateSpriteBasedOnWater();
  }

  void _updateSpriteBasedOnWater() {
    final progress = waterCount / requiredWaters;
    if (progress > 0.66) {
      // Gần đủ nước
    } else if (progress > 0.33) {
      // Đã tưới 1/3
    }
  }

  void _growToNextStage() {
    debugPrint("🌱 Stage 1 grew into Stage 2!");

    final tree = TreeSprite(
      position: targetPosition,
      treeType: treeType,
      plantSlot: plantSlot,
      currentStage: 2,
      waterCount: 0,
    );

    game.add(tree);
    (game as FarmGame).plantedTrees[plantSlot] = tree;

    onTreeGrown?.call(tree, plantSlot);

    removeFromParent();

    _showMessage("Cây đã phát triển lên giai đoạn 2!");
  }

  void _showMessage(String message) {
    (game as FarmGame).showMessage?.call(message);
  }

  // Getter để lấy thông tin stage 1
  Map<String, dynamic> get seedInfo {
    return {
      'type': treeType,
      'stage': 1,
      'waterCount': waterCount,
      'requiredWaters': requiredWaters,
      'progress': waterCount / requiredWaters,
      'position': targetPosition,
      'nextStageWaters': requiredWaters - waterCount,
    };
  }
}