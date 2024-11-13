import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'OrderFormScreen.dart';
import '../../global.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? product;
  bool isLoading = true;
  late AnimationController _animationController;
  bool _isAddingToCart = false;
  bool _showSuccess = false;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> addToCart(
      int productId, String productName, double price) async {
    setState(() {
      _isAddingToCart = true;
    });

    const String addToCartApiUrl = "$API_BASE_URL/add-to-cart";
    try {
      final requestBody = {
        'product_id': productId.toString(),
        'product_name': productName,
        'product_image': product!['image'],
        'item_price': price.toString(),
        'product_qty': "1",
        'total_price': price.toString(),
        'user_id': globalUserId.toString(),
      };

      final response = await http.post(
        Uri.parse(addToCartApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        setState(() {
          _showSuccess = true;
        });
        _animationController.forward().then((_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _showSuccess = false;
                _isAddingToCart = false;
              });
              _animationController.reset();
            }
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added to the cart"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isAddingToCart = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add product to cart"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isAddingToCart = false;
      });
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
      backgroundColor: isDarkMode
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? const Center(child: Text('Product not found'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: isDarkMode
                          ? Theme.of(context).appBarTheme.backgroundColor
                          : Colors.white,
                      iconTheme: IconThemeData(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              "http://192.168.8.78:8000${product!['image'] ?? ''}",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image,
                                    size: 100);
                              },
                            ),
                            // Gradient overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 80,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      isDarkMode
                                          ? Colors.black.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product!['name'],
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (product!['promotion_price'] != null)
                                      Text(
                                        "Rs ${product!['promotion_price']}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade400,
                                        ),
                                      ),
                                    if (product!['promotion_price'] != null)
                                      Text(
                                        "Rs ${product!['item_price']}",
                                        style: TextStyle(
                                          fontSize: 16,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      )
                                    else
                                      Text(
                                        "Rs ${product!['item_price']}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade400,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Available: ${product!['quantity']} items",
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Description",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product!['description'],
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Category Details",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCategoryDetail(
                                    "Category",
                                    product!['category']?['name'] ?? 'N/A',
                                    isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildCategoryDetail(
                                    "Description",
                                    product!['category']?['description'] ??
                                        'N/A',
                                    isDarkMode,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            Row(
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  child: ElevatedButton(
                                    onPressed: (_isAddingToCart ||
                                            product!['quantity'] <= 0)
                                        ? null
                                        : () {
                                            double price = product![
                                                        'promotion_price'] !=
                                                    null
                                                ? double.parse(
                                                    product!['promotion_price']
                                                        .toString())
                                                : double.parse(
                                                    product!['item_price']
                                                        .toString());
                                            addToCart(widget.productId,
                                                product!['name'], price);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      backgroundColor: product!['quantity'] > 0
                                          ? (isDarkMode
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child,
                                          Animation<double> animation) {
                                        return ScaleTransition(
                                            scale: animation, child: child);
                                      },
                                      child: _isAddingToCart
                                          ? _showSuccess
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 24,
                                                  key: ValueKey('check'),
                                                )
                                              : SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  key:
                                                      const ValueKey('loading'),
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                          : Icon(
                                              Icons.shopping_cart,
                                              color: isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              size: 24,
                                              key: const ValueKey('cart'),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: product!['quantity'] > 0
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OrderFormScreen(
                                                  orderDetails: [
                                                    {
                                                      'product_id':
                                                          widget.productId,
                                                      'product_name':
                                                          product!['name'],
                                                      'product_image':
                                                          product!['image'],
                                                      'product_qty': 1,
                                                      'item_price': product![
                                                              'promotion_price'] ??
                                                          product![
                                                              'item_price'],
                                                      'total_price': product![
                                                              'promotion_price'] ??
                                                          product![
                                                              'item_price'],
                                                    }
                                                  ],
                                                  cartTotal: double.parse(
                                                      product!['promotion_price']
                                                              ?.toString() ??
                                                          product!['item_price']
                                                              .toString()),
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      backgroundColor: product!['quantity'] > 0
                                          ? (isDarkMode
                                              ? Colors.white
                                              : Colors.black)
                                          : Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      product!['quantity'] > 0
                                          ? "Buy Now"
                                          : "Out of Stock",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: product!['quantity'] > 0
                                            ? (isDarkMode
                                                ? Colors.black
                                                : Colors.white)
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCategoryDetail(String label, String value, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
