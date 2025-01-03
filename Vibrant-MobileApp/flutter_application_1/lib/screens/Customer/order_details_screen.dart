import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../custom_colors.dart';
import '../../global.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;

  // Function to fetch order details by ID
  Future<void> fetchOrderDetails() async {
    final String apiUrl = "$API_BASE_URL/deliverers/order/${widget.orderId}";
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: isDarkMode
                ? CustomColors.textColorDark
                : CustomColors.textColorLight),
        title: Text("Order Details",
            style: TextStyle(
                color: isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight)),
        backgroundColor: isDarkMode
            ? CustomColors.primaryColorDark
            : CustomColors.primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            isLoading = true;
            orderDetails = null;
          });
          await fetchOrderDetails();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: isLoading
              ? SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode
                          ? CustomColors.textColorDark
                          : CustomColors.textColorLight,
                    ),
                  ),
                )
              : orderDetails == null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Text(
                          "Failed to load order details",
                          style: TextStyle(
                            color: isDarkMode
                                ? CustomColors.textColorDark
                                : CustomColors.textColorLight,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOrderCard(isDarkMode),
                          const SizedBox(height: 20),
                          _buildDelivererCard(isDarkMode),
                          const SizedBox(height: 20),
                          _buildProductCard(isDarkMode),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(bool isDarkMode) {
    return Card(
      color: isDarkMode
          ? Theme.of(context).appBarTheme.backgroundColor
          : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${orderDetails!['order']['id']}",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight,
              ),
            ),
            Divider(
                color: isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight,
                thickness: 1),
            const SizedBox(height: 8),
            _buildStatusRow(
              "Order Status:",
              orderDetails!['order']['order_status'],
              Colors.redAccent,
              isDarkMode,
            ),
            _buildStatusRow(
                "Total Price:",
                "Rs ${orderDetails!['order']['order_price']}",
                Colors.green.shade400,
                isDarkMode),
            const SizedBox(height: 8),
            Text(
              "Quantity: ${orderDetails!['order']['product_qty']}",
              style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? CustomColors.textColorDark
                      : CustomColors.textColorLight.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      String label, String value, Color valueColor, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 18,
              color: isDarkMode
                  ? CustomColors.textColorDark
                  : CustomColors.textColorLight),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: 18, color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDelivererCard(bool isDarkMode) {
    return Card(
      color: isDarkMode
          ? Theme.of(context).appBarTheme.backgroundColor
          : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Deliverer Details",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? CustomColors.textColorDark
                      : CustomColors.textColorLight),
            ),
            Divider(
                color: isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight,
                thickness: 1),
            const SizedBox(height: 8),
            orderDetails!['deliverer'] == null
                ? const Text("No deliverer assigned yet",
                    style: TextStyle(color: Colors.redAccent))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Deliverer Name: ${orderDetails!['deliverer']['deliverer_name']}",
                        style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? CustomColors.textColorDark
                                : CustomColors.textColorLight),
                      ),
                      _buildStatusRow(
                          "Delivery Status:",
                          orderDetails!['deliverer']['delivery_status'],
                          Colors.green.shade400,
                          isDarkMode),
                      const SizedBox(height: 8),
                      Text(
                        "Delivery Note: ${orderDetails!['deliverer']['delivery_note']}",
                        style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? CustomColors.textColorDark.withOpacity(0.7)
                                : CustomColors.textColorLight.withOpacity(0.7)),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(bool isDarkMode) {
    return Card(
      color: isDarkMode
          ? Theme.of(context).appBarTheme.backgroundColor
          : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Product Details",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? CustomColors.textColorDark
                      : CustomColors.textColorLight),
            ),
            Divider(
                color: isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight,
                thickness: 1),
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  "http://192.168.8.78:8000/${orderDetails!['order']['product']['image']}",
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 150,
                      height: 150,
                      color: isDarkMode
                          ? CustomColors.cardColorDark
                          : CustomColors.cardColorLight.withOpacity(0.5),
                      child: const Icon(Icons.broken_image,
                          size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildProductInfoRow("Product Name:",
                orderDetails!['order']['product']['name'], isDarkMode),
            _buildProductInfoRow("Description:",
                orderDetails!['order']['product']['description'], isDarkMode),
            _buildProductInfoRow("Category:",
                orderDetails!['order']['product']['category_name'], isDarkMode),
            _buildProductInfoRow(
                "Price:",
                "\Rs ${orderDetails!['order']['product']['item_price']}",
                isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? CustomColors.textColorDark
                    : CustomColors.textColorLight),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? CustomColors.textColorDark.withOpacity(0.7)
                    : CustomColors.textColorLight.withOpacity(0.7),
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
