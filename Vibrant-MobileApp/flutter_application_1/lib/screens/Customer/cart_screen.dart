import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../custom_colors.dart';
import '../../global.dart';
import 'OrderFormScreen.dart';
import '/theme_provider.dart';

// lib/screens/Customer/cart_screen.dart

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> cartItems = [];
  bool isLoading = true;
  double cartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  double calculateCartTotal() {
    double total = 0.0;
    for (var item in cartItems) {
      // Get the individual item price and quantity
      double itemPrice = double.parse(item['item_price'].toString());
      int quantity = item['product_qty'] ?? 1;
      total += (itemPrice * quantity);
    }
    return total;
  }

  Future<void> fetchCartItems() async {
    final String apiUrl = "$API_BASE_URL/cart/user/$globalUserId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          cartItems = data['cartItems'];
          cartTotal = calculateCartTotal();
          isLoading = false;
        });
        // Debug print to check values
        print('Cart Total: $cartTotal');
        print('Cart Items: $cartItems');
      } else {
        throw Exception('Failed to load cart items');
      }
    } catch (error) {
      print('Error fetching cart items: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteCartItem(int cartId) async {
    final String apiUrl = "$API_BASE_URL/cart/item/$cartId";
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
    final String apiUrl = "$API_BASE_URL/cart/item/$cartId";
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.brightness == Brightness.light
            ? Colors.white
            : theme.appBarTheme.backgroundColor,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Bag',
              style: TextStyle(
                color: theme.brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Text(
                    'Your Bag is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.textTheme.bodyMedium?.color ?? Colors.black,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            var cartItem = cartItems[index];
                            return Dismissible(
                              key: Key(cartItem['id'].toString()),
                              direction: DismissDirection.endToStart,
                              background: _buildDismissBackground(),
                              onDismissed: (direction) {
                                deleteCartItem(cartItem['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "${cartItem['product_name']} removed from cart")),
                                );
                              },
                              movementDuration:
                                  const Duration(milliseconds: 500),
                              resizeDuration: const Duration(milliseconds: 300),
                              child: _buildCartItemCard(cartItem, theme),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Amount:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodyMedium?.color ??
                                        Colors.black,
                                  ),
                                ),
                                Text(
                                  "Rs ${cartTotal.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color ??
                                        Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  List<Map<String, dynamic>> orderDetails =
                                      cartItems.map((item) {
                                    return {
                                      'product_id': item['product_id'],
                                      'product_name': item['product_name'],
                                      'product_qty': item['product_qty'],
                                    };
                                  }).toList();

                                  final result =
                                      await Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderFormScreen(
                                        orderDetails: orderDetails,
                                        cartTotal: cartTotal,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    setState(() {
                                      cartItems.clear();
                                      cartTotal = 0.0;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Order placed successfully. Cart cleared!'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  "CHECKOUT",
                                  style: TextStyle(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(40), // Rounded corners
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 10),
          Text('Swipe to delete', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(dynamic cartItem, ThemeData theme) {
    double discount = cartItem['promotion'] ?? 0;
    bool hasDiscount = discount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5), // Rounded edges
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasDiscount) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$discount% OFF",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          cartItem['product_name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color ??
                                Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Size: ${cartItem['size']}",
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color ??
                                Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (hasDiscount)
                              Text(
                                "Rs ${cartItem['original_price']}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            SizedBox(width: hasDiscount ? 8 : 0),
                            Text(
                              "Rs ${cartItem['item_price']}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color ??
                                    Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "Qty: ",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color ??
                                    Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove,
                                  color: theme.textTheme.bodyMedium?.color ??
                                      Colors.black),
                              onPressed: () {
                                if (cartItem['product_qty'] > 1) {
                                  updateCartQuantity(cartItem['id'],
                                      cartItem['product_qty'] - 1);
                                }
                              },
                            ),
                            Text(
                              '${cartItem['product_qty']}',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodyMedium?.color ??
                                      Colors.black),
                            ),
                            IconButton(
                              icon: Icon(Icons.add,
                                  color: theme.textTheme.bodyMedium?.color ??
                                      Colors.black),
                              onPressed: () {
                                updateCartQuantity(cartItem['id'],
                                    cartItem['product_qty'] + 1);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Rs ${cartItem['total_price']}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
