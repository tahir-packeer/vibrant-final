import 'package:flutter/material.dart';
import '../../global.dart'; // import the global variables
import 'productCategory.dart';
import 'manage_products.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Welcome Admin! Your ID is: $globalUserId"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductCategoryScreen()),
                );
              },
              child: Text("Manage Product Categories"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageProductsPage()),
                );
              },
              child: Text('Manage Products'),
            ),

          ],
        ),
      ),
    );
  }
}
