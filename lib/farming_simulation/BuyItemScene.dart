import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyItemGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Do nothing here — we'll use Flutter overlay
  }
}

class BuyItemOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const BuyItemOverlay({Key? key, required this.onClose}) : super(key: key);

  @override
  State<BuyItemOverlay> createState() => _BuyItemOverlayState();
}

class _BuyItemOverlayState extends State<BuyItemOverlay> {
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
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
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
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'coins': coinCount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item purchased!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough coins!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your Coins: $coinCount', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => buyItem(5),
              child: Text('Buy Sword (5 coins)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => buyItem(10),
              child: Text('Buy Shield (10 coins)'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.onClose,
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
