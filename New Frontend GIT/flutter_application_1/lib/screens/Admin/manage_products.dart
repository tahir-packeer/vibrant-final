import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../global.dart'; // import the global variables


class ManageProductsPage extends StatefulWidget {
  @override
  _ManageProductsPageState createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  List<dynamic> categories = [];
  String? selectedCategory;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String status = 'Active'; // Example status

  @override
  void initState() {
    super.initState();
    fetchCategories(); // Fetch categories on page load
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('${API_BASE_URL}/product_category'));
    if (response.statusCode == 200) {
      print("response.body: ${response.body}");
      setState(() {
        categories = jsonDecode(response.body)['data'];
      });
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> addProduct() async {
    final response = await http.post(
      Uri.parse('${API_BASE_URL}/product/create'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'name': nameController.text,
        'description': descriptionController.text,
        'item_price': priceController.text,
        'category_id': selectedCategory,
        'quantity': quantityController.text,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product created successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create product')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Products')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              hint: Text('Select Category'),
              items: categories.map<DropdownMenuItem<String>>((category) {
                return DropdownMenuItem<String>(
                  value: category['id'].toString(),
                  child: Text(category['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Product Description'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField<String>(
              value: status,
              decoration: InputDecoration(labelText: 'Status'),
              items: [
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (value) {
                setState(() {
                  status = value!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addProduct,
              child: Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
