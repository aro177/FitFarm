import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fit_farm/view/profile/premium.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;

class QRPaymentPage extends StatefulWidget {
  final int premiumDays;
  final int amount;

  static const Map<String, String> MY_BANK = {
    "BANK_ID": "MB",
    "ACCOUNT_NUMBER": "6686666866669",
    "ACCOUNT_NAME": "FITFARM",
  };

  const QRPaymentPage({
    super.key,
    required this.premiumDays,
    required this.amount,
  });

  @override
  State<QRPaymentPage> createState() => _QRPaymentPageState();
}

class _QRPaymentPageState extends State<QRPaymentPage> {
  late Future<Map<String, dynamic>> _qrInfoFuture;
  bool _isCheckingPayment = false;
  bool _paymentSuccess = false;
  String _paymentStatus = '';
  Timer? _paymentCheckTimer;

  // Google Apps Script URL
  static const String _googleScriptURL = 
      "https://script.googleusercontent.com/macros/echo?user_content_key=AehSKLh3HT2djVXZeMDAB6cnTfSGmqxqNsOp-kvZmWekTHgBRs-gNmyrjL6x1ESKrmZbybnEQ-EOyt5roYvUxBY2FwrNhPZwdhdo9WL8OttXPwio6IodCs9Rah-ZWJFWE7uL9_ORHRMrWcOUombmz_ZIvfxh3k48Ty1O4ymzkFmuHzXez2cTmKvd4d4-nckEosG_1Q78jD6bSDfRDkNcrghWLqype_CJ1pF1MYPNkcgTv9gkm9zTuLVFvyhx-fzMTFWva04hDCbn5Ge6LuIwTYDtg72ntuVvd7Ucg5utN785&lib=MGBIhgpK6XOzv2as5Gy0Wr_JqafM2Pfzr";

