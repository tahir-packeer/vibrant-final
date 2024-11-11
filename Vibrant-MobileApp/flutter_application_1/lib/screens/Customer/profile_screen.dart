import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:battery_plus/battery_plus.dart'; // Battery package
import 'package:image_picker/image_picker.dart'; // Image picker package
import 'package:provider/provider.dart';
import '../../custom_colors.dart';
import '../../global.dart';
import '../../theme_provider.dart';
import '../login.dart'; // Import the login screen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isLoading = true;
  bool isEditing = false;
  bool isSubmitting = false;

  File? _profileImage;
  CameraController? _cameraController;
  Map<String, dynamic>? userProfile;

  // Battery related
  final Battery _battery = Battery();
  int _batteryLevel = 0;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _getBatteryLevel();
  }

  Future<void> fetchUserProfile() async {
    final String apiUrl = "$API_BASE_URL/user/$globalUserId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final profileData = json.decode(response.body)['user'];
        setState(() {
          userProfile = profileData;
          nameController.text = profileData['name'];
          emailController.text = profileData['email'];

          if (profileData['profile_image'] != null &&
              profileData['profile_image'].isNotEmpty) {
            _profileImage = File(profileData['profile_image']);
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (error) {
      print("Error fetching user profile: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateUserProfile() async {
    setState(() {
      isSubmitting = true;
    });

    String? base64Image;
    if (_profileImage != null) {
      base64Image = await _convertImageToBase64(_profileImage!);
    }

    final String updateUrl = "$API_BASE_URL/users/update/$globalUserId";
    try {
      final response = await http.put(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "name": nameController.text,
          "email": emailController.text,
          "profile_image":
              base64Image, // Include Base64 image string in the request
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json.decode(response.body)['message'])),
        );
        setState(() {
          isEditing = false;
          userProfile = json.decode(response.body)['user'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (error) {
      print("Error updating user profile: $error");
    }

    setState(() {
      isSubmitting = false;
    });
  }

  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("Error converting image to Base64: $e");
      return null;
    }
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    setState(() {
      _batteryLevel = level;
    });
  }

  // Open gallery to select image
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Save the image to local storage
      await _saveImageToFile(image);
    }
  }

  // Open camera to capture image
  Future<void> _captureImageFromCamera() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        // Save the image to local storage
        await _saveImageToFile(image);
      }
    } else {
      print("Camera permission denied");
    }
  }

  Future<void> _saveImageToFile(XFile imageFile) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Define a unique file name, for example, based on timestamp
      final fileName = path.basename(imageFile.path); // Extract filename
      final filePath =
          path.join(directory.path, fileName); // Create full file path

      // Copy the file to the app's documents directory
      final savedImage = await File(imageFile.path).copy(filePath);

      // Set the saved image path as the profile image
      setState(() {
        _profileImage = savedImage;
      });

      print('Image saved to: $filePath');
    } catch (e) {
      print('Error saving image: $e');
    }
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            color: theme.appBarTheme.foregroundColor,
            onPressed: () {
              if (isEditing) {
                updateUserProfile(); // Call the update function
              } else {
                setState(() {
                  isEditing = true; // Enable editing mode
                });
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        _showImageSourceDialog(context);
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? (_profileImage!.existsSync()
                                ? FileImage(_profileImage!)
                                : NetworkImage(
                                    "http://10.0.2.2:8000${userProfile!['profile_image']}"))
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 28,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Name",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: nameController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Email",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: emailController,
                    enabled: isEditing,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "User Type: ${userProfile!['user_type']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Joined: ${userProfile!['created_at']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.battery_full),
                      const SizedBox(width: 10),
                      Text("Battery Level: $_batteryLevel%"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isEditing)
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              updateUserProfile();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSubmitting
                          ? CircularProgressIndicator()
                          : Text("Save Changes"),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme
                            .cardTheme.color, // Change color based on theme
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "LOG OUT",
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        title: const Text(
          "Select Image Source",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureImageFromCamera();
            },
            child: const Text(
              "Camera",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: const Text(
              "Gallery",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
