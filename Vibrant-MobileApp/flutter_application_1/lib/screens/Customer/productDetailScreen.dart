import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'order_form_screen.dart';
import '../../global.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? product;
  bool isLoading = true;

  // Function to fetch product details by ID
  Future<void> fetchProductDetails() async {
    final String apiUrl = "$API_BASE_URL/products/${widget.productId}";
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

  Future<void> addToCart(
      int productId, String productName, double price) async {
    const String addToCartApiUrl = "$API_BASE_URL/add-to-cart";
    try {
      print('Sending request to: $addToCartApiUrl');

      final requestBody = {
        'product_id': productId.toString(),
        'product_name': productName,
        'product_image': product!['image'],
        'item_price': price.toString(),
        'product_qty': "1",
        'total_price': price.toString(),
        'user_id': globalUserId.toString(),
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(addToCartApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added to the cart"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add product to cart"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("Error adding to cart: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? const Center(child: Text('Product not found'))
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
                                return const Icon(Icons.broken_image,
                                    size: 100);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          product!['name'],
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        if (product!['promotion_price'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Promotion Price: \$${product!['promotion_price']}",
                                style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.green.shade400,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Original Price: \$${product!['item_price']}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          )
                        else
                          Text(
                            "Price: \$${product!['item_price']}",
                            style: const TextStyle(
                                fontSize: 22, color: Colors.green),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          "Description: ${product!['description']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Available Quantity: ${product!['quantity']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const Text(
                          "Category Details",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Category: ${product!['category']['name']}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Category Description: ${product!['category']['description']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Fabric Type: ${product!['category']['fabric_type']}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: product!['quantity'] > 0
                                    ? () {
                                        double price =
                                            product!['promotion_price'] != null
                                                ? double.parse(
                                                    product!['promotion_price']
                                                        .toString())
                                                : double.parse(
                                                    product!['item_price']
                                                        .toString());
                                        addToCart(widget.productId,
                                            product!['name'], price);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 40),
                                  backgroundColor: product!['quantity'] > 0
                                      ? Colors.blue
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  product!['quantity'] > 0
                                      ? "Add to Cart"
                                      : "Out of Stock",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: product!['quantity'] > 0
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrderFormScreen(
                                              productId: widget.productId,
                                              productName: product!['name'],
                                              availableQuantity:
                                                  product!['quantity'],
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 15, horizontal: 40),
                                  backgroundColor: product!['quantity'] > 0
                                      ? Colors.black
                                      : Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  product!['quantity'] > 0
                                      ? "Buy Now"
                                      : "Out of Stock",
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: product!['quantity'] > 0
                                          ? Colors.white
                                          : Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
