// lib/views/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_theme.dart' show ThemeController;
import '../../utils/bl_colors.dart';
import '../layout/app_footer.dart';
import '../widgets/bl_widgets.dart';
import '../widgets/language_selector.dart';
//  // Removed
import '../support/support_screen.dart';
import 'feedback_dialog.dart';
import '../layout/desktop_navbar.dart';
import '../favorites/favorites_screen.dart';
import '../../providers/language_provider.dart'; // Added
import 'package:buslink/l10n/app_localizations.dart'; // Added
// import '../settings/language_selection_screen.dart'; // Removed

// import '../layout/mobile_navbar.dart';
// IMPORTS FOR PROFILE UPLOAD & SETTINGS
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// for kIsWeb
import '../settings/account_settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../auth/login_screen.dart';

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

    if (user == null) {
      return const BlEmpty(
          icon: Icons.lock_outline,
          title: 'Please log in to continue',
          message: 'Your trips and favourites are saved to your account.');
    }
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return FutureBuilder<DocumentSnapshot>(
      key: ValueKey(_refreshKey),
      future: firestoreService.getUserData(user.uid),
      builder: (context, snapshot) {
        var name = user.displayName ?? 'Traveller';
        var email = user.email ?? '';
        var role = 'customer';
        String? photoUrl = user.photoURL;
        if (snapshot.hasData && snapshot.data!.exists) {
          final d = snapshot.data!.data() as Map<String, dynamic>;
          name = d['displayName'] ?? d['name'] ?? name;
          email = d['email'] ?? email;
          role = (d['role'] ?? 'customer').toString().toLowerCase();
          if ((d['photoURL'] ?? '').toString().isNotEmpty) {
            photoUrl = d['photoURL'];
          }
        }
        final initials = name
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();
        final dark = themeController.themeMode == ThemeMode.dark;

        Widget avatar = Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BL.blush,
                shape: BoxShape.circle,
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: photoUrl == null
                  ? Text(initials.isEmpty ? '?' : initials,
                      style: const TextStyle(
                          color: BL.crimsonDark,
                          fontSize: 28,
                          fontWeight: FontWeight.w800))
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Semantics(
                button: true,
                label: 'Change profile picture',
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(
                      side: BorderSide(color: BL.crimson, width: 3)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _pickAndUploadImage(context, user),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(Icons.photo_camera_outlined,
                          size: 18, color: BL.crimson),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

        Widget tile(IconData icon, String label, VoidCallback onTap,
                {String? value, Widget? trailing}) =>
            InkWell(
              onTap: onTap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFF0E8E9)))),
                child: Row(
                  children: [
                    Icon(icon, color: BL.crimson, size: 26),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                    ),
                    if (value != null)
                      Text(value,
                          style:
                              const TextStyle(fontSize: 17, color: BL.muted)),
                    trailing ??
                        const Icon(Icons.chevron_right,
                            color: BL.muted, size: 26),
                  ],
                ),
              ),
            );

        void go(Widget w) =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => w));

        final list = Column(
          children: [
            tile(Icons.person_outline, 'Account Settings',
                () => go(const AccountSettingsScreen())),
            tile(Icons.notifications_none, 'Notification Settings',
                () => go(const NotificationSettingsScreen())),
            Consumer<LanguageProvider>(
              builder: (context, lp, _) => tile(
                Icons.language,
                AppLocalizations.of(context)!.selectLanguage,
                () => LanguageSelector.showLanguageDialog(context),
                value: {
                      'si': 'Sinhala',
                      'ta': 'Tamil'
                    }[lp.currentLocale.languageCode] ??
                    'English',
              ),
            ),
            tile(
              Icons.dark_mode_outlined,
              'Dark Mode',
              () => themeController
                  .setTheme(dark ? ThemeMode.light : ThemeMode.dark),
              trailing: Semantics(
                toggled: dark,
                label: dark ? 'Dark mode on' : 'Dark mode off',
                child: ExcludeSemantics(
                  child: Switch(
                    value: dark,
                    activeTrackColor: BL.crimson,
                    onChanged: (v) => themeController
                        .setTheme(v ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
              ),
            ),
            tile(Icons.favorite_border, 'My Favourites',
                () => go(const FavoritesScreen())),
            tile(Icons.help_outline, 'Support & FAQs',
                () => go(const SupportScreen())),
            tile(Icons.chat_bubble_outline, 'Send Feedback', () {
              showDialog(
                  context: context, builder: (_) => const FeedbackDialog());
            }),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _logOut(context, authService),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BL.crimson,
                    side: const BorderSide(color: BL.crimson, width: 2),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        );

        final header = Container(
          color: BL.crimson,
          padding: EdgeInsets.fromLTRB(
              widget.showBackButton ? 8 : 20,
              MediaQuery.paddingOf(context).top + (isDesktop ? 24 : 12),
              20,
              22),
          child: Row(
            children: [
              if (widget.showBackButton)
                IconButton(
                  tooltip: 'Go back',
                  color: Colors.white,
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              avatar,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                    if (email.isNotEmpty)
                      Text(email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                    if (role != 'customer')
                      Text(role == 'admin' ? 'Administrator' : 'Conductor',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        );

        if (!isDesktop) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(children: [
              header,
              Expanded(child: SingleChildScrollView(child: list)),
            ]),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                DesktopNavBar(
                    selectedIndex: 3, isAdminView: widget.isAdminView),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: BL.hairline),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(children: [header, list]),
                        ),
                      ),
                    ),
                  ),
                ),
                const AppFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logOut(BuildContext context, AuthService authService) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const Center(child: CircularProgressIndicator(color: BL.crimson)));
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not log out: $e')));
      }
    }
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

      debugPrint("Starting upload (Universal method)...");
      TaskSnapshot snapshot;

      // Use putData for BOTH Web and Mobile to avoid File path issues on Android
      snapshot = await storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'picked-file-path': image.path},
          ));
      debugPrint("Upload process complete. Getting URL...");

      // Use snapshot.ref to get URL -> safest way
      final downloadUrl = await snapshot.ref.getDownloadURL();

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
