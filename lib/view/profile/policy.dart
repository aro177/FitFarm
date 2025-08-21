import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.black),
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TColor.black,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "We respect your privacy and are committed to protecting your personal data. "
              "This Privacy Policy explains how we collect, use, and safeguard your information "
              "when you use our application.",
              style: TextStyle(fontSize: 14, color: TColor.gray, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "1. Information We Collect",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TColor.black),
            ),
            const SizedBox(height: 8),
            Text(
              "We may collect personal information such as your name, email, phone number, "
              "and app usage data to improve our services.",
              style: TextStyle(fontSize: 14, color: TColor.gray, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "2. How We Use Information",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TColor.black),
            ),
            const SizedBox(height: 8),
            Text(
              "Your information is used to personalize the app experience, "
              "provide support, and notify you of important updates.",
              style: TextStyle(fontSize: 14, color: TColor.gray, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "3. Data Security",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TColor.black),
            ),
            const SizedBox(height: 8),
            Text(
              "We implement strict security measures to keep your data safe "
              "from unauthorized access or disclosure.",
              style: TextStyle(fontSize: 14, color: TColor.gray, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "4. Contact Us",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TColor.black),
            ),
            const SizedBox(height: 8),
            Text(
              "If you have any questions about this Privacy Policy, please contact us at "
              "support@fitfarm.com.",
              style: TextStyle(fontSize: 14, color: TColor.gray, height: 1.5),
            ),
            const SizedBox(height: 30),
            
          ],
        ),
      ),
    );
  }
}
