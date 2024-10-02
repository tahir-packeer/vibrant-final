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
  late Stream<List<ConnectivityResult>> _connectivityStream; // Updated to List<ConnectivityResult>

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged; // Correct stream assignment

    // Check the initial connection status
    _checkConnectivity();

    // Listen to connectivity changes
    _connectivityStream.listen((List<ConnectivityResult> resultList) {
      if (resultList.isNotEmpty) {
        // We take the first result as the current network state
        _updateConnectionStatus(resultList.first);
      } else {
        _updateConnectionStatus(
            ConnectivityResult.none); // No connection if the list is empty
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
      showSnackbarMessage(
          context, 'Please check your internet connection.', false);
      return;
    }

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    final url = Uri.parse('${API_BASE_URL}/login'); // Use the global API base URL

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

      // Store the user_id globally for access across pages
      globalUserId = userId;

      // Show a success message
      showSnackbarMessage(context, "Login successful!", true);

      // Navigate based on user type
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
      final errorMessage =
          json.decode(response.body)['message'] ?? 'Login failed';
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
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'CustomTeez',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Changed to white for better contrast
                      ),
                    ),
                    SizedBox(height: 20),

                    // Network Status Display
                    Text(
                      'Network Status: $_connectionStatus',
                      style: TextStyle(
                        fontSize: 16,
                        color: _connectionStatus == 'No Internet Connection'
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Form Box with Background and Rounded Corners
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8), // Slight opacity for form background
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Email',
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            TextFormField(
                              decoration: InputDecoration(
                                hintText: 'Enter email',
                                hintStyle: TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _email = value;
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Password',
                              style: TextStyle(fontSize: 16, color: Colors.black),
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
                            SizedBox(height: 20),
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  Color.fromARGB(255, 121, 60, 158), // Purple color for the button
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
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.white),
                          children: [
                            TextSpan(
                              text: 'Register now',
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
