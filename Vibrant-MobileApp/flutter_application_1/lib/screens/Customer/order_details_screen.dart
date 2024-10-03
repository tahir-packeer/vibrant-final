import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../global.dart'; // Import global variables like API_BASE_URL

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  OrderDetailsScreen({required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;

  // Function to fetch order details by ID
  Future<void> fetchOrderDetails() async {
    final String apiUrl = "${API_BASE_URL}/deliverers/order/${widget.orderId}";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          orderDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (error) {
      print("Error fetching order details: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orderDetails == null
          ? Center(child: Text("Failed to load order details"))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderCard(),
              SizedBox(height: 20),
              _buildDelivererCard(),
              SizedBox(height: 20),
              _buildProductCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${orderDetails!['order']['id']}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 2),
            Text(
              "Total Price: \$${orderDetails!['order']['order_price']}",
              style: TextStyle(fontSize: 20, color: Colors.green),
            ),
            Text(
              "Order Status: ${orderDetails!['order']['order_status']}",
              style: TextStyle(fontSize: 18, color: Colors.deepOrange),
            ),
            SizedBox(height: 10),
            Text(
              "Quantity: ${orderDetails!['order']['product_qty']}",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelivererCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Deliverer Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 2),
            orderDetails!['deliverer'] == null
                ? Text(
              "No deliverer assigned yet",
              style: TextStyle(fontSize: 18, color: Colors.red),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Deliverer Name: ${orderDetails!['deliverer']['deliverer_name']}",
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  "Delivery Status: ${orderDetails!['deliverer']['delivery_status']}",
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  "Delivery Note: ${orderDetails!['deliverer']['delivery_note']}",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Product Details",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Divider(thickness: 2),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  "http://10.0.2.2:8000/${orderDetails!['order']['product']['image']}",
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Product Name: ${orderDetails!['order']['product']['name']}",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "Description: ${orderDetails!['order']['product']['description']}",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "Category: ${orderDetails!['order']['product']['category_name']}",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "Item Price: \$${orderDetails!['order']['product']['item_price']}",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}