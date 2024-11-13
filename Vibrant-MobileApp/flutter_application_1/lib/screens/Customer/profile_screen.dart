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
import '../../providers/theme_provider.dart';
import '../login.dart'; // Import the login screen

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdate;

  const ProfileScreen({super.key, this.onProfileUpdate});

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

  bool isPersonalInfoExpanded = false;
  bool isAccountInfoExpanded = false;
  bool isSettingsExpanded = false;

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
          "profile_image": base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        setState(() {
          isEditing = false;
          userProfile = responseData['user'];
          print(
              "Updated profile image: ${userProfile!['profile_image']}"); // Debug print
        });

        // Call the callback to refresh the profile image in dashboard
        widget.onProfileUpdate?.call();
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
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    // Reset and reload profile data
    setState(() {
      isLoading = true;
    });
    await fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit),
            color: isDarkMode ? Colors.white : Colors.black,
            onPressed: () {
              if (isEditing) {
                updateUserProfile();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(context).appBarTheme.backgroundColor
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: isEditing
                          ? () => _showImageSourceDialog(context)
                          : null,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: userProfile != null &&
                                      userProfile!['profile_image'] != null &&
                                      userProfile!['profile_image']
                                          .toString()
                                          .isNotEmpty
                                  ? NetworkImage(
                                      "http://192.168.8.78:8000${userProfile!['profile_image']}")
                                  : const AssetImage(
                                          'assets/default_profile.png')
                                      as ImageProvider,
                              child: userProfile == null ||
                                      userProfile!['profile_image'] == null ||
                                      userProfile!['profile_image']
                                          .toString()
                                          .isEmpty
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          if (isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      nameController.text,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      emailController.text,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          isPersonalInfoExpanded = !isPersonalInfoExpanded;
                        });
                      },
                      child: _buildInfoCard(
                        "Personal Information",
                        [
                          if (isPersonalInfoExpanded) ...[
                            _buildTextField(
                              "Name",
                              nameController,
                              isEditing,
                              Icons.person,
                              isDarkMode,
                            ),
                            const SizedBox(height: 15),
                            _buildTextField(
                              "Email",
                              emailController,
                              isEditing,
                              Icons.email,
                              isDarkMode,
                            ),
                          ],
                        ],
                        isDarkMode,
                        isExpanded: isPersonalInfoExpanded,
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () {
                        setState(() {
                          isAccountInfoExpanded = !isAccountInfoExpanded;
                        });
                      },
                      child: _buildInfoCard(
                        "Account Information",
                        [
                          if (isAccountInfoExpanded) ...[
                            _buildInfoRow(
                              "User Type",
                              userProfile!['user_type'],
                              Icons.badge,
                              isDarkMode,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Joined",
                              userProfile!['created_at'],
                              Icons.calendar_today,
                              isDarkMode,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              "Battery Level",
                              "$_batteryLevel%",
                              Icons.battery_full,
                              isDarkMode,
                            ),
                          ],
                        ],
                        isDarkMode,
                        isExpanded: isAccountInfoExpanded,
                      ),
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () {
                        setState(() {
                          isSettingsExpanded = !isSettingsExpanded;
                        });
                      },
                      child: _buildInfoCard(
                        "Settings",
                        [
                          if (isSettingsExpanded)
                            _buildSettingsRow(
                              "Dark Mode",
                              Icons.dark_mode,
                              isDarkMode,
                              Switch(
                                value: Provider.of<ThemeProvider>(context)
                                    .isDarkMode,
                                onChanged: (value) {
                                  Provider.of<ThemeProvider>(context,
                                          listen: false)
                                      .toggleTheme();
                                },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ),
                        ],
                        isDarkMode,
                        isExpanded: isSettingsExpanded,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isEditing)
                      ElevatedButton(
                        onPressed: isSubmitting ? null : updateUserProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 30,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "LOG OUT",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  Widget _buildInfoCard(String title, List<Widget> children, bool isDarkMode,
      {bool isExpanded = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ],
          ),
          if (children.isNotEmpty) ...[
            const SizedBox(height: 15),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool enabled,
    IconData icon,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
        ),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(
    String label,
    IconData icon,
    bool isDarkMode,
    Widget trailing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        trailing,
      ],
    );
  }
}
