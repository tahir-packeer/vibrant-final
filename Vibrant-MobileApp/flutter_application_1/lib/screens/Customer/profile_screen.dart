import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:battery_plus/battery_plus.dart'; // Battery package
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
  late List<CameraDescription> cameras;
  Map<String, dynamic>? userProfile;

  // Battery related
  Battery _battery = Battery();
  int _batteryLevel = 0;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    _initCamera();
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

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  bool isCapturing = false; // Flag to track capture state

  Future<void> _captureImage() async {
    if (isCapturing) {
      // Prevent new capture if one is already in progress
      print("Previous capture has not returned yet.");
      return;
    }

    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          setState(() {
            isCapturing = true; // Mark capture as in progress
          });

          final XFile image = await _cameraController!.takePicture();
          setState(() {
            _profileImage = File(image.path);
          });
        }
      } catch (e) {
        print("Error capturing image: $e");
      } finally {
        setState(() {
          isCapturing = false; // Reset the flag after capture is completed
        });
      }
    } else {
      print("Camera permission denied");
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
                onTap: _captureImage,
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
                      Icons.camera_alt,
                      size: 28,
                      color: Colors.white,
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
                  padding: EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
