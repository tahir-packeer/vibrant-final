import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:battery_plus/battery_plus.dart'; // Battery package
import 'package:image_picker/image_picker.dart';  // Image picker package
import '../../global.dart';

class ProfileScreen extends StatefulWidget {
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
  Battery _battery = Battery();
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
    final String apiUrl = "${API_BASE_URL}/user/$globalUserId";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final profileData = json.decode(response.body)['user'];
        setState(() {
          userProfile = profileData;
          nameController.text = profileData['name'];
          emailController.text = profileData['email'];

          if (profileData['profile_image'] != null && profileData['profile_image'].isNotEmpty) {
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

    final String updateUrl = "${API_BASE_URL}/users/update/$globalUserId";
    try {
      final response = await http.put(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "name": nameController.text,
          "email": emailController.text,
          "profile_image": base64Image, // Include Base64 image string in the request
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
          SnackBar(content: Text('Failed to update profile')),
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
      final filePath = path.join(directory.path, fileName); // Create full file path

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

  Future<void> _uploadImage(File imageFile) async {
    final String uploadUrl = "${API_BASE_URL}/upload_profile_image/$globalUserId";

    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    // Attach the image file to the request
    request.files.add(await http.MultipartFile.fromPath('profile_image', imageFile.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        print('Image uploaded successfully');
      } else {
        print('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Profile"),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            onPressed: isEditing
                ? () {
              updateUserProfile();
            }
                : () {
              setState(() {
                isEditing = true;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
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
                      : AssetImage('assets/default_profile.png')
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
            SizedBox(height: 20),
            Text(
              "Name",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: nameController,
              enabled: isEditing,
              decoration: InputDecoration(
                hintText: 'Enter your name',
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Email",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: emailController,
              enabled: isEditing,
              decoration: InputDecoration(
                hintText: 'Enter your email',
              ),
            ),
            SizedBox(height: 20),
            Text(
              "User Type: ${userProfile!['user_type']}",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "Joined: ${userProfile!['created_at']}",
              style: TextStyle(fontSize: 16),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.battery_full),
                SizedBox(width: 10),
                Text("Battery Level: $_batteryLevel%"),
              ],
            ),
            SizedBox(height: 20),
            if (isEditing)
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                  updateUserProfile();
                },
                child: isSubmitting
                    ? CircularProgressIndicator()
                    : Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
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
        title: Text("Select Image Source"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _captureImageFromCamera();
            },
            child: Text("Camera"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: Text("Gallery"),
          ),
        ],
      ),
    );
  }
}
