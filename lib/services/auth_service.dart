// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Required for Firebase.initializeApp
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'cache_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance; // Instance

  AuthService(); // Constructor is now empty

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // This is now correctly called from main.dart *before* runApp
  Future<void> initializeGoogleSignIn() {
    return _googleSignIn.initialize();
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        // --- WEB FLOW ---
        // This is correct. Web uses Firebase's popup.
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // --- MOBILE FLOW (Android/iOS) ---
        // 1. *** THIS IS THE FIX ***
        // As your guides correctly pointed out, v7 uses 'authenticate()'.
        GoogleSignInAccount? googleUser;
        try {
          googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);
        } catch (e) {
          rethrow;
        }

        final GoogleSignInClientAuthorization? authorization =
            await googleUser.authorizationClient.authorizationForScopes(
          ['email', 'profile'],
        );

        if (authorization == null) {
          if (!context.mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Authorization failed")),
          );
          return null;
        }

        // This is also correct (no 'await')
        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // --- COMMON LOGIC: Create user doc if new ---
      final user = userCredential.user;
      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'role': 'customer', // Default role
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Ensure doc exists even for returning users (Self-healing)
          await _ensureUserDocument(user);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        errorMessage = "Sign-in was cancelled.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      debugPrint('Firebase Auth Error: ${e.code}');
      return null;
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
      debugPrint('Sign-in error: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithApple(BuildContext context) async {
    debugPrint("--- Apple Sign-In Started ---");
    try {
      final appleProvider = OAuthProvider("apple.com");
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      debugPrint("Triggering signInWithPopup...");
      final userCredential = await _auth.signInWithPopup(appleProvider);
      debugPrint("Popup success: ${userCredential.user?.uid}");

      final user = userCredential.user;

      if (user != null) {
        await _ensureUserDocument(user);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error (Apple): ${e.code} - ${e.message}");
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Apple sign in failed: ${e.message}")),
      );
      return null;
    } catch (e) {
      debugPrint("General Error (Apple): $e");
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error: $e")),
      );
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail(BuildContext context, String email,
      String password, String? phoneNumber) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'phoneNumber': phoneNumber, // Save phone number
          'role': 'customer', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign up failed: ${e.message}")));
      return null;
    }
  }

  // --- LINKING ACCOUNTS ---

  Future<UserCredential?> linkWithGoogle(BuildContext context) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      // 1. Get Google Credential (same logic as signIn)
      OAuthCredential? credential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // For linking, we use linkWithPopup
        return await user.linkWithPopup(googleProvider);
      } else {
        // Mobile Flow (Android/iOS) - standard Google Sign In
        // Use authenticate() as per v7
        final GoogleSignInAccount googleUser =
            await _googleSignIn.authenticate(scopeHint: ['email', 'profile']); // Cancelled

        // Get Authorization for Access Token
        final GoogleSignInClientAuthorization? authorization =
            await googleUser.authorizationClient.authorizationForScopes(
          ['email', 'profile'],
        );

        if (authorization == null) {
          throw FirebaseAuthException(
              code: 'auth-failed', message: 'Authorization failed');
        }

        // Get Authentication for ID Token
        final GoogleSignInAuthentication googleAuth =
            googleUser.authentication;

        credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleAuth.idToken,
        );

        return await user.linkWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;
      String msg = "Linking failed: ${e.message}";
      if (e.code == 'credential-already-in-use') {
        msg = "This Google account is already linked to another user.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return null;
    } catch (e) {
      debugPrint("Link Error: $e");
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _ensureUserDocument(credential.user!);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign in failed: ${e.message}")));
      return null;
    }
  }

  // --- PHONE AUTHENTICATION METHODS ---

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    if (kIsWeb) {
      // --- WEB SPECIFIC LOGIC ---
      try {
        // Use visible recaptcha via invisible flow (standard)
        final ConfirmationResult result =
            await _auth.signInWithPhoneNumber(phoneNumber);

        debugPrint(
            "Web Phone Auth: Code sent successfully. VerificationID: ${result.verificationId}");
        codeSent(result.verificationId, null);
      } on FirebaseAuthException catch (e) {
        debugPrint(
            "Web Phone Auth FirebaseAuthException: ${e.code} - ${e.message}");
        verificationFailed(e);
      } catch (e) {
        debugPrint("Web Phone Auth Generic Error: $e");
        String msg = "Web auth failed: $e";
        if (e.toString().contains("internal-error")) {
          msg =
              "Firebase internal error. Check authorized domains (localhost/vercel) in Console.";
        } else if (e.toString().contains("billing-not-enabled")) {
          msg =
              "Google requires a Billing Account for Phone Auth (even for free tier). Please link a card in Google Cloud Console.";
        }
        verificationFailed(
            FirebaseAuthException(code: 'web-error', message: msg));
      }
    } else {
      // --- MOBILE LOGIC ---
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    }
  }

  Future<UserCredential?> signInWithPhoneCredential(
      BuildContext context, PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Ensure user document exists (same logic as Google/Email)
        await _ensureUserDocument(user);
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone Auth failed: ${e.message}")));
      return null;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Anonymous auth failed: $e");
      return null;
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    final docStats = await _db.collection('users').doc(user.uid).get();
    if (!docStats.exists) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'phoneNumber': user.phoneNumber, // Build phoneNumber
        'displayName': user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // If the user logs in via a different method (link phone to existing account??)
      // OR simply just update the phone number if it was missing.
      // For now, let's just update phoneNumber if it's null in DB but present in Auth
      final data = docStats.data();
      if (data != null &&
          (data['phoneNumber'] == null || data['phoneNumber'] == "") &&
          user.phoneNumber != null) {
        await _db
            .collection('users')
            .doc(user.uid)
            .update({'phoneNumber': user.phoneNumber});
      }
    }
  }

  Future<void> registerUserAsAdmin({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Initialize a secondary app instance
      // We need to use the same options as the default app
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      // 2. Get Auth instance for this secondary app
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 3. Create the user (this logs them in ONLY on the secondary auth instance)
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // 4. Create the Firestore document using the MAIN app's Firestore instance
        // (We use the main instance because the admin is authenticated there and has permissions)
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Optional: Update the user's profile on the Auth object too
        await user.updateDisplayName(displayName);
      }

      // 5. Cleanup
      await secondaryAuth.signOut();
    } catch (e) {
      debugPrint("Error creating user as admin: $e");
      rethrow;
    } finally {
      // Always delete the secondary app to free resources
      await secondaryApp?.delete();
    }
  }

  Future<void> signOut() async {
    await CacheService().clearUserProfile();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
