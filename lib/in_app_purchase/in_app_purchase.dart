// import 'dart:async';
// import 'package:get/get.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';

// class InAppPurchaseUtils extends GetxController {
//   InAppPurchaseUtils._();
//   static final InAppPurchaseUtils instance = InAppPurchaseUtils._();
//   static InAppPurchaseUtils get IAP => instance;

//   final InAppPurchase _iap = InAppPurchase.instance;
//   late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

//   final products = <ProductDetails>[].obs;
//   final isAvailable = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     initialize();
//   }

//   Future<void> initialize() async {
//     final bool available = await _iap.isAvailable();
//     isAvailable.value = available;
//     if (!available) return;

//     const Set<String> _kIds = {
//       'premium_1month',
//       'premium_3month',
//       'premium_6month',
//       'premium_12month'
//     };

//     final ProductDetailsResponse response =
//         await _iap.queryProductDetails(_kIds);

//     if (response.error != null || response.productDetails.isEmpty) return;

//     products.assignAll(response.productDetails);

//     _purchaseSubscription =
//         _iap.purchaseStream.listen(_listenToPurchaseUpdated, onDone: () {
//       _purchaseSubscription.cancel();
//     }, onError: (error) {
//       print("Purchase error: $error");
//     });
//   }

//   void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
//     for (var purchase in purchaseDetailsList) {
//       if (purchase.status == PurchaseStatus.purchased) {
//         // TODO: Verify the purchase with your backend
//         print("✅ Purchased: ${purchase.productID}");
//       } else if (purchase.status == PurchaseStatus.error) {
//         print("❌ Purchase error: ${purchase.error}");
//       }
//     }
//   }

//   Future<void> buy(ProductDetails product) async {
//     final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
//     await _iap.buyNonConsumable(purchaseParam: purchaseParam);
//   }
// }
import 'package:get/get.dart';

/// Fake Product model thay cho ProductDetails
class FakeProduct {
  final String id;
  final String title;
  final String price;

  FakeProduct(this.id, this.title, this.price);
}

class InAppPurchaseUtils extends GetxController {
  InAppPurchaseUtils._();
  static final InAppPurchaseUtils IAP = InAppPurchaseUtils._();

  /// Giả lập trạng thái store luôn khả dụng
  var isAvailable = true.obs;

  /// Giả lập danh sách product
  var products = <FakeProduct>[].obs;

  void initialize() {
    // Fake product list
    products.value = [
      FakeProduct("premium_1month", "Premium - 1 Month", "\$2.99"),
      FakeProduct("premium_3month", "Premium - 3 Months", "\$7.99"),
      FakeProduct("premium_6month", "Premium - 6 Months", "\$14.99"),
      FakeProduct("premium_12month", "Premium - 12 Months", "\$24.99"),
    ];
  }

  Future<void> buy(FakeProduct product) async {
    await Future.delayed(const Duration(seconds: 1));
    print("✅ Fake purchase success: ${product.id}");
  }
}
