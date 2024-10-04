import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the next screen after a delay
    Timer(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white, // Set the background color to white
        child: Center(
          child: SizedBox(
            width: 150, // Set the width you want for the GIF
            height: 150, // Set the height you want for the GIF
            child: Image.asset(
              'assets/splashlogo.gif', // Replace with your GIF image file
              fit: BoxFit.contain, // Makes the GIF fit within the defined size
            ),
          ),
        ),
      ),
    );
  }
}
