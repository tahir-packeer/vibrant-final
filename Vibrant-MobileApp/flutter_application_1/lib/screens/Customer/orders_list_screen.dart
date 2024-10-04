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
          orders = json.decode(response.body).reversed.toList(); // Reverse the list so new orders are at the top
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
        title: Text("Your Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
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
            return _buildOrderCard(order);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
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
                Icon(Icons.shopping_cart, color: Colors.deepPurple),
              ],
            ),
            SizedBox(height: 10),
            Divider(thickness: 2, color: Colors.grey[300]),
            SizedBox(height: 10),
            Text("Product: ${order['product']['name']}", style: TextStyle(fontSize: 16)),
            Text("Quantity: ${order['product_qty']}", style: TextStyle(fontSize: 16)),
            Text("Status: ${order['order_status']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text(
              "Total Price: \$${order['order_price']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
              ),
              onPressed: () {
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
              child: Text("View Details", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}