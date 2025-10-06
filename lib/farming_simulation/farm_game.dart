// lib/farming_simulation/farm_game.dart
import 'package:fit_farm/objects/tree_sprite.dart';
import 'package:fit_farm/objects/seed_sprite.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart' as tiled;
import 'package:flutter/material.dart';

class FarmGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  String? selectedTree;
  final List<Rect> plantableAreas = [];
  final Map<Rect, TreeSprite?> plantedTrees = {};
  Function(String)? showMessage;
  bool isWateringMode = false;

  // Callback để sử dụng nước từ Firestore
  Future<bool> Function()? _useWaterCallback;
  int _currentWaterCount = 0;

  FarmGame({this.selectedTree});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadMap();
  }

  Future<void> _loadMap() async {
    final map = await tiled.TiledComponent.load(
      'game/maps/spring_map.tmx',
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

    if (isWateringMode) {
      print("💧 Watering mode active - attempting to water...");
      _waterAtPosition(event.canvasPosition);
    } else if (selectedTree != null) {
      print("🌳 Selected tree: $selectedTree - Attempting to plant...");
      _plantTreeAtPosition(event.canvasPosition);
    } else {
      print(" No tree selected, checking for tree info...");
      _checkForTreeInfo(event.canvasPosition);
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

  // Kiểm tra ô đất đã có cây hoặc seed chưa
  bool _isPlantSlotOccupied(Rect plantSlot) {
    // Kiểm tra trong plantedTrees
    if (plantedTrees[plantSlot] != null) {
      return true;
    }

    // Kiểm tra trong các SeedSprite đang tồn tại
    for (final component in children.whereType<SeedSprite>()) {
      if (component.plantSlot == plantSlot) {
        return true;
      }
    }

    return false;
  }

  void _plantTreeAtPosition(Vector2 position) {
    if (selectedTree == null) return;

    final plantSlot = _findPlantSlotAtPosition(position);

    if (plantSlot != null) {
      if (!_isPlantSlotOccupied(plantSlot)) {
        final centerPosition = Vector2(
          plantSlot.left + plantSlot.width / 2,
          plantSlot.top + plantSlot.height / 2,
        );

        print("🌱 Creating seed at center: $centerPosition");

        // Tạo seed với callback khi seed phát triển thành cây
        final seed = SeedSprite(
          treeType: selectedTree!,
          targetPosition: centerPosition,
          plantSlot: plantSlot,
          onTreeGrown: _onTreeGrown,
        );

        add(seed);
        plantedTrees[plantSlot] = null;

        print("✅ Seed created successfully!");

        selectedTree = null;
        _showMessage("Đã trồng hạt giống!");
      } else {
        print("❌ Plant slot already has a tree or seed!");
        _showMessage("Ô đất này đã có cây hoặc hạt giống!");
      }
    } else {
      print("❌ Cannot plant - no plant slot found!");
      _showMessage("Hãy chọn ô đất màu nâu để trồng cây!");
    }
  }

  // Phương thức tưới nước - SỬ DỤNG CALLBACK TỪ FIREBASE
  void _waterAtPosition(Vector2 position) {
    // Kiểm tra nếu không có callback sử dụng nước
    if (_useWaterCallback == null) {
      _showMessage("Lỗi hệ thống nước! Vui lòng thử lại.");
      isWateringMode = false;
      return;
    }

    bool foundWaterable = false;

    // Kiểm tra nếu tap vào seed (stage 1)
    for (final component in children.whereType<SeedSprite>()) {
      if (component.containsPoint(position)) {
        foundWaterable = true;
        _useWaterAndWaterPlant(() => component.water(), "hạt giống");
        break;
      }
    }

    // Nếu chưa tìm thấy seed, kiểm tra cây (stage 2-4)
    if (!foundWaterable) {
      final plantSlot = _findPlantSlotAtPosition(position);
      if (plantSlot != null) {
        final tree = plantedTrees[plantSlot];
        if (tree != null && tree.containsPoint(position)) {
          foundWaterable = true;
          _useWaterAndWaterPlant(() => tree.water(), "cây");
        }
      }
    }

    if (!foundWaterable) {
      _showMessage("Không có cây hoặc hạt giống để tưới nước!");
    }
  }

  // Phương thức sử dụng nước và tưới cây
  void _useWaterAndWaterPlant(Function() waterPlant, String plantType) async {
    if (_useWaterCallback == null) return;

    // Sử dụng nước từ Firestore
    final waterUsed = await _useWaterCallback!();

    if (waterUsed) {
      // Nếu sử dụng nước thành công, tưới cây
      waterPlant();
      _showMessage("Đã tưới nước cho $plantType!\nNước còn lại: ${_currentWaterCount - 1}");
    } else {
      // Nếu không đủ nước
      _showMessage("Không đủ nước trong kho!");
      isWateringMode = false;
    }
  }

  // Kiểm tra thông tin cây/seed
  void _checkForTreeInfo(Vector2 position) {
    // Kiểm tra seed trước
    for (final component in children.whereType<SeedSprite>()) {
      if (component.containsPoint(position)) {
        final info = component.seedInfo;
        _showMessage(
            'Hạt giống ${info['type']}\n'
                'Giai đoạn: ${info['stage']}/4\n'
                'Đã tưới: ${info['waterCount']}/${info['requiredWaters']} lần\n'
                'Cần thêm: ${info['nextStageWaters']} lần tưới'
        );
        return;
      }
    }

    // Nếu không có seed, kiểm tra cây
    final plantSlot = _findPlantSlotAtPosition(position);
    if (plantSlot != null) {
      showTreeInfo(plantSlot);
    }
  }

  // Bật/tắt chế độ tưới nước - NHẬN CALLBACK TỪ WATER_BUTTON_OVERLAY
  void toggleWateringMode(int waterCount, Future<bool> Function() useWaterCallback) {
    isWateringMode = !isWateringMode;
    selectedTree = null; // Tắt chế độ trồng cây nếu đang bật

    // Lưu callback và số nước hiện tại
    _useWaterCallback = useWaterCallback;
    _currentWaterCount = waterCount;

    if (isWateringMode) {
      if (waterCount <= 0) {
        _showMessage("Bạn không có nước trong kho!");
        isWateringMode = false;
        _useWaterCallback = null;
      } else {
        _showMessage("Chế độ tưới nước đã bật\nNước trong kho: $waterCount");
      }
    } else {
      _showMessage("Chế độ tưới nước đã tắt");
      _useWaterCallback = null;
    }
  }

  // Callback khi seed phát triển thành cây
  void _onTreeGrown(TreeSprite tree, Rect plantSlot) {
    plantedTrees[plantSlot] = tree;
    add(tree);
    print("🌱 Seed grew into tree at [${tree.position.x},${tree.position.y}]");
  }

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

  void resetWateringMode() {
    isWateringMode = false;
    _useWaterCallback = null;
    _currentWaterCount = 0;
  }

  bool get hasWaterCallback => _useWaterCallback != null;
  int get currentWaterCount => _currentWaterCount;
}