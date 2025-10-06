// lib/farming_simulation/water_button_overlay.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'farm_game.dart';

class WaterButtonOverlay extends StatefulWidget {
  final FarmGame game;

  const WaterButtonOverlay({Key? key, required this.game}) : super(key: key);

  @override
  State<WaterButtonOverlay> createState() => _WaterButtonOverlayState();
}

class _WaterButtonOverlayState extends State<WaterButtonOverlay> {
  int _waterCount = 0;
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _waterCount = doc.data()?['water'] ?? 0;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateWaterData() async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'water': _waterCount,
      });
    }
  }

  // Sử dụng nước từ Firestore
  Future<bool> _useWater() async {
    if (_waterCount <= 0) {
      return false;
    }

    setState(() {
      _waterCount--;
    });

    await _updateWaterData();
    return true;
  }

  // Thêm nước (cho testing)
  Future<void> _addWater() async {
    setState(() {
      _waterCount++;
    });
    await _updateWaterData();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 80,
      child: Column(
        children: [
          SizedBox(height: 10),
          FloatingActionButton(
            backgroundColor: widget.game.isWateringMode ? Colors.green : Colors.blue,
            onPressed: () {
              _toggleWateringMode();
            },
            child: Icon(
              Icons.water_drop,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleWateringMode() {
    if (_isLoading) return;

    if (_waterCount <= 0) {
      _showWaterError(context);
      return;
    }

    widget.game.toggleWateringMode(_waterCount, _useWater);
    if (widget.game.isWateringMode) {
      _showWaterInfo(context);
    }
    setState(() {});
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
          'Chế độ tưới nước đã bật!\n'
              'Chạm vào cây hoặc hạt giống để tưới nước.\n'
              'Mỗi lần tưới sẽ tiêu hao 1 nước từ kho.\n'
              'Nước trong kho: $_waterCount',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showWaterError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Không đủ nước'),
          ],
        ),
        content: Text(
          'Bạn không có nước trong kho!\n'
              'Hãy mua thêm nước từ cửa hàng.',
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