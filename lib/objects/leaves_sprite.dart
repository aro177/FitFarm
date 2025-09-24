import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:fit_farm/Model/constants/global_constants.dart';
import 'package:fit_farm/Model/constants/render_priority.dart';
import 'package:fit_farm/sprout_valley.dart';

// chinh animation
class LeavesSprite extends SpriteAnimationComponent
    with HasGameReference<SproutValley>{

  late SpriteAnimation leaves ;

  Vector2 srcSize = Vector2(5, 4);

  final Random _random = Random();
  Vector2 velocity = Vector2.zero();
  double windDirection = 0.0;
  double rotationSpeed = 0.0;
  double gravity = 20;

  double targetY = 0.0;

  LeavesSprite({required Vector2 position}): super(
      position: position,
      priority: RenderPriority.environment,
      scale: Vector2(WORLD_SCALE, WORLD_SCALE)
  );

  @override
  bool get debugMode => false;

  @override
  FutureOr<void> onLoad() async{
    await loadAssets();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    windEffect(dt);
    super.update(dt);
  }

  void _reset() {
    angle = _random.nextDouble() * 2 * pi;
    velocity = Vector2(0, _random.nextDouble() * 50 + 50);
    windDirection = (_random.nextDouble() - 0.5) * 40; // Random drift
    rotationSpeed = (_random.nextDouble() - 0.5) * 2; // Random spin speed
    position.y = position.y + (_random.nextDouble() * 1);
    targetY = position.y + 120;
  }

  windEffect(double dt){
    velocity.y += gravity * dt;
    velocity.x += windDirection * dt;
    position += velocity * dt;
    angle += rotationSpeed * dt;

    if(position.y > targetY){
      removeFromParent();
    }
  }

  loadAssets()async{
    leaves = _createSpriteSheetAnimation('environments/trees/leaves.png');
    animation = leaves;

    _reset();
  }

  _createSpriteSheetAnimation(String name, {int length = 1, double stepTime = 0.1, bool loop = true, double spacing = 0}){
    return SpriteSheet(
      image: game.images.fromCache(name),
      srcSize: srcSize,
      spacing: spacing,
    ).createAnimation(
        row: 0,
        to: length,
        stepTime: stepTime,
        loop: loop
    );
  }
}