import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'blockchain_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String userBoxName = 'userBox';

  // Sign Up with Blockchain Hash Storage
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
        // Store registration hash on Ethereum blockchain
        String? blockchainHashId;
        try {
          final blockchainResult = await BlockchainService.storeRegistration(
            userId: user.uid,
            email: email,
            phone: phone,
            name: name,
          );
          
          if (blockchainResult.success) {
            blockchainHashId = blockchainResult.hashId;
            print('[Auth] Registration recorded on blockchain: ${blockchainResult.hashId}');
            print('[Auth] Transaction hash: ${blockchainResult.txHash}');
            print('[Auth] Block number: ${blockchainResult.blockNumber}');
          } else {
            print('[Auth] Blockchain registration failed: ${blockchainResult.error}');
            // Continue with registration even if blockchain fails
          }
        } catch (e) {
          print('[Auth] Blockchain error (non-fatal): $e');
          // Continue with registration even if blockchain is unavailable
        }

        // Save to Firestore with blockchain hash
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'createdAt': DateTime.now(),
          'avatar': 'https://i.pravatar.cc/150?u=$email',
          'country': 'India',
          'memberSince': DateTime.now().toString(),
          'blockchainHashId': blockchainHashId,
          'blockchainRegistered': blockchainHashId != null,
        });

        // Save locally
        final box = Hive.box(userBoxName);
        await box.put('currentUser', {
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'blockchainHashId': blockchainHashId,
        });

        return true;
      }
      return false;
    } catch (e) {
      print('Sign Up Error: $e');
      return false;
    }
  }

  // Login with Blockchain Hash Storage
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
        // Store login hash on Ethereum blockchain
        String? loginHashId;
        try {
          final blockchainResult = await BlockchainService.storeLogin(
            userId: user.uid,
            deviceId: 'flutter_${DateTime.now().millisecondsSinceEpoch}',
          );
          
          if (blockchainResult.success) {
            loginHashId = blockchainResult.hashId;
            print('[Auth] Login recorded on blockchain: ${blockchainResult.hashId}');
            print('[Auth] Transaction hash: ${blockchainResult.txHash}');
          } else {
            print('[Auth] Blockchain login failed: ${blockchainResult.error}');
            // Continue with login even if blockchain fails
          }
        } catch (e) {
          print('[Auth] Blockchain error (non-fatal): $e');
          // Continue with login even if blockchain is unavailable
        }

        // Get user data from Firestore
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        // Update last login hash in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': DateTime.now(),
          'lastLoginBlockchainHash': loginHashId,
        });

        // Save locally
        final box = Hive.box(userBoxName);
        await box.put('currentUser', userData);
        await box.put('authToken', user.uid);
        await box.put('lastLoginHash', loginHashId);

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
