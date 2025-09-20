import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fit_farm/Model/ExerciseDataModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'DetectionScreen.dart';

class ExerciseScheduleScreen extends StatefulWidget {
  final List<ExerciseDataModel> allExercises;
  final String userId; // For Firestore path

  const ExerciseScheduleScreen({
    super.key,
    required this.allExercises,
    required this.userId,
  });

  @override
  State<ExerciseScheduleScreen> createState() => _ExerciseScheduleScreenState();
}

class _ExerciseScheduleScreenState extends State<ExerciseScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ExerciseStep>> schedule = {};

  List<ExerciseStep> _getForDay(DateTime day) {
    return schedule[DateUtils.dateOnly(day)] ?? [];
  }

  // 🔹 Firestore refs
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final snap = await _db
        .collection("users")
        .doc(widget.userId)
        .collection("schedule")
        .get();

    final data = <DateTime, List<ExerciseStep>>{};
    for (var doc in snap.docs) {
      final date = DateTime.parse(doc.id); // store date as ISO string
      final steps = (doc["steps"] as List)
          .map((e) => ExerciseStep.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      data[date] = steps;
    }

    setState(() => schedule = data);
  }

  Future<void> _saveForDay(DateTime day, List<ExerciseStep> steps) async {
    final key = DateUtils.dateOnly(day);
    schedule[key] = steps;
    setState(() {});

    await _db
        .collection("users")
        .doc(widget.userId)
        .collection("schedule")
        .doc(key.toIso8601String())
        .set({
      "steps": steps.map((e) => e.toJson()).toList(),
    });
  }

  Future<ExerciseStep?> _chooseExerciseStep(ExerciseDataModel ex) async {
    final controller = TextEditingController(text: "10");
    return await showDialog<ExerciseStep>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add ${ex.title}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Target Reps"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final reps = int.tryParse(controller.text) ?? 10;
              Navigator.pop(
                context,
                ExerciseStep(
                  type: ex.type,
                  targetReps: reps,
                  title: ex.title,
                  image: ex.image,
                  color: ex.color,
                ),
              );
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ExerciseStep> todaysSteps =
    _selectedDay != null ? _getForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(title: const Text("My Exercise Schedule")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              });
            },
          ),
          Expanded(
            child: ListView(
              children: [
                for (var step in todaysSteps)
                  ListTile(
                    leading: Image.asset("assets/fitness/${step.image}"),
                    title: Text(step.title),
                    subtitle: Text("${step.targetReps} reps"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        final List<ExerciseStep> newSteps = List<ExerciseStep>.from(todaysSteps)
                          ..remove(step);
                        _saveForDay(_selectedDay!, newSteps);
                      },
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Exercise"),
                  onPressed: () async {
                    final ex = await showModalBottomSheet<ExerciseDataModel>(
                      context: context,
                      builder: (_) => ListView(
                        children: widget.allExercises
                            .map((ex) => ListTile(
                          leading: Image.asset("assets/fitness/${ex.image}"),
                          title: Text(ex.title),
                          onTap: () => Navigator.pop(context, ex),
                        ))
                            .toList(),
                      ),
                    );

                    if (ex != null && _selectedDay != null) {
                      final step = await _chooseExerciseStep(ex);
                      if (step != null) {
                        final List<ExerciseStep> newSteps = List<ExerciseStep>.from(todaysSteps)
                          ..add(step);

                        for (var s in newSteps) {
                          print("➡️ Added step: ${s.title} (${s.targetReps} reps)");
                        }

                        _saveForDay(_selectedDay!, newSteps);
                      }
                    }
                  },
                ),
                if (todaysSteps.isNotEmpty)
                  ElevatedButton(
                    child: const Text("Start Workout"),
                    onPressed: () {
                      final seq = WorkoutSequence(
                        name: "Custom Workout",
                        steps: todaysSteps,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetectionScreen(
                            sequence: seq,
                            onEarnCoin: () {}, // your coin logic
                          ),
                        ),
                      );
                    },
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
