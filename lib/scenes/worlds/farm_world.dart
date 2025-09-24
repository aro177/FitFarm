// lib/scenes/worlds/farm_world.dart
import 'dart:async';
import 'dart:math'; // Rectangle

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

import 'package:fit_farm/Model/blocks/collision_block.dart';


import 'package:fit_farm/Model/constants/global_constants.dart';
import 'package:fit_farm/Model/constants/render_priority.dart';
import '/sprout_valley.dart';

class FarmWorld extends World with HasGameReference<SproutValley> {
  late TiledComponent mapTiled;
  late Vector2 tileMapSize;

  @override
  bool get debugMode => true;
  @override
  Color get debugColor => Colors.transparent;

  @override
  FutureOr<void> onLoad() async {
    await loadMaps();           
    await loadOverlays();
    await loadCollision();
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    setCameraBounds(size);
  }

  void setCameraBounds(Vector2 size) {
    game.cameraComponent.setBounds(
      Rectangle.fromLTRB(
        size.x / 2,
        size.y / 2,
        (tileMapSize.x - WORLD_SCALE) - size.x / 2,
        (tileMapSize.y - WORLD_SCALE) - size.y / 2,
      ),
    );
  }

  Future<void> loadMaps() async {
    // Path và tile size: chỉnh theo project của bạn
    mapTiled = await TiledComponent.load(
      'farm/farm.tmx',
      Vector2.all(WORLD_TILE_SIZE),
      // images: Images(prefix: 'assets/images/resources/'),
      priority: RenderPriority.ground,
    );

    tileMapSize = Vector2(
      mapTiled.tileMap.map.width * WORLD_SCALE,
      mapTiled.tileMap.map.height * WORLD_SCALE,
    );

    await add(mapTiled);
  }

  Future<void> loadOverlays() async {
    game.overlays.add("toolbox_panel");
  }

  Future<void> loadCollision() async {
    await loadWallCollision();
    await loadHouseWallCollision();
  }


  Future<void> loadWallCollision() async {
    final objectLayer = mapTiled.tileMap.getLayer<ObjectGroup>('walls');
    if (objectLayer == null) return;
    for (final TiledObject object in objectLayer.objects) {
      final block = CollisionBlock(
        position: Vector2(object.x * WORLD_SCALE, object.y * WORLD_SCALE),
        size: Vector2(object.width * WORLD_SCALE, object.height * WORLD_SCALE),
      );
      await add(block);
    }
  }

  Future<void> loadHouseWallCollision() async {
    final objectLayer = mapTiled.tileMap.getLayer<ObjectGroup>('house_walls');
    if (objectLayer == null) return;
    for (final TiledObject object in objectLayer.objects) {
      final block = CollisionBlock(
        position: Vector2(object.x * WORLD_SCALE, object.y * WORLD_SCALE),
        size: Vector2(object.width * WORLD_SCALE, object.height * WORLD_SCALE),
      );
      await add(block);
    }
  }

}
