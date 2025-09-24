import 'dart:async';
import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/scenes/worlds/farm_world.dart';

class SproutValley extends FlameGame {
  late BuildContext gameContext;
  late CameraComponent cameraComponent;
  late RouterComponent router;



  late TiledComponent farmTiled;

  void initBuildContext(BuildContext context) {
    gameContext = context;
  }

  @override
  FutureOr<void> onLoad() async {
    await loadFarm();
    await loadRouterWorld();
    return super.onLoad();
  }

  Future<void> loadFarm() async {
    farmTiled = await TiledComponent.load(
      'farm/farm.tmx',
      Vector2.all(16),
    );
  }

  loadRouterWorld() async {
    cameraComponent = CameraComponent();
    router = RouterComponent(routes: {
      'farm': WorldRoute(
            () {
          final farmWorld = FarmWorld();
          cameraComponent.world = farmWorld;
          return farmWorld;
        },
        maintainState: false,
      ),
    }, initialRoute: 'farm');

    await addAll([cameraComponent, router]);
  }
}
