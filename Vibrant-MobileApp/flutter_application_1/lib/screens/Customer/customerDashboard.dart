import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/custom_colors.dart';
import 'package:http/http.dart' as http;
import '../login.dart';
import 'productDetailScreen.dart';
import 'orders_list_screen.dart';
import 'profile_screen.dart';
import '../../global.dart';
import 'cart_screen.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  final bool _isDarkMode = false;

  List<Widget> get _screens => <Widget>[
        const CustomerDashboardContent(),
        const CartScreen(),
        const OrdersListScreen(),
        const ProfileScreen(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: _screens[_selectedIndex],
      drawer: orientation == Orientation.landscape ? _buildDrawer() : null,
      bottomNavigationBar: orientation == Orientation.portrait
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.brightness == Brightness.light
          ? Colors.white
          : theme.appBarTheme.backgroundColor,
      title: Text("Vibrant",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
          )),
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? CustomColors.primaryColorDark
                  : CustomColors.primaryColorLight,
            ),
            child: Text(
              'Navigation',
              style: TextStyle(
                color: _isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Bag'),
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Orders'),
            onTap: () {
              setState(() {
                _selectedIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              setState(() {
                _selectedIndex = 3;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(elevation: 0),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          label: 'Bag',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      currentIndex: _selectedIndex,
      unselectedItemColor:
          theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey,
      selectedItemColor: theme.brightness == Brightness.dark
          ? Colors.white
          : CustomColors.primaryColorDark,
      onTap: _onItemTapped,
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
  }
}

class CustomerDashboardContent extends StatefulWidget {
  const CustomerDashboardContent({super.key});

  @override
  _CustomerDashboardContentState createState() =>
      _CustomerDashboardContentState();
}

class _CustomerDashboardContentState extends State<CustomerDashboardContent> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  List<dynamic> promotionalProducts = [];
  bool isLoading = true;
  String searchQuery = "";
  final PageController _pageController = PageController();
  int _currentPromotionIndex = 0;
  Timer? _promotionTimer;
  double _opacity = 1.0; // Opacity for fade effect

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _startPromotionTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _promotionTimer?.cancel();
    super.dispose();
  }

  void _startPromotionTimer() {
    _promotionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Fade out to a higher opacity
      setState(() {
        _opacity = 0.7; // Change this value to adjust the opacity
      });

      // Delay for the fade out
      Future.delayed(const Duration(milliseconds: 500), () {
        // Increment the promotion index
        if (_currentPromotionIndex < promotionalProducts.length - 1) {
          _currentPromotionIndex++;
        } else {
          _currentPromotionIndex = 0;
        }

        // Animate to the next page with sliding effect
        _pageController.animateToPage(
          _currentPromotionIndex,
          duration: const Duration(milliseconds: 1100), // Slower transition
          curve: Curves.easeInOut,
        );

        // Fade in
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _opacity = 1.0; // Fade back to fully visible
          });
        });
      });
    });
  }

  Future<void> fetchProducts() async {
    const String apiUrl = "$API_BASE_URL/products";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body)['data'];
          filteredProducts = products;
          promotionalProducts = products.where((product) {
            return product['promotion_price'] != null &&
                product['promotion_start'] != null &&
                product['promotion_end'] != null;
          }).toList();
          isLoading = false;
        });
      } else {
        _handleError('Failed to load products');
      }
    } catch (error) {
      _handleError(error.toString());
    }
  }

  void _handleError(String message) {
    print(message);
    setState(() {
      isLoading = false;
    });
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredProducts = query.isEmpty
          ? products
          : products.where((product) {
              return product['name']
                  .toLowerCase()
                  .contains(query.toLowerCase());
            }).toList();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      products = [];
      filteredProducts = [];
      promotionalProducts = [];
      isLoading = true;
      searchQuery = ""; // Reset search query
    });
    await fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(), // This ensures pull-to-refresh works
        child: isLoading
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(child: CircularProgressIndicator()),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    const SizedBox(height: 16.0),
                    if (promotionalProducts.isNotEmpty) ...[
                      const Text(
                        'Promotions',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      _buildPromotionSlider(),
                    ],
                    const SizedBox(height: 16.0),
                    const Text(
                      'Products',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    _buildProductGrid(orientation),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Search Products',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onChanged: (query) => updateSearchQuery(query),
    );
  }

  Widget _buildPromotionSlider() {
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _pageController,
        itemCount: promotionalProducts.length,
        onPageChanged: (index) {
          setState(() {
            _currentPromotionIndex = index;
          });
        },
        itemBuilder: (context, index) {
          var product = promotionalProducts[index];
          return AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(
                milliseconds: 500), // Duration of the fade effect
            child: _buildPromotionCard(product),
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product['id'],
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 4,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  "http://192.168.8.78:8000${product['image']}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rs ${product['item_price']?.toString() ?? '0.00'}",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[300],
                        ),
                      ),
                      Text(
                        "Promo: Rs ${product['promotion_price']?.toString() ?? '0.00'}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(Orientation orientation) {
    return filteredProducts.isEmpty
        ? const Center(child: Text('No products found.'))
        : GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              var product = filteredProducts[index];
              return _buildProductCard(product);
            },
          );
  }

  Widget _buildProductCard(dynamic product) {
    double originalPrice = double.parse(product['item_price'].toString());
    double? promoPrice = product['promotion_price'] != null
        ? double.parse(product['promotion_price'].toString())
        : null;
    bool hasValidPromo =
        promoPrice != null && promoPrice > 0 && promoPrice < originalPrice;
    double displayPrice = hasValidPromo ? promoPrice : originalPrice;
    bool isOutOfStock = product['quantity'] <= 0;

    double discountPercent = hasValidPromo
        ? ((originalPrice - promoPrice) / originalPrice * 100)
        : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product['id'],
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(4.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                "http://192.168.8.78:8000${product['image']}",
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image));
                },
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            if (isOutOfStock)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const Text(
                    "SOLD OUT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            if (discountPercent > 0)
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Text(
                    "${discountPercent.toStringAsFixed(0)}% OFF",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 16.0,
              left: 8.0,
              right: 8.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Rs ${displayPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: isOutOfStock ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            decoration: isOutOfStock
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasValidPromo)
                        Flexible(
                          child: Text(
                            "Rs ${originalPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.grey[300],
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.0),
                      SizedBox(width: 4.0),
                      Text(
                        "5.0",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
