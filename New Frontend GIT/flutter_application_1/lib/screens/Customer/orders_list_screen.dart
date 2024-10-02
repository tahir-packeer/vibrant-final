import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'order_details_screen.dart'; // Import the order details screen
import '../../global.dart'; // Import global variables like userID and API_BASE_URL

class OrdersListScreen extends StatefulWidget {
  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  // Function to fetch the user's orders
  Future<void> fetchOrders() async {
    final String apiUrl = "${API_BASE_URL}/orders/byuser/$globalUserId"; // Fetch orders by user ID
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body); // Assuming API returns a list of orders in 'data'
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
    fetchOrders(); // Fetch orders when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Orders"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text("You have no orders"))
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          var order = orders[index];
          return ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text("Order ID: ${order['id']}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Product: ${order['product']['name']}"),
                Text("Quantity: ${order['product_qty']}"),
                Text("Status: ${order['order_status']}"),
                Text(
                  "Total Price: ${order['order_price']}",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Navigate to OrderDetailsScreen when an order is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(
                    orderId: order['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
