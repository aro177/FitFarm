// lib/farming_simulation/farm_game.dart
import 'package:fit_farm/objects/tree_sprite.dart';
import 'package:fit_farm/objects/seed_sprite.dart';
import 'package:flame/events.dart';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart' as tiled;
import 'package:flutter/material.dart';

class FarmGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  String? selectedTree;
  final List<Rect> plantableAreas = [];
  final Map<Rect, TreeSprite?> plantedTrees = {};
  Function(String)? showMessage;

  FarmGame({this.selectedTree});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadMap();
  }

  Future<void> _loadMap() async {
    final map = await tiled.TiledComponent.load(
      'game/maps/map.tmx',
      Vector2.all(32),
    );

    final scaleX = size.x / map.width;
    final scaleY = size.y / map.height;
    final scale = min(scaleX, scaleY);

    map.scale = Vector2.all(scale);
    add(map);

    await _loadPlantableAreas(map);
  }

  Future<void> _loadPlantableAreas(tiled.TiledComponent map) async {
    try {
      final plantSlotsLayer = map.tileMap.map.layers
          .firstWhere((layer) => layer.name == 'PlantSlots') as tiled.ObjectGroup;

      for (final obj in plantSlotsLayer.objects) {
        final area = Rect.fromLTWH(
          obj.x * map.scale.x,
          obj.y * map.scale.y,
          obj.width * map.scale.x,
          obj.height * map.scale.y,
        );
        plantableAreas.add(area);
        plantedTrees[area] = null;
        debugPrint("🌱 PlantSlot: ID=${obj.id}, Area=$area");
      }
      debugPrint("✅ Loaded ${plantableAreas.length} plant slots");
    } catch (e) {
      debugPrint("❌ Error loading PlantSlots: $e");
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (selectedTree != null) {
      _plantTreeAtPosition(event.canvasPosition);
    }
    super.onTapDown(event);
  }

  Rect? _findPlantSlotAtPosition(Vector2 position) {
    for (final slot in plantableAreas) {
      if (slot.contains(position.toOffset())) {
        return slot;
      }
    }
    return null;
  }

  void _plantTreeAtPosition(Vector2 position) {
    if (selectedTree == null) return;

    final plantSlot = _findPlantSlotAtPosition(position);

    if (plantSlot != null) {
      if (plantedTrees[plantSlot] == null) {
        final centerPosition = Vector2(
          plantSlot.left + plantSlot.width / 2,
          plantSlot.top + plantSlot.height / 2,
        );

        // TẠO HẠT GIỐNG TRƯỚC
        final seed = SeedSprite(
          treeType: selectedTree!,
          targetPosition: centerPosition,
          plantSlot: plantSlot,
        );

        add(seed);
        plantedTrees[plantSlot] = null;

        debugPrint("🌱 Planted seed for $selectedTree at $centerPosition");

        selectedTree = null;
        _showMessage("Đã trồng hạt giống! Cây sẽ mọc sau 2 giây...");
      } else {
        _showMessage("Ô đất này đã có cây!");
      }
    } else {
      _showMessage("Hãy chọn ô đất màu nâu để trồng cây!");
    }
  }

  void _showMessage(String message) {
    showMessage?.call(message);
  }
}