  @override
  void initState() {
    super.initState();
    _qrInfoFuture = _generateQRInfo();
    
    // Start automatic payment checking after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      _startAutomaticPaymentChecking();
    });
  }

  @override
  void dispose() {
    _paymentCheckTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _generateQRInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        throw Exception("User document not found");
      }

      final data = doc.data() as Map<String, dynamic>?;
      final email = data?['email'] ?? "no-email@example.com";
      final description = "Premium ${widget.premiumDays} days - $email";

      final qrLink =
          "https://img.vietqr.io/image/${QRPaymentPage.MY_BANK['BANK_ID']}-${QRPaymentPage.MY_BANK['ACCOUNT_NUMBER']}-qr-only.png"
          "?amount=${widget.amount}"
          "&addInfo=${Uri.encodeComponent(description)}"
          "&accountName=${Uri.encodeComponent(QRPaymentPage.MY_BANK['ACCOUNT_NAME']!)}";

      return {
        'email': email,
        'qrLink': qrLink,
        'description': description,
      };
    } catch (e) {
      final email = FirebaseAuth.instance.currentUser?.email ?? "no-email@example.com";
      final description = "Premium ${widget.premiumDays} days - $email";
      
      final qrLink =
          "https://img.vietqr.io/image/${QRPaymentPage.MY_BANK['BANK_ID']}-${QRPaymentPage.MY_BANK['ACCOUNT_NUMBER']}-compact2.png"
          "?amount=${widget.amount}"
          "&addInfo=${Uri.encodeComponent(description)}"
          "&accountName=${Uri.encodeComponent(QRPaymentPage.MY_BANK['ACCOUNT_NAME']!)}";

      return {
        'email': email,
        'qrLink': qrLink,
        'description': description,
        'error': e.toString(),
      };
    }
  }

  // Hàm helper để loại bỏ ký tự @ và .
  String _sanitizeDescription(String input) {
    return input.replaceAll(RegExp(r'[@.-]'), '');
  }

  // Start automatic payment checking
  void _startAutomaticPaymentChecking() {
    // Check immediately first
    _checkPaymentStatus();

    // Then set up periodic checking every 10 seconds
    _paymentCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_paymentSuccess) {
        _checkPaymentStatus();
      } else {
        timer.cancel(); // Stop checking if payment is successful
      }
    });
  }

  // Function to check payment status from Google Sheets
  Future<void> _checkPaymentStatus() async {
    if (_paymentSuccess || _isCheckingPayment) return;

    setState(() {
      _isCheckingPayment = true;
      _paymentStatus = 'Checking payment status...';
    });

    try {
      final response = await http.get(Uri.parse(_googleScriptURL));
      final cleanEmail = _sanitizeDescription(FirebaseAuth.instance.currentUser?.email ?? "");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lastPaid = data['data'][data['data'].length - 1];
        final lastPrice = lastPaid["Giá trị"];
        final lastContent = lastPaid["Mô tả"];
        
        if (lastPrice >= widget.amount && lastContent.contains(cleanEmail)) {
          setState(() {
            _paymentSuccess = true;
            _paymentStatus = 'Payment successful!';
          });
          
          // Update user premium status in Firestore
          await _updateUserPremiumStatus();
          
          // Stop the timer
          _paymentCheckTimer?.cancel();
          
          // Show success message and navigate to PremiumView
          _showSuccessAndNavigate();
        } else {
          setState(() {
            _paymentStatus = 'Waiting for payment...';
          });
        }
      } else {
        throw Exception('Failed to load payment data');
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error checking payment. Retrying...';
      });
    } finally {
      setState(() {
        _isCheckingPayment = false;
      });
    }
  }

  // Show success message and navigate to PremiumView
  void _showSuccessAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment successful! Premium activated.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to PremiumView after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => PremiumView()),
  (route) => false, // Xóa tất cả các route trước đó
);
    });
  }

  // Update user premium status in Firestore
  Future<void> _updateUserPremiumStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final now = DateTime.now();
        final expiryDate = now.add(Duration(days: widget.premiumDays));
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isPremium': true,
          'premiumExpiry': expiryDate,
          'premiumActivated': now,
        });
      }
    } catch (e) {
      print('Error updating premium status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Payment"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _qrInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading payment information..."),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QRPaymentPage(
                            premiumDays: widget.premiumDays,
                            amount: widget.amount,
                          ),
                        ),
                      );
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final email = data['email'] ?? "No email";
          final qrLink = data['qrLink'] ?? "";
          final description = data['description'] ?? "Premium payment";
          final error = data['error'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (error != null)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 20.0),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Using fallback data due to network issues",
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Payment Status
                  if (_paymentStatus.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.only(bottom: 20.0),
                      decoration: BoxDecoration(
                        color: _paymentSuccess ? Colors.green[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: _paymentSuccess ? Colors.green : Colors.blue,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _paymentSuccess ? Icons.check_circle : Icons.info,
                            color: _paymentSuccess ? Colors.green : Colors.blue,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paymentStatus,
                              style: TextStyle(
                                color: _paymentSuccess ? Colors.green[800] : Colors.blue[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (_isCheckingPayment)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  
                  // Package Information
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "PREMIUM PACKAGE",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${widget.premiumDays} Days",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Email:"),
                            Text(
                              email,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Amount:"),
                            Text(
                              "${widget.amount.toStringAsFixed(0)} VND",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // QR Code Section
                  Text(
                    "Scan QR Code to Pay",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.network(
                          qrLink,
                          width: 280,
                          height: 280,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 280,
                              height: 280,
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Column(
                              children: [
                                const Icon(Icons.error_outline, 
                                    color: Colors.red, size: 50),
                                const SizedBox(height: 12),
                                Text(
                                  "Unable to load QR code",
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QRPaymentPage(
                                          premiumDays: widget.premiumDays,
                                          amount: widget.amount,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Retry"),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Manual payment information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MANUAL TRANSFER INFORMATION",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow("Bank", QRPaymentPage.MY_BANK['BANK_ID']!),
                        _buildInfoRow("Account Number", QRPaymentPage.MY_BANK['ACCOUNT_NUMBER']!),
                        _buildInfoRow("Account Name", QRPaymentPage.MY_BANK['ACCOUNT_NAME']!),
                        _buildInfoRow("Amount", "${widget.amount.toStringAsFixed(0)} VND"),
                        _buildInfoRow("Description", description),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Instructions
                  Text(
                    "Payment status is automatically checked every 10 seconds. "
                    "You will be redirected to premium page once payment is confirmed.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$title:",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}