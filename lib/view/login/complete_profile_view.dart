import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_farm/common/colo_extension.dart';
import 'package:fit_farm/view/login/what_your_goal_view.dart';
import 'package:flutter/material.dart';

import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final TextEditingController txtDate = TextEditingController();
  final TextEditingController txtWeight = TextEditingController();
  final TextEditingController txtHeight = TextEditingController();

  String? selectedGender;

  @override
  void dispose() {
    txtDate.dispose();
    txtWeight.dispose();
    txtHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Image.asset(
                  "assets/img/complete_profile.png",
                  width: media.width,
                  fit: BoxFit.fitWidth,
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Text(
                  "Let’s complete your profile",
                  style: TextStyle(
                      color: TColor.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  "It will help us to know more about you!",
                  style: TextStyle(color: TColor.gray, fontSize: 12),
                ),
                SizedBox(
                  height: media.width * 0.05,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      Container(
                          decoration: BoxDecoration(
                              color: TColor.lightGray,
                              borderRadius: BorderRadius.circular(15)),
                          child: Row(
                            children: [
                              Container(
                                  alignment: Alignment.center,
                                  width: 50,
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(horizontal: 15),
                                  
                                  child: Image.asset(
                                    "assets/img/gender.png",
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    color: TColor.gray,
                                  )),
                            
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton(
                                    items: ["Male", "Female"]
                                        .map((name) => DropdownMenuItem(
                                              value: name,
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                    color: TColor.gray,
                                                    fontSize: 14),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedGender = value;
                                      });
                                    },
                                    value: selectedGender,
                                    isExpanded: true,
                                    hint: Text(
                                      "Choose Gender",
                                      style: TextStyle(
                                          color: TColor.gray, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),

                             const SizedBox(width: 8,)

                            ],
                          ),),
                      SizedBox(
                        height: media.width * 0.04,
                      ),
                      RoundTextField(
                        controller: txtDate,
                        hitText: "Date of Birth",
                        icon: "assets/img/date.png",
                      ),
                      SizedBox(
                        height: media.width * 0.04,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RoundTextField(
                              controller: txtWeight,
                              hitText: "Your Weight",
                              icon: "assets/img/weight.png",
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: TColor.secondaryG,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "KG",
                              style:
                                  TextStyle(color: TColor.white, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.04,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RoundTextField(
                              controller: txtHeight,
                              hitText: "Your Height",
                              icon: "assets/img/hight.png",
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: TColor.secondaryG,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "CM",
                              style:
                                  TextStyle(color: TColor.white, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: media.width * 0.07,
                      ),
                      RoundButton(
                          title: "Next >",
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user != null) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                              'gender': selectedGender ?? '',
                              'dob': txtDate.text.trim(),
                              'weight': txtWeight.text.trim(),
                              'height': txtHeight.text.trim(),
                              'profile_completed_at': Timestamp.now(),
                            });
                          }

                          if (!mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const WhatYourGoalView()),
                          );
                        },),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
