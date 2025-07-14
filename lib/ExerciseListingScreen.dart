import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fit_farm/DetectionScreen.dart';
import 'package:fit_farm/Model/ExerciseDataModel.dart';

import 'farming_simulation/BuyItemScene.dart';

class ExerciseListingScreen extends StatefulWidget {
  const ExerciseListingScreen({super.key});

  @override
  State<ExerciseListingScreen> createState() => _ExerciseListingScreenState();
}

class _ExerciseListingScreenState extends State<ExerciseListingScreen> {
  List<ExerciseDataModel> exerciseList = [];

  loadData() {
    exerciseList.add(
      ExerciseDataModel(
        "Push Ups",
        "pushup.gif",
        Color(0xff005F9C),
        ExerciseType.PushUps,
      ),
    );
    exerciseList.add(
      ExerciseDataModel(
        "Squats",
        "squat.gif",
        Color(0xffDF5089),
        ExerciseType.Squat,
      ),
    );
    exerciseList.add(
      ExerciseDataModel(
        "Plank to Downward Dog",
        "plank.gif",
        Color(0xffFD8636),
        ExerciseType.DownwardDogPlank,
      ),
    );
    exerciseList.add(
      ExerciseDataModel(
        "Jumping Jack",
        "jumping.gif",
        Color(0xff000000),
        ExerciseType.JumpingJack,
      ),
    );
    setState(() {
      exerciseList;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadData();
    initUserAndCoins();
  }

  int coinCount = 0;
  User? user;

  void initUserAndCoins() async {
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

  @override
  Widget build(BuildContext context) {

    void earnCoin() async {
      setState(() {
        coinCount++;
      });

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'coins': coinCount,
        }, SetOptions(merge: true)); // merge so other fields stay
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Fitness Apps')),
      body: Stack(
        children: [
          // Main Column content
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: exerciseList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetectionScreen(
                              exerciseDataModel: exerciseList[index],
                              onEarnCoin: earnCoin,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: exerciseList[index].color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 150,
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                exerciseList[index].title,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Image.asset(
                                'assets/${exerciseList[index].image}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameWidget(
                          game: BuyItemGame(),
                          overlayBuilderMap: {
                            'BuyOverlay': (context, game) => BuyItemOverlay(
                              onClose: () {
                                (game as BuyItemGame).overlays.remove('BuyOverlay');
                                Navigator.pop(context);
                              },
                            ),
                          },
                          initialActiveOverlays: const ['BuyOverlay'],
                        ),
                      ),
                    );

                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Farming Simulation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Top-right coin counter (valid only inside Stack)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$coinCount',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 6),
                  Image.asset(
                    'assets/coin.png',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
