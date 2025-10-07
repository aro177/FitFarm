import 'package:flutter/material.dart';

enum CropType { carrot, potato }

class CropTile {
  final int x;
  final int y;
  bool hasCrop;
  CropType? crop;

  CropTile({required this.x, required this.y, this.hasCrop = false, this.crop});

  void plant(CropType type) {
    if (!hasCrop) {
      crop = type;
      hasCrop = true;
      debugPrint("🌱 Planted $type at ($x,$y)");
    }
  }

  void interact() {
    if (hasCrop) {
      debugPrint("⛏ Removed $crop at ($x,$y)");
      crop = null;
      hasCrop = false;
    }
  }
}
