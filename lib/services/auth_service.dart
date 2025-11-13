// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // In v7, GoogleSignIn must be accessed through instance and initialized
  GoogleSignInAccount? _googleUser;
  
  // Getters for auth state
  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  GoogleSignInAccount? get googleUser => _googleUser;

  // Initialize GoogleSignIn - call this in main.dart
  Future<void> initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize();
      
      // Listen to authentication events
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _googleUser = event.user;
            break;
          case GoogleSignInAuthenticationEventSignOut():
            _googleUser = null;
            break;
          default:
            _googleUser = null;
        }
      });
    } catch (e) {
      debugPrint('Error initializing Google Sign-In: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      // Step 1: Trigger the authentication flow
      await GoogleSignIn.instance.authenticate();
      
      // Step 2: Get the signed-in user from the authentication events
      // The _googleUser will be set by the authentication event listener
      if (_googleUser == null) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign-in was cancelled")),
        );
        return null;
      }

      // Step 3: Get authorization for required scopes
      final GoogleSignInClientAuthorization? authorization = 
          await _googleUser!.authorizationClient.authorizationForScopes(
        ['email', 'profile'],
      );

      if (authorization == null) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authorization failed")),
        );
        return null;
      }

      // Step 4: Get the ID token
      final GoogleSignInAuthentication googleAuth = await _googleUser!.authentication;

      // Step 5: Create credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Step 6: Sign in to Firebase
      return await _auth.signInWithCredential(credential);
      
    } on GoogleSignInException catch (e) {
      if (!context.mounted) return null;
      
      String errorMessage = 'Error signing in with Google';
      switch (e.code.name) {
        case 'canceled':
          errorMessage = 'Sign-in was cancelled';
          break;
        case 'interrupted':
          errorMessage = 'Sign-in was interrupted';
          break;
        case 'clientConfigurationError':
          errorMessage = 'Configuration error. Please check Firebase setup and SHA-1';
          break;
        case 'platformError':
          errorMessage = 'Platform error. Check your google-services.json file';
          break;
        default:
          errorMessage = 'Error: ${e.code.name}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      debugPrint('Google Sign-In Error: ${e.code.name}');
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
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}