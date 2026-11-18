import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // LOAD LOGGED-IN USER DATA
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('current_user_id');

      if (userId == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      final userData = await DatabaseHelper.instance.getUserById(userId);

      if (!mounted) return;

      setState(() {
        user = userData;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('PROFILE LOAD ERROR: $e');

      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // SELECT PROFILE IMAGE
  Future<void> selectProfileImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1000,
      );

      if (pickedImage == null) return;

      final userId = user?['id'] as int?;

      if (userId == null) return;

      // SAVE IMAGE PERMANENTLY
      final directory = await getApplicationDocumentsDirectory();

      final extension = pickedImage.path.contains('.')
          ? pickedImage.path.split('.').last
          : 'jpg';

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

      final savedImage = await File(
        pickedImage.path,
      ).copy('${directory.path}/$fileName');

      // SAVE IMAGE PATH IN SQLITE
      await DatabaseHelper.instance.updateUserProfileImage(
        userId,
        savedImage.path,
      );

      await loadUserData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      debugPrint('PROFILE IMAGE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update profile picture.')),
      );
    }
  }

  // GALLERY AND CAMERA OPTIONS
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    selectProfileImage(ImageSource.gallery);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    selectProfileImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // LOGOUT FUNCTION
  Future<void> logoutUser(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,

          title: const Text('Logout', style: TextStyle(color: Colors.white)),

          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('current_user_id');

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = user?['name'] ?? 'User Name';
    final userEmail = user?['email'] ?? 'Email not available';

    final imagePath = user?['profile_image_path'] as String?;

    final hasProfileImage = imagePath != null && File(imagePath).existsSync();

    return Scaffold(
      backgroundColor: AppColors.background,

      // APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),

      // BODY
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),

                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // PROFILE PICTURE
                    GestureDetector(
                      onTap: showImageOptions,

                      child: Stack(
                        children: [
                          Container(
                            height: 115,
                            width: 115,

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cardBackground,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),

                            child: ClipOval(
                              child: hasProfileImage
                                  ? Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                      width: 115,
                                      height: 115,
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 65,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ),

                          // CAMERA ICON
                          Positioned(
                            bottom: 0,
                            right: 0,

                            child: Container(
                              padding: const EdgeInsets.all(7),

                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.background,
                                  width: 2,
                                ),
                              ),

                              child: const Icon(
                                Icons.camera_alt,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // USER NAME
                    Text(
                      userName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    // USER EMAIL
                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // FULL NAME CARD
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      title: 'Full Name',
                      value: userName,
                    ),

                    const SizedBox(height: 15),

                    // EMAIL CARD
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email Address',
                      value: userEmail,
                    ),

                    const SizedBox(height: 15),

                    // ACCOUNT CARD
                    _buildInfoCard(
                      icon: Icons.security_outlined,
                      title: 'Account',
                      value: 'Personal Account',
                    ),

                    const SizedBox(height: 60),

                    // SMALL THEME-BASED LOGOUT BUTTON
                    SizedBox(
                      width: 185,
                      height: 50,

                      child: OutlinedButton.icon(
                        onPressed: () => logoutUser(context),

                        icon: const Icon(Icons.logout_rounded, size: 19),

                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.cardBackground,

                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.2,
                          ),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // PROFILE INFORMATION CARD
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 27),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
