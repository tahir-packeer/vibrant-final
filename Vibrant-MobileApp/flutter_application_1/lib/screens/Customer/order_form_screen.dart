import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../global.dart'; // Import global variables like API_BASE_URL and user_id

class OrderFormScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final int availableQuantity;

  const OrderFormScreen({
    super.key,
    required this.productId,
    required this.productName,
    required this.availableQuantity,
  });

  @override
  _OrderFormScreenState createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String userName = '';
  String userAddress = '';
  int productQty = 1; // Default quantity set to 1
  bool isSubmitting = false;
  bool isAddingToCart = false;

  String selectedCardType = 'Visa'; // Default card type
  final cardNumberController = TextEditingController();
  final cardNameController = TextEditingController();
  final cardExpiryController = TextEditingController();
  final cardCvvController = TextEditingController();
  double finalAmount = 0.0;

  // Function to submit order details
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    const String apiUrl = "$API_BASE_URL/orders/bulk/cart";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': globalUserId,
          'user_name': userName,
          'user_address': userAddress,
          'payment_status': 'Paid',
          'order_status': 'Order Placed',
          'products': [
            {
              'product_id': widget.productId,
              'product_name': widget.productName,
              'product_qty': productQty,
            }
          ],
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order placed successfully for ${widget.productName}!"),
        ));
        Navigator.pop(context); // Go back after order is placed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to place the order. Please try again."),
        ));
      }
    } catch (error) {
      print("Error placing order: $error");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Error placing the order."),
      ));
    }

    setState(() {
      isSubmitting = false;
    });
  }

  // Function to fetch product details by product ID
  Future<Map<String, dynamic>?> _fetchProductDetails(int productId) async {
    final String productApiUrl = "$API_BASE_URL/products/$productId";

    print("Fetching product details from: $productApiUrl");

    try {
      final response = await http.get(Uri.parse(productApiUrl));

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Decoded JSON data: $data");

        if (data.containsKey('data')) {
          print("Product details found: ${data['data']}");
          return data['data'];
        } else {
          print("No 'data' key found in the response.");
          return null;
        }
      } else {
        print(
            "Failed to load product details. Status Code: ${response.statusCode}");
        return null;
      }
    } catch (error) {
      print("Error fetching product details: $error");
      return null;
    }
  }

  // Function to add product to cart
  Future<void> _addToCart() async {
    setState(() {
      isAddingToCart = true;
    });

    final productDetails = await _fetchProductDetails(widget.productId);
    if (productDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch product details")),
      );
      setState(() {
        isAddingToCart = false;
      });
      return;
    }

    const String addToCartApiUrl = "$API_BASE_URL/add-to-cart";
    final double itemPrice = double.parse(productDetails['item_price']);
    final double totalPrice = itemPrice * productQty;
    final productImage = productDetails['image'];

    try {
      final response = await http.post(
        Uri.parse(addToCartApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product_id': productDetails['id'].toString(),
          'product_name': productDetails['name'],
          'product_image': productImage,
          'item_price': itemPrice.toString(),
          'product_qty': productQty.toString(),
          'total_price': totalPrice.toString(),
          'user_id':
              globalUserId.toString(), // Assume globalUserId from global.dart
        }),
      );

      print("Response body cart: ${response.body}");
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added to the cart")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to add product to cart")),
        );
      }
    } catch (error) {
      print("Error adding to cart: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error adding product to cart")),
      );
    }

    setState(() {
      isAddingToCart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Form"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Product: ${widget.productName}",
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: "Your Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    userName = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: "Your Address"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    userAddress = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: productQty,
                decoration: const InputDecoration(labelText: "Quantity"),
                items: List.generate(widget.availableQuantity, (index) {
                  int quantity = index + 1;
                  return DropdownMenuItem<int>(
                    value: quantity,
                    child: Text(quantity.toString()),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    productQty = value ?? 1;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Card Details Section
              _buildCardDetailsSection(),

              const Spacer(),
              ElevatedButton(
                onPressed: isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isSubmitting
                    ? CircularProgressIndicator()
                    : Text("Place Order"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isAddingToCart
                    ? CircularProgressIndicator()
                    : Text("Add to Cart"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Payment Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Card Type Selector
        Row(
          children: [
            _buildCardTypeOption("Visa"),
            const SizedBox(width: 10),
            _buildCardTypeOption("MasterCard"),
          ],
        ),

        const SizedBox(height: 20),
        TextFormField(
          controller: cardNumberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Card Number",
            prefixIcon: Icon(Icons.credit_card),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your card number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: cardNameController,
          decoration: const InputDecoration(
            labelText: "Card Holder Name",
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the card holder name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: cardExpiryController,
                decoration: const InputDecoration(
                  labelText: "Expiry Date",
                  hintText: "MM/YY",
                  prefixIcon: Icon(Icons.date_range),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter expiry date';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextFormField(
                controller: cardCvvController,
                decoration: const InputDecoration(
                  labelText: "CVV",
                  hintText: "123",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter CVV';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardTypeOption(String cardType) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCardType = cardType;
        });
      },
      child: Row(
        children: [
          Icon(
            cardType == "Visa" ? Icons.credit_card : Icons.credit_card_outlined,
            color: selectedCardType == cardType ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 5),
          Text(
            cardType,
            style: TextStyle(
              color: selectedCardType == cardType ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
