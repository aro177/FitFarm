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

    map.scale = Vector2(scaleX, scaleY);

    add(map);

    await _loadPlantableAreas(map);
  }


  Future<void> _loadPlantableAreas(tiled.TiledComponent map) async {
    try {
      final plantSlotsLayer = map.tileMap.map.layers
          .firstWhere((layer) => layer.name == 'PlantSlots') as tiled.ObjectGroup;

      print("✅ Found PlantSlots layer with ${plantSlotsLayer.objects.length} objects");

      for (final obj in plantSlotsLayer.objects) {
        final area = Rect.fromLTWH(
          obj.x * map.scale.x,
          obj.y * map.scale.y,
          obj.width * map.scale.x,
          obj.height * map.scale.y,
        );
        plantableAreas.add(area);
        plantedTrees[area] = null;

        print("🌱 PlantSlot: ID=${obj.id}, Position=(${obj.x}, ${obj.y}), Size=(${obj.width}, ${obj.height})");
        print("🌱 PlantSlot (scaled): Area=$area");
      }

      print(" Total plantable areas: ${plantableAreas.length}");
    } catch (e) {
      print(" Error loading PlantSlots: $e");
      print(" Available layers: ${map.tileMap.map.layers.map((l) => l.name).toList()}");
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    print("🎯 Tap detected at: ${event.canvasPosition}");

    if (selectedTree != null) {
      print("🌳 Selected tree: $selectedTree - Attempting to plant...");
      _plantTreeAtPosition(event.canvasPosition);
    } else {
      print(" No tree selected");
    }
    super.onTapDown(event);
  }

  Rect? _findPlantSlotAtPosition(Vector2 position) {
    print("🔍 Looking for plant slot at: $position");

    for (final slot in plantableAreas) {
      if (slot.contains(position.toOffset())) {
        print("✅ Found plant slot: $slot");
        return slot;
      }
    }

    print(" No plant slot found at: $position");
    print(" Available slots: $plantableAreas");
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

        print("🌱 Creating seed at center: $centerPosition");

        // Tạo seed
        final seed = SeedSprite(
          treeType: selectedTree!,
          targetPosition: centerPosition,
          plantSlot: plantSlot,
        );

        add(seed);
        plantedTrees[plantSlot] = null;

        print("✅ Seed created successfully!");

        selectedTree = null;
        _showMessage("Đã trồng hạt giống! Cây sẽ mọc sau 2 giây...");
      } else {
        print("❌ Plant slot already has a tree!");
        _showMessage("Ô đất này đã có cây!");
      }
    } else {
      print("❌ Cannot plant - no plant slot found!");
      _showMessage("Hãy chọn ô đất màu nâu để trồng cây!");
    }
  }

  //tuoi cay
  void showTreeInfo(Rect plantSlot) {
    final tree = plantedTrees[plantSlot];
    if (tree != null) {
      final info = tree.treeInfo;
      showMessage?.call(
          '${info['type']}\n'
              'Giai đoạn: ${info['currentStage']}/4\n'
              'Số lần tưới: ${info['waterCount']}\n'
              'Cần thêm: ${info['nextStageWaters']} lần tưới\n'
              'Tình trạng: ${info['isWithered'] ? 'Đã héo' : 'Khỏe mạnh'}'
      );
    }
  }

  void _showMessage(String message) {
    showMessage?.call(message);
    print("💬 Message: $message");
  }
}