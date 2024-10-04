import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login.dart';
import 'productDetailScreen.dart';
import 'orders_list_screen.dart';
import 'profile_screen.dart';
import 'customizations_screen.dart';
import '../../global.dart';
import 'cart_screen.dart';

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class MyColors {
  static const Color primaryColor = Color(0xFF000000); // Custom blue color
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  static List<Widget> _screens = <Widget>[
    CustomerDashboardContent(),
    CartScreen(),
    OrdersListScreen(),
    ProfileScreen(),
    CustomizationsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;

    return MaterialApp(
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: Scaffold(
        appBar: _buildAppBar(context),
        body: _screens[_selectedIndex],
        bottomNavigationBar: orientation == Orientation.portrait
            ? _buildBottomNavigationBar()
            : null,
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Vibrant"),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.brightness_3 : Icons.wb_sunny),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            _logout(context);
          },
        ),
      ],
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(elevation: 0),
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
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_rounded),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.gif_box),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Customizations',
        ),
      ],
      currentIndex: _selectedIndex,
      unselectedItemColor: Colors.grey,
      selectedItemColor: MyColors.primaryColor,
      backgroundColor: Colors.white,
      onTap: _onItemTapped,
    );
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }
}

class CustomerDashboardContent extends StatefulWidget {
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
  PageController _pageController = PageController();
  int _currentPromotionIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    final String apiUrl = "${API_BASE_URL}/products";
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

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: 16.0),
            if (promotionalProducts.isNotEmpty) _buildPromotionSlider(),
            SizedBox(height: 16.0),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildProductGrid(orientation),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Search Products',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onChanged: (query) => updateSearchQuery(query),
    );
  }

  Widget _buildPromotionSlider() {
    return Container(
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
          return _buildPromotionCard(product);
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
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 4,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  "http://10.0.2.2:8000${product['image']}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Icon(Icons.broken_image));
                  },
                ),
              ),
            ),
            // Gradient for readability
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
            // Text content overlay
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${product['item_price']?.toString() ?? '0.00'}",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[300],
                        ),
                      ),
                      Text(
                        "Promo: \$${product['promotion_price']?.toString() ?? '0.00'}",
                        style: TextStyle(
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
        ? Center(child: Text('No products found.'))
        : GridView.builder(
      physics: NeverScrollableScrollPhysics(),
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
    // Parse the original and promotional prices
    double? originalPrice = double.tryParse(product['item_price'].toString());
    double? promoPrice = double.tryParse(product['promotion_price']?.toString() ?? '0');

    // Calculate the discount percentage only if a valid promotion is present
    double? discountPercent = originalPrice != null && promoPrice != null && promoPrice < originalPrice
        ? ((originalPrice - promoPrice) / originalPrice * 100).roundToDouble()
        : null;

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
        margin: EdgeInsets.all(4.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            // Product Image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.network(
                "http://10.0.2.2:8000${product['image']}",
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.broken_image));
                },
              ),
            ),
            // Dark Gradient Overlay for text readability
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
            // Text Content over the Image
            Positioned(
              bottom: 16.0,
              left: 8.0,
              right: 8.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.0),
                  // Product Price and Promotion Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Show promo price if it exists, otherwise show original price only
                      if (promoPrice != null && promoPrice < originalPrice!)
                        Text(
                          "\$${promoPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        )
                      else
                        Text(
                          "\$${originalPrice?.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      // Show original price only if promo price exists and is lower
                      if (promoPrice != null )
                        Text(
                          "\$${originalPrice?.toStringAsFixed(2)}",
                          style: TextStyle(
                            color: Colors.grey[300],
                            decoration: TextDecoration.lineThrough,
                            fontSize: 14.0,
                          ),
                        ),
                    ],
                  ),
                  // Product Rating
                  Row(
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
            // Discount Badge in the Top Left Corner
            if (discountPercent != null)
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Text(
                    "${discountPercent.toStringAsFixed(0)}% OFF",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
