import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Import provider
import '../../custom_colors.dart';
import '../../theme_provider.dart'; // Ensure this imports the correct ThemeProvider
import 'order_details_screen.dart';
import '../../global.dart';

class OrdersListScreen extends StatefulWidget {
  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  // Function to fetch the user's orders
  Future<void> fetchOrders() async {
    final String apiUrl = "${API_BASE_URL}/orders/byuser/$globalUserId";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body).reversed.toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print(error);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkTheme = themeProvider.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Orders',
          style: TextStyle(
            color: isDarkTheme ? CustomColors.cardColorLight : CustomColors.textColorLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDarkTheme ? CustomColors.primaryColorDark : CustomColors.primaryColor,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text("You have no orders", style: TextStyle(fontSize: 18)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index];
            return _buildOrderCard(order, isDarkTheme);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, bool isDarkTheme) { // Pass isDarkTheme as a parameter
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order ID: ${order['id']}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(Icons.shopping_cart, color: Colors.grey),
              ],
            ),
            SizedBox(height: 10),
            Divider(thickness: 2, color: Colors.grey[300]),
            SizedBox(height: 10),
            Text("${order['product']['name']}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Qty: ${order['product_qty']}", style: TextStyle(fontSize: 16)),
            Text("Status: ${order['order_status']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              "Total: \Rs ${order['order_price']}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkTheme ? CustomColors.cardColorDark : CustomColors.textColorDark, // Set button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailsScreen(
                      orderId: order['id'],
                    ),
                  ),
                );
              },
              child: Text(
                "View Details",
                style: TextStyle(
                  color: isDarkTheme ? CustomColors.textColorDark : CustomColors.textColorLight, // Set text color
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
