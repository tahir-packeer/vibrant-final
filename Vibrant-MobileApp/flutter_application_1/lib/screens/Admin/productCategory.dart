import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../global.dart'; // Import the global variables

class ProductCategoryScreen extends StatefulWidget {
  @override
  _ProductCategoryScreenState createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _categoryNameController = TextEditingController();
  TextEditingController _fabricTypeController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  List<dynamic> _categories = []; // To store the product categories
  bool _isEditMode = false; // To track if we are in edit mode
  int? _editingCategoryId; // To track the current category being edited

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the screen is loaded
  }

  // Function to fetch categories
  Future<void> _fetchCategories() async {
    final url = Uri.parse('${API_BASE_URL}/product_category');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _categories = data['data']; // Store categories in state
        });
      } else {
        showSnackbarMessage(context, "Failed to load categories", false);
      }
    } catch (e) {
      showSnackbarMessage(context, "Error: $e", false);
    }
  }

  // Function to submit new or updated category
  Future<void> submitCategory() async {
    setState(() {
      _isLoading = true; // Show loading spinner
    });

    final url = _isEditMode
        ? Uri.parse('${API_BASE_URL}/product_category/update/$_editingCategoryId')
        : Uri.parse('${API_BASE_URL}/product_category');

    // Create a multipart request
    var request = http.MultipartRequest('POST', url);
    request.fields['name'] = _categoryNameController.text;
    request.fields['fabric_type'] = _fabricTypeController.text;
    request.fields['description'] = _descriptionController.text;

    final response = await request.send();

    setState(() {
      _isLoading = false; // Hide loading spinner
    });

    if (response.statusCode == 200) {
      showSnackbarMessage(context, _isEditMode ? "Category updated successfully!" : "Category created successfully!", true);
      _fetchCategories(); // Refresh categories
      _resetForm(); // Reset form after submission
    } else {
      showSnackbarMessage(context, "Failed to submit category.", false);
    }
  }

  // Function to delete a category
  Future<void> _deleteCategory(int id) async {
    final url = Uri.parse('${API_BASE_URL}/product_category/delete/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        showSnackbarMessage(context, "Category deleted successfully!", true);
        _fetchCategories(); // Refresh categories after deletion
      } else {
        showSnackbarMessage(context, "Failed to delete category.", false);
      }
    } catch (e) {
      showSnackbarMessage(context, "Error: $e", false);
    }
  }

  // Function to reset the form
  void _resetForm() {
    setState(() {
      _categoryNameController.clear();
      _fabricTypeController.clear();
      _descriptionController.clear();
      _isEditMode = false;
      _editingCategoryId = null;
    });
  }

  // Function to load a category for editing
  void _editCategory(int id) async {
    final url = Uri.parse('${API_BASE_URL}/product_category/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Print the response details in the console
        print('Response status: ${response.statusCode}');
        print('Response body name: ${data['data']['name']}');  // Corrected line
        print('Response headers: ${response.headers}');

        setState(() {
          // Load the data into the controllers for editing
          _categoryNameController.text = data['data']['name'] ?? '';
          _fabricTypeController.text = data['data']['fabric_type'] ?? '';
          _descriptionController.text = data['data']['description'] ?? '';
          _isEditMode = true;
          _editingCategoryId = id;
        });
      } else {
        showSnackbarMessage(context, "Failed to load category. Status Code: ${response.statusCode}", false);
      }
    } catch (e) {
      showSnackbarMessage(context, "Error: $e", false);
    }
  }



  // Function to display snackbar messages
  void showSnackbarMessage(BuildContext context, String message, bool success) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: success ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Product Category" : "Create Product Category"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Text field for Category Name
                TextFormField(
                  controller: _categoryNameController,
                  decoration: InputDecoration(labelText: 'Category Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                // Text field for Fabric Type
                TextFormField(
                  controller: _fabricTypeController,
                  decoration: InputDecoration(labelText: 'Fabric Type'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the fabric type';
                    }
                    return null;
                  },
                ),
                // Text field for Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                // Submit button for creating or updating category
                _isLoading
                    ? CircularProgressIndicator() // Show spinner while loading
                    : ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      submitCategory();
                    }
                  },
                  child: Text(_isEditMode ? 'Update Category' : 'Create Category'),
                ),
                SizedBox(height: 20),
                // Display the categories
                Text(
                  "Product Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _categories.isEmpty
                    ? Text("No categories available.")
                    : ListView.builder(
                  shrinkWrap: true, // Avoid scrolling issues
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      leading: category['image'] != null
                          ? Image.network(
                        '${API_BASE_URL}/${category['image']}', // Load image from URL
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : Icon(Icons.category), // Placeholder icon
                      title: Text(category['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fabric: ${category['fabric_type']}'),
                          Text(category['description']),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editCategory(category['id']);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteCategory(category['id']);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
