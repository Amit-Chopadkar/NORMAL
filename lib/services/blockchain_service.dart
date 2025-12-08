import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';

/// Ethereum Blockchain Service for TourGuard
/// Connects to the ML Engine blockchain API to store and verify
/// user registration and login hash IDs on Ethereum.
class BlockchainService {
  static const String boxName = 'blockchainBox';
  
  // Default API endpoint - update this based on your deployment
  static String _apiBaseUrl = 'http://10.191.242.74:8082'; // Your PC's IP
  // static String _apiBaseUrl = 'http://10.0.2.2:8082'; // Android emulator
  // static String _apiBaseUrl = 'http://localhost:8082'; // iOS simulator
  
  /// Initialize the blockchain service
  static Future<void> init({String? apiBaseUrl}) async {
    if (apiBaseUrl != null) {
      _apiBaseUrl = apiBaseUrl;
    }
    
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }
  
  /// Set the API base URL
  static void setApiUrl(String url) {
    _apiBaseUrl = url;
  }
  
  /// Store registration hash on Ethereum blockchain
  /// Called after successful Firebase authentication
  static Future<BlockchainResult> storeRegistration({
    required String userId,
    required String email,
    required String phone,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/blockchain/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'email': email,
          'phone': phone,
          'name': name,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Store hash locally
          await _storeLocalHash(
            userId: userId,
            hashId: data['hash_id'],
            txHash: data['tx_hash'],
            blockNumber: data['block_number'],
            eventType: 'REGISTER',
          );
          
          return BlockchainResult(
            success: true,
            hashId: data['hash_id'],
            txHash: data['tx_hash'],
            blockNumber: data['block_number'],
            message: 'Registration recorded on blockchain',
          );
        } else {
          return BlockchainResult(
            success: false,
            error: data['error'] ?? 'Unknown error',
          );
        }
      } else {
        return BlockchainResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[Blockchain] Registration error: $e');
      return BlockchainResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Store login hash on Ethereum blockchain
  /// Called after successful Firebase login
  static Future<BlockchainResult> storeLogin({
    required String userId,
    String? deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/blockchain/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'device_id': deviceId ?? 'flutter_app',
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          // Store hash locally
          await _storeLocalHash(
            userId: userId,
            hashId: data['hash_id'],
            txHash: data['tx_hash'],
            blockNumber: data['block_number'],
            eventType: 'LOGIN',
          );
          
          return BlockchainResult(
            success: true,
            hashId: data['hash_id'],
            txHash: data['tx_hash'],
            blockNumber: data['block_number'],
            message: 'Login recorded on blockchain',
          );
        } else {
          return BlockchainResult(
            success: false,
            error: data['error'] ?? 'Unknown error',
          );
        }
      } else {
        return BlockchainResult(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[Blockchain] Login error: $e');
      return BlockchainResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Verify if a hash exists on the blockchain
  static Future<VerificationResult> verifyHash(String hashId) async {
    try {
      // Ensure hash has proper format
      final hash = hashId.startsWith('0x') ? hashId : '0x$hashId';
      
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/blockchain/verify/$hash'),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return VerificationResult(
          exists: data['exists'] == true,
          hashId: data['hash_id'],
          message: data['message'],
        );
      } else {
        return VerificationResult(
          exists: false,
          hashId: hashId,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[Blockchain] Verification error: $e');
      return VerificationResult(
        exists: false,
        hashId: hashId,
        error: e.toString(),
      );
    }
  }
  
  /// Get user's blockchain records
  static Future<UserRecords?> getUserRecords(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/blockchain/user/$userId/records'),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return UserRecords(
          userId: data['user_id'],
          recordCount: data['record_count'],
          records: List<Map<String, dynamic>>.from(data['records'] ?? []),
          summary: data['summary'] != null 
            ? Map<String, dynamic>.from(data['summary']) 
            : null,
        );
      }
      return null;
    } catch (e) {
      print('[Blockchain] Get records error: $e');
      return null;
    }
  }
  
