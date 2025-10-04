import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fit_farm/Model/ExerciseDataModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:velocity_x/velocity_x.dart';

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

Color _cardBg(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return cs.surface.withOpacity(0.9);
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

  Future<ExerciseDataModel?> _showExercisePicker(BuildContext context) {
    return showModalBottomSheet<ExerciseDataModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text("Choose an exercise").text.semiBold.xl.make(),
                ),
                8.heightBox,
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: widget.allExercises.length,
                    separatorBuilder: (_, __) => 8.heightBox,
                    itemBuilder: (_, i) {
                      final ex = widget.allExercises[i];
                      return _ExercisePickTile(
                        title: ex.title,
                        imagePath: "assets/fitness/${ex.image}",
                        onTap: () => Navigator.pop(ctx, ex),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ExerciseStep> todaysSteps =
    _selectedDay != null ? _getForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Exercise Schedule"),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ex = await _showExercisePicker(context);
          if (ex != null && _selectedDay != null) {
            final step = await _chooseExerciseStep(ex);
            if (step != null) {
              final List<ExerciseStep> newSteps = List<ExerciseStep>.from(todaysSteps)..add(step);
              for (var s in newSteps) {
                // debug log
                // ignore: avoid_print
                print("➡️ Added step: ${s.title} (${s.targetReps} reps)");
              }
              _saveForDay(_selectedDay!, newSteps);
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Exercise"),
      ),
      bottomNavigationBar: todaysSteps.isNotEmpty
          ? SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
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
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Start Workout"),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            12.heightBox,
            // Calendar in a modern card
            VxBox(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar(
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
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                ),
              ),
            )
                .roundedLg
                .color(_cardBg(context))
                .shadowXs
                .make()
                .px16(),
            8.heightBox,
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: HStack([
                const Text("Today's Exercises").text.semiBold.make().expand(),
                if (todaysSteps.isNotEmpty)
                  FilledButton.tonal(
                    onPressed: () async {
                      final ex = await _showExercisePicker(context);
                      if (ex != null && _selectedDay != null) {
                        final step = await _chooseExerciseStep(ex);
                        if (step != null) {
                          final List<ExerciseStep> newSteps = List<ExerciseStep>.from(todaysSteps)..add(step);
                          _saveForDay(_selectedDay!, newSteps);
                        }
                      }
                    },
                    child: const Text("Add"),
                  ),
              ]),
            ),
            8.heightBox,
            // List / Empty state
            Expanded(
              child: todaysSteps.isEmpty
                  ? _EmptyStateCard(
                title: "No exercises yet",
                subtitle: "Pick some moves for your day.\nTap the + button to start.",
                icon: Icons.fitness_center_rounded,
              ).px16()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: todaysSteps.length,
                separatorBuilder: (_, __) => 8.heightBox,
                itemBuilder: (context, i) {
                  final step = todaysSteps[i];
                  return _ExerciseTileModern(
                    step: step,
                    onDelete: () {
                      final List<ExerciseStep> newSteps = List<ExerciseStep>.from(todaysSteps)..remove(step);
                      _saveForDay(_selectedDay!, newSteps);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ExerciseTileModern extends StatelessWidget {
  final ExerciseStep step;
  final VoidCallback onDelete;

  const _ExerciseTileModern({
    required this.step,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return VxBox(
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/fitness/${step.image}",
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          12.widthBox,
          // Title + reps
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                step.title.text.semiBold.make(),
                4.heightBox,
                "Target: ${step.targetReps} reps"
                    .text
                    .sm
                    .color(cs.onSurfaceVariant)
                    .make(),
              ],
            ),
          ),
          // Delete (tonal)
          IconButton.filledTonal(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
          ),
        ],
      ),
    )
        .p12
        .roundedLg
        .color(Theme.of(context).cardColor)
        .shadowXs
        .make();
  }
}

class _ExercisePickTile extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _ExercisePickTile({
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: VxBox(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(imagePath, width: 52, height: 52, fit: BoxFit.cover),
            ),
            12.widthBox,
            title.text.semiBold.make().expand(),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ).p12.roundedLg.color(Theme.of(context).cardColor).shadowXs.make(),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return VxBox(
      child: VStack([
        8.heightBox,
        Icon(icon, size: 40, color: cs.primary),
        12.heightBox,
        title.text.semiBold.lg.make(),
        6.heightBox,
        subtitle.text.center.color(cs.onSurfaceVariant).make(),
        8.heightBox,
      ], crossAlignment: CrossAxisAlignment.center),
    ).p16.roundedLg.color(_cardBg(context)).alignCenter.make();
  }
}

