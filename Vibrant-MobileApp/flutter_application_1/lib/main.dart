import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/Customer/customerDashboard.dart';
import './screens/register.dart';
import './screens/login.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: Consumer<ThemeProvider>(
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
            },
          );
        },
      ),
    );
  }
}
