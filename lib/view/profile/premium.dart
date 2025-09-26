import 'package:fit_farm/view/profile/qr_payment.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
            
        if (doc.exists) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Membership"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final isPremium = userData?['isPremium'] == true;
    final premiumExpiry = userData?['premiumExpiry'] as Timestamp?;
    final premiumActivated = userData?['premiumActivated'] as Timestamp?;

    if (isPremium && premiumExpiry != null) {
      // Người dùng đã có premium - hiển thị thông tin
      final expiryDate = premiumExpiry.toDate();
      final activatedDate = premiumActivated?.toDate();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.verified_user,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            "You are a Premium Member!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Membership Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow("Status", "Active", Icons.check_circle, Colors.green),
                  if (activatedDate != null)
                    _buildDetailRow("Activated on", _formatDate(activatedDate), Icons.calendar_today, Colors.blue),
                  _buildDetailRow("Expires on", _formatDate(expiryDate), Icons.event_available, Colors.orange),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Thank you for being a premium member. Enjoy all the exclusive features!",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Thêm nút quay về ProfileView
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Back to Profile"),
          ),
        ],
      );
    } else {
      // Người dùng chưa có premium - hiển thị các gói để mua
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Upgrade to Premium",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Choose a package that suits your needs:",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRPaymentPage(
                    premiumDays: 7,
                    amount: 50000,
                  ),
                ),
              );
            },
            child: const Text("7 Days Package - 50,000 VND"),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRPaymentPage(
                    premiumDays: 30,
                    amount: 150000,
                  ),
                ),
              );
            },
            child: const Text("30 Days Package - 150,000 VND"),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QRPaymentPage(
                    premiumDays: 90,
                    amount: 400000,
                  ),
                ),
              );
            },
            child: const Text("90 Days Package - 400,000 VND"),
          ),
          const SizedBox(height: 24),
          const Text(
            "Premium features include:\n• Advanced analytics\n• Exclusive workouts\n• Personalized coaching\n• Ad-free experience",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Thêm nút quay về ProfileView
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Back to Profile"),
          ),
        ],
      );
    }
  }

  Widget _buildDetailRow(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}