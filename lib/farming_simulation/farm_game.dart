// lib/farming_simulation/farm_game.dart
import 'package:fit_farm/objects/tree_sprite.dart';
import 'package:fit_farm/objects/seed_sprite.dart';
import 'package:fit_farm/farming_simulation/garbage_digging.dart';
import 'package:flame/components.dart';
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
  bool isDiggingMode = false;

  Future<bool> Function()? _useWaterCallback;
  int _currentWaterCount = 0;

  final List<GarbageItem> garbageItems = [];
  Function(GarbageItem)? onGarbageDigged;

  FarmGame({this.selectedTree});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadMap();
    onGarbageDigged = _handleGarbageDigged;
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
    await _loadGarbageTiles(map);
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

  Future<void> _loadGarbageTiles(tiled.TiledComponent map) async {
    try {
      final garbageLayer = map.tileMap.map.layers
          .firstWhere((layer) => layer.name == 'rac') as tiled.TileLayer;

      print("🗑️ Found rac tile layer with size: ${garbageLayer.width}x${garbageLayer.height}");

      final tileSize = Vector2(32, 32);
      int garbageCount = 0;

      // Load tất cả sprite rác
      final garbageSprites = await _loadAllGarbageSprites();

      print("🔄 Loaded ${garbageSprites.length} garbage sprites");

      for (int x = 0; x < garbageLayer.width; x++) {
        for (int y = 0; y < garbageLayer.height; y++) {
          final index = y * garbageLayer.width + x;
          final tile = garbageLayer.tileData![index];

          if (tile != 0) {
            final garbageId = 'garbage_${x}_${y}';

            final position = Vector2(
              x * tileSize.x * map.scale.x + (tileSize.x * map.scale.x) / 2,
              y * tileSize.y * map.scale.y + (tileSize.y * map.scale.y) / 2,
            );

            final size = Vector2(
              tileSize.x * map.scale.x,
              tileSize.y * map.scale.y,
            );

            final garbageSprite = garbageSprites[garbageCount % garbageSprites.length];

            final garbageItem = GarbageItem(
              id: garbageId,
              tilePosition: Vector2(x.toDouble(), y.toDouble()),
              sprite: garbageSprite,
              position: position,
              size: size,
            );

            add(garbageItem);
            garbageItems.add(garbageItem);
            garbageCount++;

            print("🗑️ Garbage at tile ($x, $y) - Type: $garbageId");
          }
        }
      }

      print(" Total garbage items loaded: $garbageCount");
    } catch (e) {
      print(" Error loading rac tile layer: $e");
    }
  }

  Future<List<Sprite>> _loadAllGarbageSprites() async {
    final garbageFiles = [
      'game/images/resources/background/Spring/i_bg_dirtBottle_spring.png',
      'game/images/resources/background/Spring/i_bg_dirtGrass_spring.png',
      'game/images/resources/background/Spring/i_bg_dirtOil_spring.png',
      'game/images/resources/background/Spring/i_bg_dirtPesticides_spring.png',
      'game/images/resources/background/Spring/i_bg_dirtRadioactive_spring.png',
    ];

    final sprites = <Sprite>[];

    for (final file in garbageFiles) {
      try {
        final sprite = await Sprite.load(file);
        sprites.add(sprite);
        print("✅ Loaded garbage sprite: $file");
      } catch (e) {
        print("❌ Failed to load garbage sprite: $file - $e");
      }
    }

    return sprites;
  }

  @override
  void onTapDown(TapDownEvent event) {
    print("🎯 Tap detected at: ${event.canvasPosition}");

    if (isDiggingMode) {
      print("⛏️ Digging mode active - checking for garbage...");
      _checkForGarbageAtPosition(event.canvasPosition);
    } else if (isWateringMode) {
      print("💧 Watering mode active - attempting to water...");
      _waterAtPosition(event.canvasPosition);
    } else if (selectedTree != null) {
      print("🌳 Selected tree: $selectedTree - Attempting to plant...");
      _plantTreeAtPosition(event.canvasPosition);
    } else {
      print(" No mode active, checking for tree info...");
      _checkForTreeInfo(event.canvasPosition);
    }
    super.onTapDown(event);
  }

  // Kiểm tra có rác tại vị trí tap không
  void _checkForGarbageAtPosition(Vector2 position) {
    bool foundGarbage = false;

    // Kiểm tra các garbage items
    for (final garbage in garbageItems) {
      if (!garbage.isDigged && garbage.containsPoint(position)) {
        foundGarbage = true;
        break;
      }
    }

    if (!foundGarbage) {
      _showMessage("Không có rác ở đây! Bạn có thể trồng cây.");
    }
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
      // Kiểm tra xem ô đất này có đang bị rác che không
      if (_isPlantSlotBlockedByGarbage(plantSlot)) {
        _showMessage("Ô đất này đang bị rác che! Hãy dọn rác trước.");
        return;
      }

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

  // Kiểm tra ô đất có bị rác che không
  bool _isPlantSlotBlockedByGarbage(Rect plantSlot) {
    for (final garbage in garbageItems) {
      if (!garbage.isDigged) {
        final garbageRect = Rect.fromCenter(
          center: garbage.position.toOffset(),
          width: garbage.size.x,
          height: garbage.size.y,
        );

        // Nếu rác nằm trong hoặc chồng lên plant slot
        if (garbageRect.overlaps(plantSlot)) {
          return true;
        }
      }
    }
    return false;
  }

  // Phương thức tưới nước
  void _waterAtPosition(Vector2 position) {
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

  // Bật/tắt chế độ tưới nước
  void toggleWateringMode(int waterCount, Future<bool> Function() useWaterCallback) {
    isWateringMode = !isWateringMode;
    isDiggingMode = false; // Tắt chế độ đào rác
    selectedTree = null; // Tắt chế độ trồng cây nếu đang bật

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

  // Bật/tắt chế độ đào rác
  void toggleDiggingMode() {
    isDiggingMode = !isDiggingMode;
    isWateringMode = false; // Tắt chế độ tưới nước
    selectedTree = null; // Tắt chế độ trồng cây

    if (isDiggingMode) {
      final remainingGarbage = garbageItems.where((g) => !g.isDigged).length;
      if (remainingGarbage <= 0) {
        _showMessage("Không còn rác để dọn!");
        isDiggingMode = false;
      } else {
        _showMessage("Chế độ dọn rác đã bật!\nChạm vào rác để dọn.\nCòn $remainingGarbage rác.");
      }
    } else {
      _showMessage("Chế độ dọn rác đã tắt");
    }
  }

  // Xử lý khi rác được đào
  void _handleGarbageDigged(GarbageItem garbage) {
    print("🗑️ Garbage dug at tile (${garbage.tilePosition.x}, ${garbage.tilePosition.y})");

    // Kiểm tra nếu không còn rác nào thì tắt chế độ đào
    final remainingGarbage = garbageItems.where((g) => !g.isDigged).length;
    if (remainingGarbage <= 0) {
      isDiggingMode = false;
      _showMessage("Đã dọn sạch tất cả rác! Có thể trồng cây ở mọi ô đất.");
    }
  }

  // Getter để lấy số rác chưa đào
  int get remainingGarbageCount {
    return garbageItems.where((garbage) => !garbage.isDigged).length;
  }

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