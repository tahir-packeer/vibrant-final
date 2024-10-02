import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'order_form_screen.dart'; // Import the order form screen
import '../../global.dart'; // import the global variables

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  ProductDetailScreen({required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;

  // Function to fetch product details by ID
  Future<void> fetchProductDetails() async {
    final String apiUrl = "${API_BASE_URL}/products/${widget.productId}";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          product = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load product details');
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
    fetchProductDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : product == null
          ? Center(child: Text('Product not found'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                "http://10.0.2.2:8000${product!['image']}",
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image, size: 100);
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              product!['name'],
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Check if product has promotion and display accordingly
            if (product!['promotion_price'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Promotion Price: \$${product!['promotion_price']}",
                    style: TextStyle(
                        fontSize: 22,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Original Price: \$${product!['item_price']}",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              )
            else
              Text(
                "Price: \$${product!['item_price']}",
                style: TextStyle(
                    fontSize: 22, color: Colors.green),
              ),

            SizedBox(height: 10),
            Text(
              "Description: ${product!['description']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "Available Quantity: ${product!['quantity']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Divider(),
            Text(
              "Category Details",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Category: ${product!['category']['name']}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 5),
            Text(
              "Category Description: ${product!['category']['description']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              "Fabric Type: ${product!['category']['fabric_type']}",
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderFormScreen(
                      productId: widget.productId,
                      productName: product!['name'],
                      availableQuantity: product!['quantity'],
                    ),
                  ),
                );
              },
              child: Text("Order Now"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    vertical: 15, horizontal: 20),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