  /// Get blockchain global statistics
  static Future<BlockchainStats?> getGlobalStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/blockchain/stats'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return BlockchainStats(
          connected: data['connected'] == true,
          contractDeployed: data['contract_deployed'] == true,
          totalUsers: data['total_users'] ?? 0,
          totalRegistrations: data['total_registrations'] ?? 0,
          totalLogins: data['total_logins'] ?? 0,
          networkUrl: data['network_url'],
          accountAddress: data['account_address'],
        );
      }
      return null;
    } catch (e) {
      print('[Blockchain] Get stats error: $e');
      return null;
    }
  }
  
  /// Check blockchain service health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/blockchain/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'connected';
      }
      return false;
    } catch (e) {
      print('[Blockchain] Health check failed: $e');
      return false;
    }
  }
  
  /// Get locally stored blockchain hashes
  static List<Map<String, dynamic>> getLocalHashes() {
    try {
      final box = Hive.box(boxName);
      final hashes = box.get('hashes', defaultValue: <dynamic>[]);
      return List<Map<String, dynamic>>.from(hashes);
    } catch (e) {
      return [];
    }
  }
  
  /// Get the last registration hash for a user
  static Map<String, dynamic>? getLastRegistrationHash(String userId) {
    final hashes = getLocalHashes();
    final userHashes = hashes.where(
      (h) => h['userId'] == userId && h['eventType'] == 'REGISTER'
    ).toList();
    
    if (userHashes.isEmpty) return null;
    return userHashes.last;
  }
  
  /// Get the last login hash for a user
  static Map<String, dynamic>? getLastLoginHash(String userId) {
    final hashes = getLocalHashes();
    final userHashes = hashes.where(
      (h) => h['userId'] == userId && h['eventType'] == 'LOGIN'
    ).toList();
    
    if (userHashes.isEmpty) return null;
    return userHashes.last;
  }
  
  /// Store hash locally for offline access
  static Future<void> _storeLocalHash({
    required String userId,
    required String? hashId,
    required String? txHash,
    required int? blockNumber,
    required String eventType,
  }) async {
    try {
      final box = Hive.box(boxName);
      List<dynamic> hashes = box.get('hashes', defaultValue: <dynamic>[]);
      
      hashes.add({
        'userId': userId,
        'hashId': hashId,
        'txHash': txHash,
        'blockNumber': blockNumber,
        'eventType': eventType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await box.put('hashes', hashes);
    } catch (e) {
      print('[Blockchain] Local storage error: $e');
    }
  }
  
  /// Clear local blockchain data
  static Future<void> clearLocalData() async {
    try {
      final box = Hive.box(boxName);
      await box.delete('hashes');
    } catch (e) {
      print('[Blockchain] Clear data error: $e');
    }
  }
}


/// Result of a blockchain transaction
class BlockchainResult {
  final bool success;
  final String? hashId;
  final String? txHash;
  final int? blockNumber;
  final String? message;
  final String? error;
  
  BlockchainResult({
    required this.success,
    this.hashId,
    this.txHash,
    this.blockNumber,
    this.message,
    this.error,
  });
  
  @override
  String toString() {
    return 'BlockchainResult(success: $success, hashId: $hashId, txHash: $txHash, blockNumber: $blockNumber)';
  }
}


/// Result of hash verification
class VerificationResult {
  final bool exists;
  final String hashId;
  final String? message;
  final String? error;
  
  VerificationResult({
    required this.exists,
    required this.hashId,
    this.message,
    this.error,
  });
}


/// User's blockchain records
class UserRecords {
  final String userId;
  final int recordCount;
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic>? summary;
  
  UserRecords({
    required this.userId,
    required this.recordCount,
    required this.records,
    this.summary,
  });
}


/// Global blockchain statistics
class BlockchainStats {
  final bool connected;
  final bool contractDeployed;
  final int totalUsers;
  final int totalRegistrations;
  final int totalLogins;
  final String? networkUrl;
  final String? accountAddress;
  
  BlockchainStats({
    required this.connected,
    required this.contractDeployed,
    required this.totalUsers,
    required this.totalRegistrations,
    required this.totalLogins,
    this.networkUrl,
    this.accountAddress,
  });
}


// ============ Legacy Compatibility ============
// Keep the old class name for backward compatibility

@Deprecated('Use BlockchainService instead')
class BlockchainDigitalID {
  static const String boxName = 'blockchainBox';
  
  static Future<void> initBlockchain() async {
    await BlockchainService.init();
  }

  static Future<String> createDigitalID({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String country,
    required String passportNumber,
    required String visaDetails,
    List<String>? emergencyContacts,
    Map<String, dynamic>? itinerary,
  }) async {
    final result = await BlockchainService.storeRegistration(
      userId: userId,
      email: email,
      phone: phone,
      name: name,
    );
    
    return result.hashId ?? 'TID-$userId-${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<Map<String, dynamic>?> getDigitalID(String blockchainID) async {
    final verification = await BlockchainService.verifyHash(blockchainID);
    
    if (verification.exists) {
      return {
        'blockchainID': blockchainID,
        'exists': true,
        'verified': true,
      };
    }
    return null;
  }

  static Future<bool> isValidForTrip(String blockchainID) async {
    final verification = await BlockchainService.verifyHash(blockchainID);
    return verification.exists;
  }

  static Future<String> generateQRCodeData(String blockchainID) async {
    return jsonEncode({
      'blockchainID': blockchainID,
      'type': 'TourGuard_Identity',
      'network': 'Ethereum',
    });
  }
}
