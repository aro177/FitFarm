import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/Model/blocks/collision_block.dart';
import 'package:fit_farm/Model/constants/global_constants.dart';
import 'package:fit_farm/Model/constants/render_priority.dart';
import 'package:fit_farm/objects/leaves_sprite.dart';
import 'package:fit_farm/sprout_valley.dart';

class TreeSprite extends SpriteAnimationComponent
    with HasGameReference<SproutValley>, CollisionCallbacks, TapCallbacks {
  late SpriteAnimation idleTree, fallTree;

  late CollisionBlock trunkHitbox;

  late Vector2 srcSize = Vector2(64, 48);

  bool isFallen = false;

  TreeSprite({required Vector2 position})
      : super(
    position: position,
    priority: RenderPriority.ground,
    scale: Vector2(WORLD_SCALE + 0.5, WORLD_SCALE + 0.5),
  );

  @override
  bool get debugMode => true;

  @override
  Color get debugColor => Colors.transparent;

  @override
  FutureOr<void> onLoad() async {
    await loadAssets();
    await loadHitbox();
    return super.onLoad();
  }

  //chỉnh sprite
  loadAssets() async {
    idleTree = _createSpriteSheetAnimation(
      "environments/trees/tree.png",
      length: 1,
      loop: false,
    );
    fallTree = _createSpriteSheetAnimation(
      "environments/trees/fall_tree.png",
      loop: false,
      spacing: 0,
      length: 12,
    );

    animation = idleTree;
  }

  loadHitbox() async {
    trunkHitbox = CollisionBlock(
      size: Vector2(10, 6),
      position: Vector2(35, 35),
    );
    await add(trunkHitbox);
  }

  SpriteAnimation _createSpriteSheetAnimation(
      String name, {
        int length = 7,
        double stepTime = 0.1,
        bool loop = true,
        double spacing = 1,
      }) {
    return SpriteSheet(
      image: game.images.fromCache(name),
      srcSize: srcSize,
      spacing: spacing,
    ).createAnimation(
      row: 0,
      to: length,
      stepTime: stepTime,
      loop: loop,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isFallen) {
      animateFallTree();
    }
    super.onTapDown(event);
  }

  showLeaves() {
    var leaves1 = LeavesSprite(
        position:
        Vector2(position.x + (38 * WORLD_SCALE), position.y + (20 * WORLD_SCALE)));
    var leaves2 = LeavesSprite(
        position:
        Vector2(position.x + (48 * WORLD_SCALE), position.y + (20 * WORLD_SCALE)));

    parent?.addAll([leaves1, leaves2]);
  }

  animateFallTree() {
    isFallen = true;
    animation = fallTree;

    if (animation != null && animationTicker != null) {
      animationTicker!.onFrame = (indexFrame) {
        if (indexFrame == 2) {
          showLeaves();
        }
      };

      animationTicker!.onComplete = () {
        remove(trunkHitbox);
        removeFromParent();
      };
    }
  }
}
