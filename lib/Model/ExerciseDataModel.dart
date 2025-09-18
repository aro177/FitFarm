import 'dart:ui';

enum ExerciseType {
  PushUps,
  Squat,
  DownwardDogPlank,
  JumpingJack,
  SitUp,
  LegRaises,
  AlternateLegDrops,
  GluteBridge,
  Lunges,
  PlankLegRaise,
  StandingSideLegKicks,
  Side_lyingLegRaise,
  StandingKickHand,
  PulseSquats,
}

class ExerciseStep {
  final ExerciseType type;
  final int targetReps;
  final String title; // optional display
  final String image; // optional display (asset path name in your style)
  final Color color; // optional bar color

  const ExerciseStep({
    required this.type,
    required this.targetReps,
    this.title = '',
    this.image = '',
    this.color = const Color(0xFF222222),
  });
}

class WorkoutSequence {
  final String name;
  final List<ExerciseStep> steps;

  const WorkoutSequence({required this.name, required this.steps});
}
