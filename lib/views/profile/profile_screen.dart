// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/language_provider.dart';
import 'support_screen.dart';
import 'feedback_dialog.dart';
import '../layout/desktop_navbar.dart';
import '../favorites/favorites_screen.dart';
import '../settings/language_selection_screen.dart';

// import '../layout/mobile_navbar.dart';
import '../layout/custom_app_bar.dart';
// IMPORTS FOR PROFILE UPLOAD & SETTINGS
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import '../settings/account_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool isAdminView;
  const ProfileScreen(
      {super.key,
      this.showBackButton = false,
      this.onBack,
      this.isAdminView = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // To force refresh after upload
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final themeController = Provider.of<ThemeController>(context);
    final user = Provider.of<User?>(context);
    final lp = Provider.of<LanguageProvider>(context);

    if (user == null) {
      return Center(
        child: Text(
          lp.translate('no_account'),
          style: const TextStyle(fontFamily: 'Inter', color: Colors.grey),
        ),
      );
    }

    // Check for desktop
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return FutureBuilder<DocumentSnapshot>(
      // Key changes to force rebuild
      key: ValueKey(_refreshKey),
      future: firestoreService.getUserData(user.uid),
      builder: (context, snapshot) {
        String name = user.displayName ?? "Traveller";
        String email = user.email ?? "No Email";
        String phone = user.phoneNumber ?? "No Phone Linked";
        String role = "Customer";
        String initial = name.isNotEmpty ? name[0].toUpperCase() : "T";
        String? photoUrl = user.photoURL;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          // Use 'displayName' or 'name' (legacy)
          name = data['displayName'] ?? data['name'] ?? name;
          email = data['email'] ?? email;
          // Use 'phoneNumber' or 'phone' (legacy)
          phone = data['phoneNumber'] ?? data['phone'] ?? phone;
          role = (data['role'] ?? "Customer").toString().toUpperCase();
          // Use Firestore photoURL if available, else user.photoURL
          if (data['photoURL'] != null &&
              data['photoURL'].toString().isNotEmpty) {
            photoUrl = data['photoURL'];
          }
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: isDesktop
              ? null
              : CustomAppBar(
                  automaticallyImplyLeading: widget.showBackButton,
                  leading: widget.showBackButton
                      ? BackButton(
                          onPressed: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        )
                      : null,
                ),
          // bottomNavigationBar:
          //    isDesktop ? null : const MobileBottomNav(selectedIndex: 3),
          body: Column(
            children: [
              if (isDesktop)
                Material(
                  elevation: 4,
                  child: DesktopNavBar(
                      selectedIndex: 3, isAdminView: widget.isAdminView),
                ), // Profile is index 3
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // PROFILE PICTURE
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () async {
                                      debugPrint("Profile Avatar Clicked");
                                      await _pickAndUploadImage(context, user);
                                    },
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 60,
                                          backgroundColor: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                          backgroundImage: (photoUrl != null)
                                              ? NetworkImage(photoUrl)
                                              : null,
                                          child: (photoUrl == null)
                                              ? Text(
                                                  initial,
                                                  style: const TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(Icons.edit,
                                              size: 20, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    role,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Divider(),
                                const SizedBox(height: 16),
                                _infoRow(context, Icons.email_outlined,
                                    lp.translate('email'), email),
                                _infoRow(context, Icons.phone_outlined,
                                    lp.translate('phone_label'), phone),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    secondary: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.dark_mode,
                                          color: Colors.purple),
                                    ),
                                    value: themeController.themeMode ==
                                        ThemeMode.dark,
                                    title: Text(
                                      lp.translate('dark_mode'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    activeTrackColor: AppTheme.primaryColor,
                                    onChanged: (val) {
                                      themeController.setTheme(val
                                          ? ThemeMode.dark
                                          : ThemeMode.light);
                                    },
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.blue),
                                    ),
                                    title: Text(
                                      lp.translate('notifications'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Switch(
                                      value: true,
                                      activeTrackColor: AppTheme.primaryColor,
                                      onChanged: (v) {},
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.green.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.language,
                                          color: Colors.green),
                                    ),
                                    title: Text(
                                      lp.translate('language'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: Text(lp.currentLanguageName,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LanguageSelectionScreen()));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.person,
                                          color: Colors.blue),
                                    ),
                                    title: const Text(
                                      "Account Settings",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: const Text(
                                        "Name, Phone, Linked Accounts",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    trailing: const Icon(Icons.chevron_right,
                                        size: 18, color: Colors.grey),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AccountSettingsScreen())),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.favorite,
                                          color: Colors.red),
                                    ),
                                    title: const Text(
                                      "My Favourites",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: const Icon(Icons.chevron_right,
                                        size: 18, color: Colors.grey),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const FavoritesScreen())),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.support_agent,
                                          color: Colors.orange),
                                    ),
                                    title: Text(
                                      lp.translate('help_support'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: const Icon(Icons.chevron_right,
                                        size: 18, color: Colors.grey),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const SupportScreen())),
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.rate_review,
                                          color: Colors.blue),
                                    ),
                                    title: const Text(
                                      "Send Feedback",
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600),
                                    ),
                                    trailing: const Icon(Icons.chevron_right,
                                        size: 18, color: Colors.grey),
                                    onTap: () {
                                      showDialog(
                                          context: context,
                                          builder: (_) =>
                                              const FeedbackDialog());
                                    },
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.logout,
                                          color: Colors.red),
                                    ),
                                    title: Text(
                                      lp.translate('log_out'),
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red),
                                    ),
                                    onTap: () => authService.signOut(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            "${lp.translate('version')} 1.0.0",
                            style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey.shade400,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, User user) async {
    // 1. Pick Image
    XFile? image;
    try {
      debugPrint("Starting image picker...");
      final ImagePicker picker = ImagePicker();
      image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Optimization
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) {
        debugPrint("No image picked");
        return;
      }
      debugPrint("Image picked: ${image.path}");
    } catch (e) {
      debugPrint("Error picking image: $e");
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading image... please wait.")));

    try {
      // 2. Upload to Firebase Storage
      debugPrint("Creating storage ref...");
      final storageRef =
          FirebaseStorage.instance.ref().child('user_profiles/${user.uid}.jpg');

      debugPrint("Reading bytes...");
      final bytes = await image.readAsBytes();
      debugPrint("Read ${bytes.length} bytes.");

      debugPrint("Starting upload...");
      if (kIsWeb) {
        await storageRef.putData(
            bytes,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'picked-file-path': image.path},
            ));
      } else {
        // Add metadata to file upload too
        await storageRef.putFile(
            File(image.path),
            SettableMetadata(
              contentType: 'image/jpeg',
            ));
      }
      debugPrint("Upload complete. Getting URL...");

      // Retry logic for getDownloadURL to avoid race conditions
      String? downloadUrl;
      for (int i = 0; i < 3; i++) {
        try {
          downloadUrl = await storageRef.getDownloadURL();
          break;
        } catch (e) {
          debugPrint("Attempt ${i + 1} to get URL failed: $e");
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (downloadUrl == null) {
        throw Exception("Could not retrieve download URL after upload.");
      }

      debugPrint("Download URL: $downloadUrl");

      // 3. Update Firestore & Auth
      debugPrint("Updating Firestore...");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoURL': downloadUrl});

      debugPrint("Updating Auth...");
      await user.updatePhotoURL(downloadUrl);

      // FORCE REFRESH
      debugPrint("Upload sequence finished successfully.");
      if (context.mounted) {
        setState(() {
          _refreshKey++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated!")));
      }
    } catch (e) {
      debugPrint("Upload Error detected: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      }
    }
  }
}
