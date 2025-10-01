// lib/farming_simulation/farm_game.dart
import 'package:fit_farm/objects/tree_sprite.dart';
import 'package:flame/events.dart';
import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart' as tiled;
import 'package:flutter/material.dart';

class FarmGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  String? selectedTree;
  FarmGame({this.selectedTree});
  final List<Rect> plantableAreas = [];
  final Map<Rect, TreeSprite?> plantedTrees = {};

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

    // Lấy kích thước map theo pixel
  final mapWidth = map.tileMap.map.width * 32;
  final mapHeight = map.tileMap.map.height * 32;

  // Tính scale theo màn hình
  final scaleX = size.x / mapWidth;
  final scaleY = size.y / mapHeight;
  final scale = min(scaleX, scaleY);

  map.scale = Vector2.all(scale);

    map.scale = Vector2.all(scale);
    add(map);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (selectedTree != null) {
      _plantTreeAtPosition(event.canvasPosition);
    }
    super.onTapDown(event);
  }

  Future<void> _loadPlantableAreas(tiled.TiledComponent map) async {
    try {
      final plantSlotsLayer = map.tileMap.map.layers
          .firstWhere((layer) => layer.name == 'PlantSlots') as tiled.ObjectGroup;

      for (final obj in plantSlotsLayer.objects) {
        // Lấy vùng từ object rectangle (đã scale)
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
      debugPrint(" Error loading PlantSlots: $e");
    }
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

    // Tạo cây tại vị trí tap
    final tree = TreeSprite(
      position: position,
      treeType: selectedTree!,
    );

    add(tree);

    debugPrint("🌳 Planted $selectedTree at $position");

    // Reset selected tree sau khi trồng
    selectedTree = null;
  }
}