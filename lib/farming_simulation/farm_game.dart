// lib/farm_game.dart

import 'dart:math';

import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart' as tiled;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarmGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final map = await tiled.TiledComponent.load(
      'game/maps/map.tmx',
      Vector2.all(32),
    );

    final scaleX = size.x / map.width;
    final scaleY = size.y / map.height;
    final scale = min(scaleX, scaleY);

    map.scale = Vector2.all(scale);
    add(map);

  }
}

class FarmGameOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const FarmGameOverlay({Key? key, required this.onClose}) : super(key: key);

  @override
  State<FarmGameOverlay> createState() => _FarmGameOverlayState();
}

class _FarmGameOverlayState extends State<FarmGameOverlay> {
  int coinCount = 0;
  User? user;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('coins')) {
        setState(() {
          coinCount = doc['coins'];
        });
      }
    }
  }

  Future<void> buyItem(int cost) async {
    if (coinCount >= cost && user != null) {
      setState(() {
        coinCount -= cost;
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'coins': coinCount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item purchased!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Coins: $coinCount', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => buyItem(5),
              child: const Text('Buy Sword (5 coins)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => buyItem(10),
              child: const Text('Buy Shield (10 coins)'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.onClose,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
