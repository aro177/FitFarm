import 'package:fit_farm/ExerciseListingScreen.dart';
import 'package:fit_farm/common_widget/round_button.dart';
import 'package:fit_farm/view/workout_tracker/workout_tracker_view.dart';
import 'package:flutter/material.dart';

class SelectView extends StatelessWidget {
  const SelectView({super.key});

  @override
  Widget build(BuildContext context) {
    // var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoundButton(
                title: "Exercise Listing",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExerciseListingScreen(),
                    ),
                  );
                }),

                const SizedBox(height: 15,),
          ],
        ),
      ),
    );
  }
}
