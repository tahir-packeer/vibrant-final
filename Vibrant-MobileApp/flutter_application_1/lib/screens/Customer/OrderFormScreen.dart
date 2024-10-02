import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../global.dart';
import 'customerDashboard.dart'; // import your global constants like API_BASE_URL

class OrderFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderDetails;
  final double cartTotal;

  OrderFormScreen({required this.orderDetails, required this.cartTotal});

  @override
  _OrderFormScreenState createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool isLoading = false;

  // Function to place an order using the Laravel API
  Future<void> placeOrder() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = "${API_BASE_URL}/orders/bulk/cart";

    // Prepare the order payload
    Map<String, dynamic> orderPayload = {
      'user_id': 1,  // Replace this with actual user_id from user authentication
      'user_name': _nameController.text,
      'user_address': _addressController.text,
      'payment_status': 'Paid',  // Set it dynamically based on the payment status
      'order_status': 'Order Placed',
      'products': widget.orderDetails,  // Product details with id and quantity
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(orderPayload),
      );

      if (response.statusCode == 201) {
        // Order placed successfully
        print("Order placed successfully");

        // Show a success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('Your order has been placed successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  // Navigate to the CustomerDashboard page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CustomerDashboard()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to place order');
      }
    } catch (error) {
      print("Error placing order: $error");
      // Show an error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to place the order. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Form'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Display the product details dynamically
            for (var item in widget.orderDetails)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product: ${item['product_name']}',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Product ID: ${item['product_id']}'),
                    Text('Quantity: ${item['product_qty']}'),
                  ],
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Your Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Your Address'),
            ),
            SizedBox(height: 20),
            Text(
              'Payment Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _cardHolderController,
              decoration: InputDecoration(
                labelText: 'Card Holder Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              "Total: \$${widget.cartTotal.toStringAsFixed(2)}",
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: placeOrder,
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
    );
  }
}
