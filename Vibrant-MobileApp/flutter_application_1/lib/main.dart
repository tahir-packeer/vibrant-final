import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import the ThemeProvider
import 'screens/Admin/adminDashboard.dart';
import 'screens/Admin/productCategory.dart';
import 'screens/Customer/customerDashboard.dart';
import './screens/register.dart';
import './screens/login.dart';
import 'splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Authentication App with Splash Screen',
          theme: themeProvider.currentTheme,
          home: SplashScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/customerDashboard': (context) => CustomerDashboard(),
            '/adminDashboard': (context) => AdminDashboard(),
            '/productCategory': (context) => ProductCategoryScreen(),
          },
        );
      },
    );
  }
}