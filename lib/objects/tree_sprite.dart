// objects/tree_sprite.dart
import 'dart:async' as async;
import 'package:fit_farm/objects/tree_sprite.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/farming_simulation/farm_game.dart';

class TreeSprite extends SpriteComponent
    with HasGameReference<FarmGame>, TapCallbacks {
  final String treeType;
  final Rect plantSlot;


  int waterCount = 0;
  DateTime lastWatered = DateTime.now();
  DateTime plantedAt = DateTime.now();
  bool isWithered = false;
  async.Timer? _witheringTimer;

  static const Map<int, int> growthRequirements = {
    1: 5,
    2: 15,
    3: 30,
    4: 50,
  };

  int get currentStage {
    if (waterCount >= growthRequirements[4]!) return 4;
    if (waterCount >= growthRequirements[3]!) return 3;
    if (waterCount >= growthRequirements[2]!) return 2;
    if (waterCount >= growthRequirements[1]!) return 1;
    return 0; // Seed stage
  }

  TreeSprite({
    required Vector2 position,
    required this.treeType,
    required this.plantSlot,
  }) : super(
    position: position,
    size: Vector2(64, 80),
    anchor: Anchor.bottomCenter,
  );


  @override
  Future<void> onLoad() async {
    await _updateTreeSprite();

    _witheringTimer = async.Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkWithering();
    });

    return super.onLoad();
  }

  void _handleWitheringCheck(Timer timer) {
    _checkWithering();
  }

  Future<void> _updateTreeSprite() async {
    if (isWithered) {
      sprite = await game.loadSprite(_getWitheredAssetPath());
    } else {
      sprite = await game.loadSprite(_getTreeAssetPath(currentStage));
    }
  }

  String _getTreeAssetPath(int stage) {
    switch (treeType) {
      case "Cây táo":
        return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s$stage/p_tomato_s${stage}_00.png";
      case "Cây xoài":
        return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s$stage/p_tomato_s${stage}_00.png";
      default:
        return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s$stage/p_tomato_s${stage}_00.png";
    }
  }

  String _getWitheredAssetPath() {
    return "game/images/resources/plants/Tomato/p_tomato/p_tomato_s5/p_tomato_s5_00.png";
  }

  @override
  void onTapDown(TapDownEvent event) {
    _waterTree();
    super.onTapDown(event);
  }

  void _waterTree() {
    final now = DateTime.now();
    final hoursSinceLastWater = now.difference(lastWatered).inHours;

    if (hoursSinceLastWater >= 5) {
      waterCount++;
      lastWatered = now;

      if (isWithered) {
        isWithered = false;
      }

      _updateTreeSprite();

      print("💧 Watered $treeType. Total waters: $waterCount, Stage: $currentStage");

      _showWaterEffect();

    } else {
      final hoursRemaining = 5 - hoursSinceLastWater;
      print("⏳ Cannot water yet. Wait $hoursRemaining more hours");

      (game as FarmGame).showMessage?.call(
          'Cây vẫn còn ẩm! Hãy đợi thêm ${hoursRemaining}h để tưới lại.'
      );
    }
  }

  void _checkWithering() {
    final now = DateTime.now();
    final daysSinceLastWater = now.difference(lastWatered).inDays;

    if (daysSinceLastWater >= 2 && !isWithered) {
      isWithered = true;
      _updateTreeSprite();
      print("🥀 $treeType has withered!");
    }
  }

  void _showWaterEffect() {
    (game as FarmGame).showMessage?.call(
        'Đã tưới nước cho $treeType! Lần tưới: $waterCount'
    );
  }

  Map<String, dynamic> get treeInfo {
    return {
      'type': treeType,
      'waterCount': waterCount,
      'currentStage': currentStage,
      'nextStageWaters': _getNextStageWaters(),
      'isWithered': isWithered,
      'lastWatered': lastWatered,
      'plantedAt': plantedAt,
    };
  }

  int _getNextStageWaters() {
    final nextStage = currentStage + 1;
    if (nextStage > 4) return 0;
    return growthRequirements[nextStage]! - waterCount;
  }
}