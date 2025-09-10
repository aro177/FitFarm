import 'package:fit_farm/in_app_purchase/in_app_purchase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  bool isPremium = true;
  DateTime? premiumEndDate;

  @override
  void initState() {
    super.initState();
    InAppPurchaseUtils.IAP.initialize(); // fake init IAP
  }

  String getPremiumInfo() {
    if (!isPremium) return "You are not a Premium member yet.";
    if (premiumEndDate == null) return "Premium status unknown.";
    final now = DateTime.now();
    final diff = premiumEndDate!.difference(now).inDays;
    if (diff > 0) {
      return "Premium active • $diff days left\nExpires on ${DateFormat('dd/MM/yyyy').format(premiumEndDate!)}";
    } else {
      return "Your Premium has expired.";
    }
  }

  void activatePremium(int months) {
    final now = DateTime.now();
    setState(() {
      isPremium = true;
      premiumEndDate = now.add(Duration(days: 30 * months));
    });
  }

  @override
  Widget build(BuildContext context) {
    final iap = InAppPurchaseUtils.IAP;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Membership"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          if (!iap.isAvailable.value) {
            return const Center(child: Text("Store not available"));
          }
          if (iap.products.isEmpty) {
            return const Center(child: Text("No Premium products found"));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.workspace_premium,
                  size: 90, color: Colors.amber.shade700),
              const SizedBox(height: 20),
              Text(getPremiumInfo(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 40),

              if (!isPremium) ...[
                const Text("Choose your Premium plan",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...iap.products.map((product) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await iap.buy(product);
                        // Fake activate (sau này thay bằng verify backend)
                        if (product.id == 'premium_1month') {
                          activatePremium(1);
                        } else if (product.id == 'premium_3month') {
                          activatePremium(3);
                        } else if (product.id == 'premium_6month') {
                          activatePremium(6);
                        } else if (product.id == 'premium_12month') {
                          activatePremium(12);
                        }
                      },
                      child: Text(
                          "${product.title} - ${product.price}",
                          style: const TextStyle(fontSize: 16)),
                    ),
                  );
                })
              ] else ...[
                Card(
                  margin: const EdgeInsets.only(top: 30),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Enjoy your Premium benefits!",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(45),
                          ),
                          onPressed: () {
                            setState(() {
                              isPremium = false;
                              premiumEndDate = null;
                            });
                          },
                          child: const Text("Cancel Premium (Test Mode)"),
                        ),
                      ],
                    ),
                  ),
                )
              ]
            ],
          );
        }),
      ),
    );
  }
}
