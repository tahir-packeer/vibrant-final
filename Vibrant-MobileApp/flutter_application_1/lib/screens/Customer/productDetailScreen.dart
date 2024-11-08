import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'order_form_screen.dart';
import '../../global.dart';

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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : product == null
          ? Center(child: Text('Product not found'))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    "http://10.0.2.2:8000${product!['image']}",
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image, size: 100);
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                product!['name'],
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (product!['promotion_price'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Promotion Price: \$${product!['promotion_price']}",
                      style: TextStyle(fontSize: 22, color: Colors.green.shade400, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Original Price: \$${product!['item_price']}",
                      style: TextStyle(fontSize: 18, color: Colors.grey, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                )
              else
                Text(
                  "Price: \$${product!['item_price']}",
                  style: TextStyle(fontSize: 22, color: Colors.green),
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
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: product!['quantity'] > 0
                      ? () {
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
                  }
                      : null,
                  child: Text(
                    product!['quantity'] > 0 ? "Order Now" : "Out of Stock",
                    style: TextStyle(fontSize: 18, color: product!['quantity'] > 0 ? Colors.white : Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 130),
                    backgroundColor: product!['quantity'] > 0 ? Colors.black : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}