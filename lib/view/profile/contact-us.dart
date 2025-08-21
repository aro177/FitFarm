import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/colo_extension.dart';

class ContactUsView extends StatelessWidget {
  const ContactUsView({super.key});

  void _showEmailPopup(BuildContext context) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: TColor.primaryColor1.withOpacity(0.1),
                      child: Icon(Icons.email, color: TColor.primaryColor1),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Send us an Email",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TColor.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Subject input
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: "Subject",
                    prefixIcon: const Icon(Icons.title_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Message input
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Message",
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.message_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'support@fitfarm.com',
                          query:
                              'subject=${Uri.encodeComponent(subjectController.text)}&body=${Uri.encodeComponent(bodyController.text)}',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primaryColor1,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text("Send"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Contact Us",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.black),
      ),
      backgroundColor: TColor.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "We’d love to hear from you!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TColor.black,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  "support@fitfarm.com",
                  style: TextStyle(fontSize: 14, color: TColor.gray),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  "+84 123 456 789",
                  style: TextStyle(fontSize: 14, color: TColor.gray),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "123 Đường ABC, Quận 1, TP. Hồ Chí Minh, Việt Nam",
                    style: TextStyle(fontSize: 14, color: TColor.gray),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showEmailPopup(context);
                },
                icon: const Icon(Icons.email),
                label: const Text("Send us an Email"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
