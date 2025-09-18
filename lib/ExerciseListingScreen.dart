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
  int coinCount = 0;
  User? user;

  @override
  void initState() {
    super.initState();
    initUserAndCoins();
  }

  Future<void> initUserAndCoins() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc.data()!.containsKey('coins')) {
        setState(() => coinCount = doc['coins']);
      }
    }
  }

  void earnCoin() async {
    setState(() => coinCount++);
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(
        {'coins': coinCount},
        SetOptions(merge: true),
      );
    }
  }

  // ---------- MIXED WORKOUT ONLY ----------

  WorkoutSequence _quickMix() {
    return const WorkoutSequence(
      name: 'Quick Mix',
      steps: [
        ExerciseStep(
          type: ExerciseType.PushUps,
          targetReps: 5,
          title: 'Push Ups',
          image: 'pushup.gif',
          color: Color(0xff005F9C),
        ),
        ExerciseStep(
          type: ExerciseType.Squat,
          targetReps: 10,
          title: 'Squats',
          image: 'squat.gif',
          color: Color(0xffDF5089),
        ),
        ExerciseStep(
          type: ExerciseType.JumpingJack,
          targetReps: 7,
          title: 'Jumping Jack',
          image: 'jumping.gif',
          color: Color(0xff000000),
        ),
      ],
    );
  }

  // Toàn thân nhanh gọn: cơ bụng + mông + chân
  WorkoutSequence _coreAndLegs() {
    return const WorkoutSequence(
      name: 'Core & Legs',
      steps: [
        ExerciseStep(
          type: ExerciseType.SitUp,
          targetReps: 12,
          title: 'Sit Ups',
          image: 'situp.gif',
          color: Color(0xffFF7043),
        ),
        ExerciseStep(
          type: ExerciseType.GluteBridge,
          targetReps: 15,
          title: 'Glute Bridge',
          image: 'glutebridge.gif',
          color: Color(0xff8E24AA),
        ),
        ExerciseStep(
          type: ExerciseType.LegRaises,
          targetReps: 10,
          title: 'Leg Raises',
          image: 'legraises.gif',
          color: Color(0xff3949AB),
        ),
      ],
    );
  }

// Sức bền + tim mạch
  WorkoutSequence _cardioBlast() {
    return const WorkoutSequence(
      name: 'Cardio Blast',
      steps: [
        ExerciseStep(
          type: ExerciseType.JumpingJack,
          targetReps: 20,
          title: 'Jumping Jack',
          image: 'jumping.gif',
          color: Color(0xff000000),
        ),
        ExerciseStep(
          type: ExerciseType.Lunges,
          targetReps: 12,
          title: 'Lunges',
          image: 'lunges.gif',
          color: Color(0xffC2185B),
        ),
        ExerciseStep(
          type: ExerciseType.PulseSquats,
          targetReps: 15,
          title: 'Pulse Squats',
          image: 'pulsesquat.gif',
          color: Color(0xff00796B),
        ),
      ],
    );
  }

// Plank variations cho core
  WorkoutSequence _plankChallenge() {
    return const WorkoutSequence(
      name: 'Plank Challenge',
      steps: [
        ExerciseStep(
          type: ExerciseType.PlankLegRaise,
          targetReps: 10,
          title: 'Plank Leg Raise',
          image: 'planklegraises.gif',
          color: Color(0xff5D4037),
        ),
        ExerciseStep(
          type: ExerciseType.AlternateLegDrops,
          targetReps: 12,
          title: 'Alternate Leg Drops',
          image: 'alternateLegDrop.gif',
          color: Color(0xffF57C00),
        ),
      ],
    );
  }

  Future<void> _startSequence(WorkoutSequence seq) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetectionScreen(
          sequence: seq,     // <-- only mixed workout path
          onEarnCoin: earnCoin,
        ),
      ),
    );
  }

  Widget _mixCard(BuildContext context, WorkoutSequence seq) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white70),
              const SizedBox(width: 8),
              Text(seq.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total ${seq.steps.fold<int>(0, (s, e) => s + e.targetReps)} reps',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Steps preview
          for (final step in seq.steps) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: step.color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: step.color.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  if (step.image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/fitness/${step.image}',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (step.image.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title.isNotEmpty ? step.title : step.type.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${step.targetReps} reps',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _startSequence(seq),
              child: const Text(
                'Start Workout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Apps')),
      body: Stack(
        children: [
          // CONTENT: Mix-only UI
          ListView(
            children: [
              _mixCard(context, _quickMix()),
              _mixCard(context, _coreAndLegs()),
              _mixCard(context, _cardioBlast()),
              _mixCard(context, _plankChallenge()),

              // Farming Simulation (kept)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    child: const Text(
                      'Farming Simulation',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Coin counter
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$coinCount',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  Image.asset('assets/coin.png', width: 24, height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

