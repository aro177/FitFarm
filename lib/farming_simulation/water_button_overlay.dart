// lib/farming_simulation/water_button_overlay.dart
import 'package:flutter/material.dart';
import 'farm_game.dart';

class WaterButtonOverlay extends StatelessWidget {
  final FarmGame game;

  const WaterButtonOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 80,
      child: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          _showWaterInfo(context);
        },
        child: const Icon(Icons.water_drop, color: Colors.white),
      ),
    );
  }

  void _showWaterInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 8),
            Text('Hệ thống tưới nước'),
          ],
        ),
        content: Text(
          'Chạm vào cây để tưới nước.\n'
              'Mỗi lần tưới cách nhau 5-6 tiếng.\n'
              'Cây cần nước để phát triển!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}