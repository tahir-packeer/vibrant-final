import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../global.dart';
import 'customerDashboard.dart';

class OrderFormScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderDetails;
  final double cartTotal;

  const OrderFormScreen({super.key, required this.orderDetails, required this.cartTotal});

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

    const String apiUrl = "$API_BASE_URL/orders/bulk/cart";

    // Prepare the order payload
    Map<String, dynamic> orderPayload = {
      'user_id': globalUserId, // Ensure you're using the actual logged-in user's ID
      'user_name': _nameController.text,
      'user_address': _addressController.text,
      'payment_status': 'Paid',
      'order_status': 'Order Placed',
      'products': widget.orderDetails,
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

        // Navigate back to the orders list and refresh
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CustomerDashboard(),
          ),
        );
      } else {
        throw Exception('Failed to place order');
      }
    } catch (error) {
      print("Error placing order: $error");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to place the order. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
        title: const Text('Order Form'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Product ID: ${item['product_id']}'),
                    Text('Quantity: ${item['product_qty']}'),
                  ],
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Your Address'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Card Holder Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Total: \$${widget.cartTotal.toStringAsFixed(2)}",
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: placeOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: Text("Place Order"),
            ),
          ],
        ),
      ),
    );
  }
}
