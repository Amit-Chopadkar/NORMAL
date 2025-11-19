import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String userBoxName = 'userBox';

  // Sign Up
  static Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Save to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': DateTime.now(),
          'avatar': 'https://i.pravatar.cc/150?u=$email',
          'country': 'India',
          'memberSince': DateTime.now().toString(),
        });

        // Save locally
        final box = Hive.box(userBoxName);
        await box.put('currentUser', {
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Sign Up Error: $e');
      return false;
    }
  }

  // Login
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Save locally
        final box = Hive.box(userBoxName);
        await box.put('currentUser', userData);
        await box.put('authToken', user.uid);

        return true;
      }
      return false;
    } catch (e) {
      print('Login Error: $e');
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      final box = Hive.box(userBoxName);
      await box.delete('currentUser');
      await box.delete('authToken');
    } catch (e) {
      print('Logout Error: $e');
    }
  }

  // Get current user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Get Current User Error: $e');
      return null;
    }
  }

  // Update profile
  static Future<bool> updateProfile({
    required String name,
    required String phone,
    required String country,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'phone': phone,
          'country': country,
          'updatedAt': DateTime.now(),
        });

        // Update local
        final box = Hive.box(userBoxName);
        Map<String, dynamic> userData = box.get('currentUser') ?? {};
        userData['name'] = name;
        userData['phone'] = phone;
        userData['country'] = country;
        await box.put('currentUser', userData);

        return true;
      }
      return false;
    } catch (e) {
      print('Update Profile Error: $e');
      return false;
    }
  }

  // Check if logged in
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get auth token
  static String? getAuthToken() {
    return _auth.currentUser?.uid;
  }
}
