import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import 'comparison_view.dart';

class PhotoProgressView extends StatefulWidget {
  const PhotoProgressView({super.key});

  @override
  State<PhotoProgressView> createState() => _PhotoProgressViewState();
}

class _PhotoProgressViewState extends State<PhotoProgressView> {
  // Chỉ sử dụng 8 sản phẩm từ các link được cung cấp
  List productArr = [
    {
      "category": "Fitness Equipment",
      "products": [
        {
          "name": "Premium Yoga Mat",
          "image": "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/70AdW0YRBw"
        },
        {
          "name": "Professional Dumbbell Set",
          "image": "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/3Axux0463z"
        },
        {
          "name": "Resistance Bands Pack",
          "image": "https://images.unsplash.com/photo-1598974357801-cbca100e65d3?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/8zvhtkkvoq"
        },
        {
          "name": "Speed Jump Rope",
          "image": "https://images.unsplash.com/photo-1594736797933-d0401ba2fe65?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/7pjkVcy2l2"
        },
      ]
    },
    {
      "category": "Fitness Accessories",
      "products": [
        {
          "name": "Exercise Ball",
          "image": "https://images.unsplash.com/photo-1534258936925-c58bed479fcb?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/2ViE9shwiH"
        },
        {
          "name": "Foam Roller",
          "image": "https://images.unsplash.com/photo-1574680178050-55c6a6a96e0a?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/8zvhtriAle"
        },
      ]
    },
    {
      "category": "Nutrition Supplements",
      "products": [
        {
          "name": "Whey Protein",
          "image": "https://images.unsplash.com/photo-1597074866923-dc0589150358?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/5pyg84cIoT"
        },
        {
          "name": "Pre-workout Booster",
          "image": "https://images.unsplash.com/photo-1599058917765-a780eda07a3e?w=400&h=400&fit=crop",
          "shopee_link": "https://s.shopee.vn/2LOnxf29AP"
        },
      ]
    }
  ];

  // Function to open Shopee link
  Future<void> _launchShopeeUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Fitness Store",
          style: TextStyle(
              color: TColor.black, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: TColor.black, size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none, color: TColor.black, size: 24),
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với banner đẹp
            Container(
              width: media.width,
              height: media.width * 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TColor.primaryColor1.withOpacity(0.8),
                    TColor.primaryColor2.withOpacity(0.8)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    bottom: -30,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.fitness_center, size: 150, color: TColor.white),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "FITNESS STORE",
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Premium equipment for your journey",
                          style: TextStyle(
                            color: TColor.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: 140,
                          height: 40,
                          child: RoundButton(
                            title: "Shop Now",
                            onPressed: () {
                              _launchShopeeUrl("https://s.shopee.vn/70AdW0YRBw");
                            },
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Danh mục sản phẩm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Shop by Category",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Grid danh mục
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryItem("Equipment", Icons.fitness_center, TColor.primaryColor1),
                  _buildCategoryItem("Accessories", Icons.sports_handball, TColor.secondaryColor1),
                  _buildCategoryItem("Nutrition", Icons.local_drink, TColor.primaryColor2),
                ],
              ),
            ),

            SizedBox(height: 25),

            // Sản phẩm nổi bật
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Featured Products",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                   
                ],
              ),
            ),

            // Danh sách sản phẩm
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: productArr.length,
              itemBuilder: ((context, index) {
                var pObj = productArr[index] as Map? ?? {};
                var productsArr = pObj["products"] as List? ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        pObj["category"].toString(),
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: productsArr.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: ((context, indexRow) {
                          var product = productsArr[indexRow] as Map? ?? {};
                          return InkWell(
                            onTap: () {
                              _launchShopeeUrl(product["shopee_link"] as String? ?? "");
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 120,
                              decoration: BoxDecoration(
                                color: TColor.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hình ảnh sản phẩm
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: TColor.lightGray,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        product["image"] as String? ?? "",
                                        width: 120,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (BuildContext context, Widget child,
                                            ImageChunkEvent? loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              color: TColor.primaryColor1,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: TColor.lightGray,
                                            child: Icon(Icons.error, color: TColor.gray),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  // Tên sản phẩm
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(
                                      product["name"] as String? ?? "",
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      
       
    );
  }

  // Widget xây dựng danh mục
  Widget _buildCategoryItem(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: TColor.black,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}