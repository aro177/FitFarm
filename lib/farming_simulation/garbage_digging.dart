// lib/farming_simulation/garbage_digging.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'farm_game.dart';

class GarbageItem extends SpriteComponent with TapCallbacks, HasGameReference<FarmGame> {
  final String id;
  final Vector2 tilePosition;
  bool isDigged = false;

  GarbageItem({
    required this.id,
    required this.tilePosition,
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(
    sprite: sprite,
    position: position,
    size: size,
    anchor: Anchor.center,
  );

  @override
  void onTapDown(TapDownEvent event) {
    if (!isDigged && game.isDiggingMode) {
      _digGarbage();
    }
  }

  void _digGarbage() {
    isDigged = true;
    removeFromParent();
    game.showMessage?.call('Đã dọn rác! Bây giờ có thể trồng cây ở đây.');
    print("🗑️ Digged garbage at tile (${tilePosition.x}, ${tilePosition.y})");
    game.onGarbageDigged?.call(this);
  }
}