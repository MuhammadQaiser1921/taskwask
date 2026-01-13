import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';


/// NOTE:
/// - dart:io is NOT supported on Web
/// - File upload must be handled differently on Web
class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// GoogleSignIn is ONLY for mobile
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const String _lastLoginKey = 'last_login_date';
  static const int _loginValidDays = 10;

  // ===============================
  // BASIC AUTH
  // ===============================

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // ===============================
  // SESSION HANDLING
  // ===============================

  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginString = prefs.getString(_lastLoginKey);

    if (lastLoginString == null) return false;

    final lastLogin = DateTime.parse(lastLoginString);
    final days = DateTime.now().difference(lastLogin).inDays;

    return days < _loginValidDays;
  }

  Future<void> _saveLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastLoginKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _clearLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginKey);
  }

  // ===============================
  // EMAIL AUTH
  // ===============================

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveLoginTimestamp();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveLoginTimestamp();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ===============================
  // GOOGLE SIGN-IN (WEB + MOBILE)
  // ===============================

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // ✅ WEB: Use Firebase popup
        final googleProvider = GoogleAuthProvider();
        final credential =
            await _firebaseAuth.signInWithPopup(googleProvider);
        await _saveLoginTimestamp();
        return credential;
      } else {
        // ✅ MOBILE: Use google_sign_in
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google sign-in cancelled');
        }

        final googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await _firebaseAuth.signInWithCredential(credential);

        await _saveLoginTimestamp();
        return userCredential;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ===============================
  // SIGN OUT
  // ===============================

  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }

    await _clearLoginTimestamp();
  }

  // ===============================
  // PASSWORD & ACCOUNT
  // ===============================

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user logged in');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      await user.delete();
      await _clearLoginTimestamp();
    }
  }

  // ===============================
  // PROFILE UPDATE (NO dart:io)
  // ===============================

  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      await user.reload();
    }
  }

  // ===============================
// PROFILE IMAGE UPLOAD (WEB + MOBILE)
// ===============================

Future<String> uploadProfilePictureBytes(Uint8List imageBytes) async {
  final user = currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  try {
    debugPrint('Starting profile picture upload for user: ${user.uid}');
    
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child('${user.uid}.jpg');

    debugPrint('Uploading image data...');
    final uploadTask = await storageRef.putData(
      imageBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    debugPrint('Getting download URL...');
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    debugPrint('Updating user profile with photo URL...');
    // Update Firebase Auth profile photo
    await updateUserProfile(photoURL: downloadUrl);

    debugPrint('Profile picture upload complete: $downloadUrl');
    return downloadUrl;
  } catch (e) {
    debugPrint('Profile picture upload error: $e');
    throw Exception('Failed to upload profile picture: ${e.toString()}');
  }
}


  // ===============================
  // ERROR HANDLING
  // ===============================

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'user-not-found':
        return 'Account not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'Account disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try later';
      case 'operation-not-allowed':
        return 'Sign-in method not enabled';
      case 'invalid-credential':
        return 'Invalid credentials';
      case 'network-request-failed':
        return 'Network error';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
