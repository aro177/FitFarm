// lib/farming_simulation/digging_button_overlay.dart
import 'package:flutter/material.dart';
import 'farm_game.dart';

class DiggingButtonOverlay extends StatelessWidget {
  final FarmGame game;

  const DiggingButtonOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 140,
      child: Column(
        children: [
          SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: game.isDiggingMode ? Colors.orange : Colors.brown,
            onPressed: () {
              game.toggleDiggingMode();
            },
            child: Icon(
              Icons.construction,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}