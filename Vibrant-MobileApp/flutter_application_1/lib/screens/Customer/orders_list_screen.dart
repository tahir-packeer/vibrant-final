import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'order_details_screen.dart';
import '../../global.dart';
import '../../custom_colors.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  _OrdersListScreenState createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final String apiUrl = "$API_BASE_URL/orders/byuser/$globalUserId";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            // Handle both array and single object responses
            if (decodedResponse is List) {
              orders = decodedResponse.reversed.toList();
            } else if (decodedResponse is Map && decodedResponse.containsKey('data')) {
              orders = (decodedResponse['data'] as List).reversed.toList();
            } else {
              orders = [];
            }
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (error) {
      print('Error fetching orders: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          orders = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Your Orders',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color ?? Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Text(
                    "You have no orders",
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                    ),
                  ),
                )
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
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      color: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                Icon(Icons.shopping_cart, 
                    color: theme.textTheme.bodyMedium?.color ?? Colors.grey),
              ],
            ),
            const SizedBox(height: 10),
            Divider(thickness: 2, color: theme.dividerColor),
            const SizedBox(height: 10),
            if (order['product'] != null) ...[
              Text(
                order['product']['name'] ?? 'Product Name Not Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                ),
              ),
              Text(
                "Qty: ${order['product_qty'] ?? 'N/A'}",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.black,
                ),
              ),
              Text(
                "Status: ${order['order_status'] ?? 'Processing'}",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Total: Rs ${order['order_price'] ?? '0.00'}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.cardTheme.color,
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
                      color: theme.textTheme.bodyLarge?.color ?? Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
