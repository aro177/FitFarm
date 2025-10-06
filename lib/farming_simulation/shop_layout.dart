// lib/farming_simulation/shop_layout.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'farm_game.dart';

class Plant {
  final String id;
  final String name;
  final int price;
  final String image;
  int? owned;

  Plant({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.owned,
  });

  Plant copyWith({int? owned}) {
    return Plant(
      id: id,
      name: name,
      price: price,
      image: image,
      owned: owned ?? this.owned,
    );
  }
}

// ---------------- Shop Button Overlay ----------------
class ShopButtonOverlay extends StatelessWidget {
  final FarmGame game;

  const ShopButtonOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: () {
              game.overlays.add('ShopPopup');
            },
            child: const Icon(Icons.store),
          ),
        ),
      ],
    );
  }
}

// ---------------- Overlay Shop ----------------
class ShopOverlay extends StatefulWidget {
  final FarmGame game;
  final VoidCallback onClose;

  const ShopOverlay({
    Key? key,
    required this.game,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _coins = 1000000;
  User? _user;
  List<String> _inventory = [];
  int _waterCount = 0;
  String? _selectedPlant;
  bool _showConfirmDialog = false;
  String _dialogType = 'buy';

  final List<Map<String, dynamic>> _shopPlants = [
    {
      "id": "apple",
      "name": "Cây táo",
      "price": 5,
      "image": "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_00.png",
      "seed": "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s1/p_tomato_s1_00.png",
    },
    {
      "id": "mango",
      "name": "Cây xoài",
      "price": 10,
      "image": "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s4/p_tomato_s4_00.png",
      "seed": "assets/game/images/resources/plants/Tomato/p_tomato/p_tomato_s1/p_tomato_s1_00.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // ĐỔI THÀNH 3 TAB
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _coins = doc.data()?['coins'] ?? 100000;
          _inventory = List<String>.from(doc.data()?['inventory'] ?? []);
          _waterCount = doc.data()?['water'] ?? 0;
        });
      }
    }
  }

  Future<void> _add100Coins() async {
    setState(() {
      _coins += 100;
    });

    await _updateUserData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('+100 Coins! Tổng: $_coins coins'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _updateUserData() async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'coins': _coins,
        'inventory': _inventory,
        'water': _waterCount,
      });
    }
  }

  // HÀM MUA NƯỚC
  void _handleBuyWater() {
    setState(() {
      _dialogType = 'buyWater';
      _showConfirmDialog = true;
    });
  }

  void _confirmBuyWater() {
    const waterPrice = 5;

    if (_coins >= waterPrice) {
      setState(() {
        _coins -= waterPrice;
        _waterCount += 1;
      });

      _updateUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã mua 1 nước!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không đủ coins!')),
      );
    }

    setState(() {
      _showConfirmDialog = false;
    });
  }

  void _handleBuyPlant(String plantName, int price) {
    setState(() {
      _selectedPlant = plantName;
      _dialogType = 'buy';
      _showConfirmDialog = true;
    });
  }

  void _handlePlantSeed(String plantName) {
    setState(() {
      _selectedPlant = plantName;
      _dialogType = 'plant';
      _showConfirmDialog = true;
    });
  }

  void _confirmBuy() {
    if (_selectedPlant != null) {
      final plant = _shopPlants.firstWhere((p) => p["name"] == _selectedPlant);
      final price = plant["price"] as int;

      if (_coins >= price) {
        setState(() {
          _coins -= price;
          _inventory.add(_selectedPlant!);
        });

        _updateUserData();
        widget.game.selectedTree = _selectedPlant;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã mua $_selectedPlant!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không đủ coins!')),
        );
      }
    }
    setState(() {
      _showConfirmDialog = false;
      _selectedPlant = null;
    });
  }

  void _confirmPlant() {
    if (_selectedPlant != null) {
      setState(() {
        _inventory.remove(_selectedPlant);
      });

      _updateUserData();
      widget.game.selectedTree = _selectedPlant;
    }
    setState(() {
      _showConfirmDialog = false;
      _selectedPlant = null;
    });

    widget.onClose();
  }

  int _getPlantCount(String plantName) {
    return _inventory.where((item) => item == plantName).length;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        Center(
          child: Container(
            width: 350,
            height: 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.eco,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cửa Hàng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: widget.onClose,
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.yellow[300],
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Coins: $_coins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 25,
                              child: ElevatedButton(
                                onPressed: _add100Coins,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.yellow.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      '+100',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // TABS - THÊM TAB NƯỚC
                Container(
                  color: Colors.grey[100],
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.green,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.green,
                    tabs: const [
                      Tab(text: 'Cây'),
                      Tab(text: 'Kho'),
                      Tab(text: 'Nước'), // TAB MỚI
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildShopTab(),      // Tab Cây
                      _buildInventoryTab(), // Tab Kho
                      _buildWaterTab(),     // Tab Nước MỚI
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_showConfirmDialog) _buildConfirmationDialog(),
      ],
    );
  }

  // TAB CÂY - GIỮ NGUYÊN
  Widget _buildShopTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _shopPlants.map((plant) {
        final plantName = plant["name"] as String;
        final price = plant["price"] as int;
        final image = plant["image"] as String;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Giá: $price coins',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: _coins >= price ? () => _handleBuyPlant(plantName, price) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Mua'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // TAB KHO - GIỮ NGUYÊN
  Widget _buildInventoryTab() {
    if (_inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Kho trống',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mua cây từ cửa hàng!',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final uniquePlants = _shopPlants.where((plant) {
      return _inventory.contains(plant["name"]);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: uniquePlants.map((plant) {
        final plantName = plant["name"] as String;
        final count = _getPlantCount(plantName);
        final seed = plant["seed"] as String;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    seed,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plantName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sẵn sàng trồng',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: count > 0 ? () => _handlePlantSeed(plantName) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Trồng'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // TAB NƯỚC MỚI
  Widget _buildWaterTab() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          Icons.water_drop,
          size: 60,
          color: Colors.blue,
        ),
        const SizedBox(height: 10),
        Text(
          'Mua nước để tưới cây',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '5 Coins / 1 Nước',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Nước hiện có: $_waterCount',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _handleBuyWater,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Mua Nước'),
        ),
      ],
    );
  }

  Widget _buildConfirmationDialog() {
    String title = '';
    String message = '';
    VoidCallback? onConfirm;

    if (_dialogType == 'buy') {
      title = 'Xác nhận mua';
      message = 'Mua $_selectedPlant với giá ${_shopPlants.firstWhere((p) => p["name"] == _selectedPlant)["price"]} coins?';
      onConfirm = _confirmBuy;
    } else if (_dialogType == 'plant') {
      title = 'Xác nhận trồng';
      message = 'Trồng $_selectedPlant?';
      onConfirm = _confirmPlant;
    } else if (_dialogType == 'buyWater') {
      title = 'Xác nhận mua';
      message = 'Mua 1 nước với giá 5 coins?';
      onConfirm = _confirmBuyWater;
    }

    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.7),
        ),
        Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showConfirmDialog = false;
                          });
                        },
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}