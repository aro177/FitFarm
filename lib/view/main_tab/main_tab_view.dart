import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_farm/common/colo_extension.dart';
import 'package:fit_farm/common_widget/tab_button.dart';
import 'package:fit_farm/view/chatbot/chat-bot.dart';
import 'package:fit_farm/view/main_tab/select_view.dart';
import 'package:flutter/material.dart';

import '../home/home_view.dart';
import '../login/login_view.dart';
import '../photo_progress/photo_progress_view.dart';
import '../profile/profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket(); 
  Widget currentTab = const HomeView();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    await Future.delayed(Duration.zero); // ensures context is available

    final user = FirebaseAuth.instance.currentUser;

    if (user == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  backgroundColor: TColor.white,
  body: PageStorage(bucket: pageBucket, child: currentTab),
  bottomNavigationBar: BottomAppBar(
    child: Container(
      decoration: BoxDecoration(
        color: TColor.white, 
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, -2))
        ]
      ),
      height: kToolbarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TabButton(
              icon: "assets/img/home.png",
              selectIcon: "assets/img/home_select.png",
              isActive: selectTab == 0,
              onTap: () {
                selectTab = 0;
                currentTab = const HomeView();
                if (mounted) setState(() {});
              }),
          TabButton(
              icon: "assets/img/workout.png",
              selectIcon: "assets/img/workout_select.png",
              isActive: selectTab == 1,
              onTap: () {
                selectTab = 1;
                currentTab = const SelectView();
                if (mounted) setState(() {});
              }),
          TabButton(
              icon: "assets/img/shopping-bag.png",
              selectIcon: "assets/img/shopping-bag_select.png",
              isActive: selectTab == 2,
              onTap: () {
                selectTab = 2;
                currentTab = const PhotoProgressView();
                if (mounted) setState(() {});
              }),
          TabButton(
              icon: "assets/img/profile_tab.png",
              selectIcon: "assets/img/profile_tab_select.png",
              isActive: selectTab == 3,
              onTap: () {
                selectTab = 3;
                currentTab = const ProfileView();
                if (mounted) setState(() {});
              }),
          TabButton(
            icon: "assets/img/chat-bot (2).png",
            selectIcon: "assets/img/chat-bot-tab-select.png", 
            isActive: selectTab == 4, 
            onTap: () {
              selectTab = 4;
              currentTab = const ChatBotPage();
              if (mounted) setState(() {});
            }),
        ],
      ),
    ),
  ),
);
  }
}
