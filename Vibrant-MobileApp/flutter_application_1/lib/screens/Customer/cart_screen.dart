import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../custom_colors.dart';
import '../../global.dart';
import 'OrderFormScreen.dart';
import '/theme_provider.dart';

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
    final String apiUrl = "${API_BASE_URL}/cart/user/$globalUserId";
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
    return cartItems.fold(0.0, (total, item) => total + item['total_price']);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bag',
          style: TextStyle(color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
        ),
        backgroundColor: isDarkTheme ? CustomColors.primaryColorDark : CustomColors.primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(
        child: Text(
          'Your Cart is empty',
          style: TextStyle(fontSize: 18, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  var cartItem = cartItems[index];
                  return Dismissible(
                    key: Key(cartItem['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      deleteCartItem(cartItem['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${cartItem['product_name']} removed from cart")),
                      );
                    },
                    child: _buildCartItemCard(cartItem, isDarkTheme),
                  );
                },
              ),
            ),
            _buildCartTotal(isDarkTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(dynamic cartItem, bool isDarkTheme) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      color: isDarkTheme ? CustomColors.cardColorDark : CustomColors.cardColorLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "http://10.0.2.2:8000${cartItem['product_image']}",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem['product_name'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Size: ${cartItem['size']}",
                    style: TextStyle(fontSize: 14, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "\$${cartItem['item_price']}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                      ),
                      SizedBox(width: 8),
                      if (cartItem['discount_price'] != null)
                        Text(
                          "\$${cartItem['discount_price']}",
                          style: TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Qty: ",
                        style: TextStyle(fontSize: 14, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                        onPressed: () {
                          if (cartItem['product_qty'] > 1) {
                            updateCartQuantity(cartItem['id'], cartItem['product_qty'] - 1);
                          }
                        },
                      ),
                      Text(
                        '${cartItem['product_qty']}',
                        style: TextStyle(fontSize: 14, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                        onPressed: () {
                          updateCartQuantity(cartItem['id'], cartItem['product_qty'] + 1);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Total: \$${cartItem['total_price']}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                deleteCartItem(cartItem['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartTotal(bool isDarkTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total: \$${cartTotal.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              List<Map<String, dynamic>> orderDetails = cartItems.map((item) {
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
            child: Text("CHECKOUT SECURELY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              backgroundColor: isDarkTheme ? CustomColors.secondaryColorDark : CustomColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(fontSize: 16, color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight),
            ),
          ),
        ],
      ),
    );
  }
}