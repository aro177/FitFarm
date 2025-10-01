import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/Model/constants/render_priority.dart';

class CollisionBlock extends PositionComponent{
  late RectangleHitbox hitbox;

  CollisionBlock({super.position, super.size}){
    priority = RenderPriority.ground;
    hitbox = RectangleHitbox(size: size, isSolid: true)
      ..debugColor = Colors.transparent;

    debugColor = Colors.transparent;
  }



  bool get isColliding => hitbox.isColliding;
  bool collidingWith(Hitbox? other){
    if(other == null) return false;
    return hitbox.collidingWith(other);
  }

  @override
  FutureOr<void> onLoad() {
    add(hitbox);
    return super.onLoad();
  }
}