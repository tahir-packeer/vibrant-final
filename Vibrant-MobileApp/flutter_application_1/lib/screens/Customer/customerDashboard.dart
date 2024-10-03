import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login.dart';
import 'OrderFormScreen.dart';
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
  static const Color primaryColor = Color(0xFF1976D2); // Custom blue color
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  static List<Widget> _screens = <Widget>[
    CustomerDashboardContent(),
    OrdersListScreen(),
    ProfileScreen(),
    CustomizationsScreen(),
    CartScreen(), // Adding CartScreen to the screens list
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
      title: Text("Customer Dashboard"),
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
          icon: Icon(Icons.shopping_bag),
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
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
      ],
      currentIndex: _selectedIndex,
      unselectedItemColor: Colors.grey,
      selectedItemColor: MyColors.primaryColor,
      backgroundColor: Colors.white,
      elevation: 5,
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
  _CustomerDashboardContentState createState() => _CustomerDashboardContentState();
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
        return product['name'].toLowerCase().contains(query.toLowerCase());
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                "http://10.0.2.2:8000${product['image']}",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.broken_image));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Promo: \$${product['promotion_price']?.toString() ?? '0.00'}",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text("Was: \$${product['item_price']?.toString() ?? '0.00'}"),
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
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        var product = filteredProducts[index];
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
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Image.network(
                    "http://10.0.2.2:8000${product['image']}",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Icon(Icons.broken_image));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product['name'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("Price: \$${product['item_price']}"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
