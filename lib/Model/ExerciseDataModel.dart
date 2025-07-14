import 'dart:ui';

enum ExerciseType{PushUps, Squat, DownwardDogPlank, JumpingJack}
class ExerciseDataModel {
  String title;
  String image;
  Color color;
  ExerciseType type;

  ExerciseDataModel(this.title, this.image, this.color, this.type);
}