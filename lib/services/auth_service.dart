// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // We need this

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
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.authenticate(scopeHint: ['email']);

        if (googleUser == null) {
          if (!context.mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sign-in was cancelled")),
          );
          return null;
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
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: authorization.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // --- COMMON LOGIC: Create user doc if new ---
      final user = userCredential.user;
      if (user != null &&
          userCredential.additionalUserInfo?.isNewUser == true) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'role': 'customer', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
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

  Future<UserCredential?> signUpWithEmail(
      BuildContext context, String email, String password) async {
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

  Future<UserCredential?> signInWithEmail(
      BuildContext context, String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign in failed: ${e.message}")));
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
