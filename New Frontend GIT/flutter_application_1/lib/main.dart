import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/Admin/adminDashboard.dart';
import 'package:flutter_application_1/screens/Admin/productCategory.dart';
import 'package:flutter_application_1/screens/Customer/customerDashboard.dart';
import './screens/register.dart'; // Import the RegisterScreen
import './screens/login.dart'; // Import the LoginScreen
import 'splash_screen.dart'; // Import the splash screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication App with Splash Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),  // Set SplashScreen as the initial screen
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/customerDashboard': (context) => CustomerDashboard(),
        '/adminDashboard': (context) => AdminDashboard(),
        '/productCategory': (context) => ProductCategoryScreen(),
      },
    );
  }
}
