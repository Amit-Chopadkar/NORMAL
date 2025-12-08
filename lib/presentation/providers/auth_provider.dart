import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../services/backend_service.dart';
import '../../services/blockchain_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;
  List<Map<String, String>> _emergencyContacts = [];

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, String>> get emergencyContacts => _emergencyContacts;

  // Registration Data
  String? _registrationType = 'domestic'; // 'domestic' or 'international'
  File? _selectedDocument;

  String? get registrationType => _registrationType;
  File? get selectedDocument => _selectedDocument;

  void setRegistrationType(String type) {
    _registrationType = type;
    _selectedDocument = null; // Reset document when switching type
    notifyListeners();
  }

  void setSelectedDocument(File? file) {
    _selectedDocument = file;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    final contactsData = prefs.getStringList('emergency_contacts');

    if (userData != null) {
      _user = User.fromJson(jsonDecode(userData));
    }

    if (contactsData != null) {
      _emergencyContacts = contactsData
          .map((e) => Map<String, String>.from(jsonDecode(e)))
          .toList();
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      final normalized = _normalizeUserPayload(response['user']);
      _user = User.fromJson(normalized);
      await _saveUserToPrefs(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(data, _selectedDocument);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.verifyOtp(phone, otp);
      final normalized = _normalizeUserPayload(response['user']);
      _user = User.fromJson(normalized);
      await _saveUserToPrefs(_user!);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> syncBlockchainIdentity() async {
    if (_user == null) return false;
    
    try {
      // Try to register on blockchain
      final result = await BlockchainService.storeRegistration(
        userId: _user!.id,
        email: _user!.email,
        phone: _user!.phone,
        name: _user!.name,
      );
      
      if (result.success && result.hashId != null) {
        // Update user with new hash
        final updatedUser = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          phone: _user!.phone,
          userType: _user!.userType,
          nationality: _user!.nationality,
          documentUrl: _user!.documentUrl,
          hashId: _user!.hashId,
          blockchainHashId: result.hashId,
        );
        
        _user = updatedUser;
        await _saveUserToPrefs(_user!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Sync error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _emergencyContacts = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await BackendService.clearCredentials();
    notifyListeners();
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'user_data',
        jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'userType': user.userType,
          'nationality': user.nationality,
          'hashId': user.hashId,
          'blockchainHashId': user.blockchainHashId,
        }));
  }

  Future<void> addEmergencyContact(String name, String phone) async {
    _emergencyContacts.add({'name': name, 'phone': phone});
    final prefs = await SharedPreferences.getInstance();
    final List<String> encodedList =
        _emergencyContacts.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('emergency_contacts', encodedList);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<String, dynamic> _normalizeUserPayload(Map<String, dynamic> raw) {
    return {
      'id': raw['id'] ?? '',
      'name': raw['name'] ?? '',
      'email': raw['email'] ?? '',
      'phone': raw['phone'] ?? '',
      'userType': raw['userType'] ?? _registrationType ?? 'domestic',
      'nationality': raw['nationality'],
      'documentUrl': raw['documentUrl'],
      'hashId': raw['hashId'],
      'blockchainHashId': raw['blockchainHashId'],
    };
  }
}
