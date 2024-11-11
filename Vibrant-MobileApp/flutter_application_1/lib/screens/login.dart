import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../global.dart';
import './Customer/customerDashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  final bool _isLoading = false;
  bool _passwordVisible = false; // Visibility toggle for password
  String _connectionStatus = ''; // To display the connection status
  late Connectivity _connectivity;
  late Stream<ConnectivityResult> _connectivityStream;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream =
        _connectivity.onConnectivityChanged.map((event) => event.first);

    _connectivityStream.listen((ConnectivityResult result) {
      _updateConnectionStatus(result);
    });
  }

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    final ConnectivityResult result = results.first;
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    String status;
    if (result == ConnectivityResult.mobile) {
      status = 'Connected to Mobile Data';
    } else if (result == ConnectivityResult.wifi) {
      status = 'Connected to WiFi';
    } else {
      status = 'No Internet Connection';
    }

    setState(() {
      _connectionStatus = status;
    });

    _startStatusTimer();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _connectionStatus = '';
      });
    });
  }

  Future<void> loginUser() async {
    try {
      final url = Uri.parse('$API_BASE_URL/login');
      print('Attempting to connect to: $url'); // Debug URL

      final response = await http
          .post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json", // Add this header
        },
        body: json.encode({
          'email': _email,
          'password': _password,
        }),
      )
          .timeout(
        const Duration(seconds: 30), // Increase timeout
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your internet connection.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String userType = data['user']['user_type'];
        final int userId = data['user']['id'];

        globalUserId = userId;

        showSnackbarMessage(context, "Login successful!", true);

        // Navigate to dashboard based on user type
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Login failed';
        showSnackbarMessage(context, errorMessage, false);
      }
    } on SocketException catch (e) {
      print('Socket Error: $e');
      showSnackbarMessage(context,
          'Connection error. Please check your internet and server.', false);
    } on TimeoutException catch (e) {
      print('Timeout Error: $e');
      showSnackbarMessage(
          context, 'Connection timed out. Please try again.', false);
    } catch (e) {
      print('General Error: $e');
      showSnackbarMessage(context, 'An error occurred: $e', false);
    }
  }

  void showSnackbarMessage(BuildContext context, String message, bool success) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: success ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/gym.jpg', // Add your background image here
              fit: BoxFit.cover,
            ),
          ),
          if (_connectionStatus.isNotEmpty)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _connectionStatus,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Column(
            children: [
              const Spacer(), // Push the content to the bottom
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(25.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95), // Opaque background
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 16),

                        // Email Field
                        const Text(
                          'Email Address',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter email address',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color:
                                      Colors.grey), // Set border color to grey
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _email = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        const Text(
                          'Password',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter Password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText:
                              !_passwordVisible, // Toggle password visibility
                          onChanged: (value) {
                            setState(() {
                              _password = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Login Button
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.black, // Black for button
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      loginUser();
                                    }
                                  },
                                  child: const Text('LOG IN',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white)),
                                ),
                              ),
                        const SizedBox(height: 16),

                        // Register Now Text
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, '/register');
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: 'Register now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Add space at the bottom
            ],
          ),
        ],
      ),
    );
  }
}
