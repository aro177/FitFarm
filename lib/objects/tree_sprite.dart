// objects/tree_sprite.dart
import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/farming_simulation/farm_game.dart';

class TreeSprite extends SpriteComponent
    with HasGameReference<FarmGame>, TapCallbacks {
  final String treeType;
  final Rect plantSlot;
  int currentStage;
  int waterCount;

  DateTime lastWatered = DateTime.now();
  DateTime plantedAt = DateTime.now();
  bool isWithered = false;
  async.Timer? _witheringTimer;

  // GROWTH REQUIREMENTS MỚI - Thống nhất với seed_sprite
  static const Map<int, int> growthRequirements = {
    2: 4, // Stage 2 → Stage 3 cần 4 nước
    3: 5, // Stage 3 → Stage 4 cần 5 nước
    4: 0, // Stage 4 là cuối cùng
  };

  TreeSprite({
    required Vector2 position,
    required this.treeType,
    required this.plantSlot,
    this.currentStage = 2,
    this.waterCount = 0,
  }) : super(
    position: position,
    size: Vector2(64, 80),
    anchor: Anchor.bottomCenter,
  );

  @override
  Future<void> onLoad() async {
    await _updateTreeSprite();

    // Timer kiểm tra héo mỗi phút
    _witheringTimer = async.Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkWithering();
    });

    return super.onLoad();
  }

  @override
  void onRemove() {
    _witheringTimer?.cancel();
    super.onRemove();
  }

  Future<void> _updateTreeSprite() async {
    try {
      final stage = currentStage;
      // Nếu cây bị héo, dùng sprite stage 5
      final actualStage = isWithered ? 5 : stage;
      sprite = await game.loadSprite(_getTreeAssetPath(actualStage));
      print("🌳 Updated $treeType to stage $actualStage (waters: $waterCount)");
    } catch (e) {
      print("❌ ERROR loading tree sprite: $e");
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

  @override
  void onTapDown(TapDownEvent event) {
    _waterTree();
    super.onTapDown(event);
  }

  // Trong class TreeSprite, sửa phương thức _waterTree()
  void _waterTree() {
    // KHÔNG kiểm tra isWateringMode ở đây nữa, vì đã kiểm tra trong farm_game
    // Chỉ thực hiện logic tưới nước cụ thể cho cây

    final now = DateTime.now();
    final minutesSinceLastWater = now.difference(lastWatered).inMinutes;

    // 5 phút chờ tưới lại (giữ nguyên)
    if (minutesSinceLastWater >= 5) {
      waterCount++;
      lastWatered = now;

      if (isWithered) {
        isWithered = false;
        _updateTreeSprite(); // Cập nhật sprite khi hồi sinh
      }

      // Kiểm tra phát triển stage
      _checkGrowth();

      _showWaterEffect();

    } else {
      final minutesRemaining = 5 - minutesSinceLastWater;
      (game as FarmGame).showMessage?.call(
          'Cây vẫn còn ẩm! Hãy đợi thêm ${minutesRemaining} phút để tưới lại.'
      );
    }
  }

  void _checkGrowth() {
    if (currentStage >= 4 || isWithered) return;

    final requiredWaters = growthRequirements[currentStage] ?? 0;

    if (waterCount >= requiredWaters && requiredWaters > 0) {
      currentStage++;
      waterCount = 0; // Reset water count cho stage mới

      print("🌳 $treeType grew to stage $currentStage!");
      _updateTreeSprite();

      (game as FarmGame).showMessage?.call(
          '$treeType đã phát triển lên giai đoạn $currentStage!'
      );
    }
  }

  void _checkWithering() {
    if (isWithered || currentStage >= 4) return;

    final now = DateTime.now();
    final minutesSinceLastWater = now.difference(lastWatered).inMinutes;

    // 30 phút không tưới thì héo (stage 5)
    if (minutesSinceLastWater >= 30) {
      isWithered = true;
      _updateTreeSprite();
      print("🥀 $treeType has withered after 30 minutes without water!");

      (game as FarmGame).showMessage?.call(
          '$treeType đã bị héo do thiếu nước!'
      );
    }
  }

  void _showWaterEffect() {
    final nextStageWaters = _getNextStageWaters();

    String message = 'Đã tưới nước cho $treeType!\nLần tưới: $waterCount\nGiai đoạn: ${isWithered ? "Héo" : "$currentStage/4"}';

    if (!isWithered) {
      if (currentStage < 4 && nextStageWaters > 0) {
        message += '\nCần thêm $nextStageWaters lần tưới để lên giai đoạn ${currentStage + 1}';
      } else if (currentStage == 4) {
        message += '\nCây đã đạt giai đoạn tối đa!';
      }
    } else {
      message += '\nCây đang bị héo, cần được tưới nước!';
    }

    (game as FarmGame).showMessage?.call(message);
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
    if (isWithered || currentStage >= 4) return 0;

    final requiredWaters = growthRequirements[currentStage] ?? 0;
    return requiredWaters - waterCount;
  }

  void water() {
    _waterTree();
  }
}