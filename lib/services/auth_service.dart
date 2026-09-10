import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String phone,
    String? address,
    String? city,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final userModel = UserModel(
        uid: credential.user!.uid,
        fullName: fullName,
        email: email,
        phone: phone,
        role: role,
        address: address,
        city: city,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestore());

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with phone (OTP)
  // On Android: Firebase uses Play Integrity / SafetyNet for automatic verification
  // On iOS: Firebase handles reCAPTCHA automatically via APNs
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(PhoneAuthCredential) verificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Called when auto-retrieval times out — user must enter OTP manually
      },
      timeout: const Duration(seconds: 120),
    );
  }

  // Verify OTP code
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Check if user profile exists in Firestore
  Future<bool> userProfileExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // Create user profile after phone auth
  Future<void> createUserProfile({
    required String uid,
    required String fullName,
    required UserRole role,
    required String phone,
    String? email,
    String? address,
    String? city,
  }) async {
    final userModel = UserModel(
      uid: uid,
      fullName: fullName,
      phone: phone,
      email: email,
      role: role,
      address: address,
      city: city,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .set(userModel.toFirestore());
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel userModel) async {
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .update(userModel.toFirestore());
  }
}
