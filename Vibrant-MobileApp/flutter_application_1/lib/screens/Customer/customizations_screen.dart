import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../global.dart';

class CustomizationsScreen extends StatefulWidget {
  @override
  _CustomizationsScreenState createState() => _CustomizationsScreenState();
}

class _CustomizationsScreenState extends State<CustomizationsScreen> {
  List<dynamic> customizations = [];
  List<dynamic> pendingPayments = [];
  bool isLoading = true;

  // Function to fetch all customizations for a user
  Future<void> fetchCustomizations() async {
    final String apiUrl = "${API_BASE_URL}/customizations/$globalUserId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          customizations = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load customizations');
      }
    } catch (error) {
      print(error);
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to fetch pending payment customizations
  Future<void> fetchPendingPayments() async {
    final String apiUrl = "${API_BASE_URL}/customizations/$globalUserId/pending-payment";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          pendingPayments = json.decode(response.body)['data'];
        });
      } else {
        throw Exception('Failed to load pending payments');
      }
    } catch (error) {
      print(error);
    }
  }

  // Function to confirm payment for a customization
  Future<void> confirmPayment(int customizationId) async {
    final String apiUrl = "${API_BASE_URL}/customizations/$customizationId/confirm-payment";
    try {
      final response = await http.put(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json.decode(response.body)['message'])),
        );
        fetchPendingPayments(); // Refresh the pending payments after confirmation
      } else {
        throw Exception('Failed to confirm payment');
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while confirming payment.')),
      );
    }
  }

  // Function to get the user's current location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, ask the user to enable them.
      return Future.error('Location services are disabled.');
    }

    // Check if permission is granted
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show an error message
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, handle this situation
      return Future.error(
          'Location permissions are permanently denied, cannot request permissions.');
    }

    // If all permissions are granted, return the user's current position
    return await Geolocator.getCurrentPosition();
  }

  // Function to create a new customization with geolocation
  Future<void> createCustomization(
      String title, String description, int quantity, String note, String? filePath) async {
    final String apiUrl = "${API_BASE_URL}/customizations";

    try {
      // Get the user's location before creating the customization
      Position position = await _determinePosition();

      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['quantity'] = quantity.toString();
      request.fields['user_id'] = globalUserId.toString();
      request.fields['note'] = note;
      request.fields['unit_price'] = '0'; // User does not send price, backend will handle it
      request.fields['total_price'] = '0';

      // Add geolocation data to the request fields
      request.fields['latitude'] = position.latitude.toString();
      request.fields['longitude'] = position.longitude.toString();

      if (filePath != null) {
        request.files.add(await http.MultipartFile.fromPath('image', filePath));
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Customization created successfully'),
        ));
        fetchCustomizations(); // Refresh the list of customizations
      } else {
        throw Exception('Failed to create customization');
      }
    } catch (error) {
      print('Error creating customization: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create customization')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCustomizations();
    fetchPendingPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customizations"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _showCreateCustomizationDialog();
              },
              child: Text("Create Customization"),
            ),
            SizedBox(height: 20),
            Text(
              "Pending Payment Customizations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: pendingPayments.length,
                itemBuilder: (context, index) {
                  var customization = pendingPayments[index];
                  return ListTile(
                    leading: Image.network(
                      "http://10.0.2.2:8000/${customization['image']}",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(customization['title']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${customization['status']}"),
                        Text("Unit Price: \$${customization['unit_price']}"),
                        Text("Total Price: \$${customization['total_price']}"),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        confirmPayment(customization['id']);
                      },
                      child: Text("Confirm Payment"),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              "All Customizations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customizations.length,
                itemBuilder: (context, index) {
                  var customization = customizations[index];
                  return ListTile(
                    leading: Image.network(
                      "http://10.0.2.2:8000/${customization['image']}",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(customization['title']),
                    subtitle: Text("Status: ${customization['status']}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to show a dialog for creating customization
  Future<void> _showCreateCustomizationDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedFilePath;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Create Customization"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(labelText: 'Note'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    // Use file_picker to select a file
                    final result = await FilePicker.platform.pickFiles();
                    if (result != null && result.files.isNotEmpty) {
                      setState(() {
                        selectedFilePath = result.files.first.path; // Get the path of the selected file
                      });
                    }
                  },
                  child: Text(selectedFilePath == null
                      ? "Select File"
                      : "File Selected: ${selectedFilePath!.split('/').last}"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Create"),
              onPressed: () {
                createCustomization(
                  titleController.text,
                  descriptionController.text,
                  int.parse(quantityController.text),
                  noteController.text,
                  selectedFilePath,
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
