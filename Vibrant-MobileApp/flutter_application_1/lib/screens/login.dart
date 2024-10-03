import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart'; // Import the connectivity package
import '../global.dart'; // import the global variables
import './Customer/customerDashboard.dart'; // import the CustomerDashboard page
import './Admin/adminDashboard.dart'; // import the AdminDashboard page

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  bool _passwordVisible = false; // Visibility toggle for password
  String _connectionStatus = 'Unknown'; // To display the connection status
  late Connectivity _connectivity;
  late Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;

    _checkConnectivity();

    _connectivityStream.listen((List<ConnectivityResult> resultList) {
      if (resultList.isNotEmpty) {
        _updateConnectionStatus(resultList.first);
      } else {
        _updateConnectionStatus(ConnectivityResult.none);
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result as ConnectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    String status;
    if (result == ConnectivityResult.mobile) {
      status = 'Mobile Data';
    } else if (result == ConnectivityResult.wifi) {
      status = 'WiFi';
    } else {
      status = 'No Internet Connection';
    }

    setState(() {
      _connectionStatus = status;
    });
  }

  Future<void> loginUser() async {
    if (_connectionStatus == 'No Internet Connection') {
      showSnackbarMessage(context, 'Please check your internet connection.', false);
      return;
    }

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    final url = Uri.parse('${API_BASE_URL}/login');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'email': _email,
        'password': _password,
      }),
    );

    setState(() {
      _isLoading = false; // Hide loading spinner
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String userType = data['user']['user_type'];
      final int userId = data['user']['id'];

      globalUserId = userId;

      showSnackbarMessage(context, "Login successful!", true);

      if (userType == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CustomerDashboard()),
        );
      } else if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      }
    } else {
      final errorMessage = json.decode(response.body)['message'] ?? 'Login failed';
      showSnackbarMessage(context, errorMessage, false);
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
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/gym.jpg', // Add your background image here
              fit: BoxFit.cover,
              //image transparency
            ),
          ),
          Column(
            children: [
              Spacer(), // Push the content to the bottom
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
                        // Email Field
                        Text(
                          'Email Address',
                          style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter email address',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey), // Set border color to grey
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _email = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Password Field
                        Text(
                          'Password',
                          style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Enter Password',
                            hintStyle: TextStyle(color: Colors.grey),
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
                          obscureText: !_passwordVisible, // Toggle password visibility
                          onChanged: (value) {
                            setState(() {
                              _password = value;
                            });
                          },
                        ),
                        SizedBox(height: 16),

                        // Forgot Password Link
                        SizedBox(height: 16),

                        // Login Button
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Black for button
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                loginUser();
                              }
                            },
                            child: Text('LOG IN',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Register Now Text
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                children: [
                                  TextSpan(
                                    text: 'Register now',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.bold,
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
              SizedBox(height: 16), // Add space at the bottom
            ],
          ),
        ],
      ),
    );
  }
}
