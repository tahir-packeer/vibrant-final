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

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  bool _isDarkMode = false; // Track if dark mode is enabled

  static List<Widget> _screens = <Widget>[
    CustomerDashboardContent(),
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: Scaffold(
        appBar: AppBar(
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
        ),
        body: Stack(
          children: [
            _screens[_selectedIndex],
            Positioned(
              right: 16.0,
              bottom: 16.0,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
                child: Icon(Icons.shopping_cart),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
        bottomNavigationBar: orientation == Orientation.portrait
            ? BottomNavigationBar(
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
          ],
          currentIndex: _selectedIndex,
          unselectedItemColor: Colors.orange,
          selectedItemColor: Colors.blueAccent,
          backgroundColor: Colors.orange,
          onTap: _onItemTapped,
        )
            : null,
      ),
    );
  }
}

void _logout(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
  );
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

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final String apiUrl = "${API_BASE_URL}/products";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body)['data'];
          filteredProducts = products;

          // Filter promotional products
          promotionalProducts = products.where((product) {
            return product['promotion_price'] != null &&
                product['promotion_start'] != null &&
                product['promotion_end'] != null;
          }).toList();

          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
      print(error);
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          return product['name']
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Products',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (query) => updateSearchQuery(query),
          ),
        ),

        // Section for Promotional Products
        if (promotionalProducts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promotions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 230, // Set a fixed height for the promotional list
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // Horizontal scroll for promotions
                    itemCount: promotionalProducts.length,
                    itemBuilder: (context, index) {
                      var product = promotionalProducts[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Image.network(
                              "http://10.0.2.2:8000${product['image']}",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image);
                              },
                            ),
                            Text(product['name']),
                            Text(
                              "Promo: \$${product['promotion_price']}",
                              style: TextStyle(color: Colors.red),
                            ),
                            Text("Was: \$${product['item_price']}"),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      productId: product['id'],
                                    ),
                                  ),
                                );
                              },
                              child: Text('View'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

        // Normal product grid
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredProducts.isEmpty
              ? Center(child: Text('No products found.'))
              : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: orientation == Orientation.portrait ? 1 : 2,
              childAspectRatio: 3,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              var product = filteredProducts[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: Image.network(
                    "http://10.0.2.2:8000${product['image']}",
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image);
                    },
                  ),
                  title: Text(product['name']),
                  subtitle: Text("\$${product['item_price']}"),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Cart Screen (Same code as your existing one)
class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double cartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final String apiUrl = "${API_BASE_URL}/cart/user/$globalUserId"; // Replace with dynamic user ID if needed
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          cartItems = json.decode(response.body)['cartItems'];
          cartTotal = calculateCartTotal();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (error) {
      print(error);
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculateCartTotal() {
    double total = 0.0;
    for (var item in cartItems) {
      total += item['total_price'];
    }
    return total;
  }

  Future<void> deleteCartItem(int cartId) async {
    final String apiUrl = "${API_BASE_URL}/cart/item/$cartId";
    try {
      final response = await http.delete(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          cartItems.removeWhere((item) => item['id'] == cartId);
          cartTotal = calculateCartTotal();
        });
      } else {
        throw Exception('Failed to delete cart item');
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> updateCartQuantity(int cartId, int qty) async {
    final String apiUrl = "${API_BASE_URL}/cart/item/$cartId";
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"product_qty": qty}),
      );
      if (response.statusCode == 200) {
        setState(() {
          var updatedItem = json.decode(response.body)['cartItem'];
          int index = cartItems.indexWhere((item) => item['id'] == cartId);
          if (index != -1) {
            cartItems[index] = updatedItem;
            cartTotal = calculateCartTotal();
          }
        });
      } else {
        throw Exception('Failed to update cart quantity');
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> placeOrder() async {
    print("Order placed!");
  }

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(child: Text('Your Cart is empty'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var cartItem = cartItems[index];
                return Card(
                  child: ListTile(
                    leading: Image.network(
                      "http://10.0.2.2:8000${cartItem['product_image']}",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image);
                      },
                    ),
                    title: Text(cartItem['product_name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Price: \$${cartItem['item_price']}"),
                        Row(
                          children: [
                            Text("Qty: "),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                if (cartItem['product_qty'] > 1) {
                                  updateCartQuantity(
                                      cartItem['id'],
                                      cartItem['product_qty'] - 1);
                                }
                              },
                            ),
                            Text('${cartItem['product_qty']}'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                updateCartQuantity(
                                    cartItem['id'],
                                    cartItem['product_qty'] + 1);
                              },
                            ),
                          ],
                        ),
                        Text("Total: \$${cartItem['total_price']}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        deleteCartItem(cartItem['id']);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Total: \$${cartTotal.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    List<Map<String, dynamic>> orderDetails =
                    cartItems.map((item) {
                      return {
                        'product_id': item['product_id'],
                        'product_name': item['product_name'],
                        'product_qty': item['product_qty'],
                      };
                    }).toList();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderFormScreen(
                          orderDetails: orderDetails,
                          cartTotal: cartTotal,
                        ),
                      ),
                    );
                  },
                  child: Text("Place Order"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
