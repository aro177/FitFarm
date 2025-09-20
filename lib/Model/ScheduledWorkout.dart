import 'ExerciseDataModel.dart';

class ScheduledWorkout {
  final DateTime date;
  final List<WorkoutSequence> sequences;

  ScheduledWorkout({required this.date, required this.sequences});
}