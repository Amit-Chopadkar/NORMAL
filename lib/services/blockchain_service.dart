import 'package:web3dart/web3dart.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class BlockchainDigitalID {
  static const String boxName = 'blockchainBox';
  
  // Simulated blockchain data structure
  static Future<void> initBlockchain() async {
    await Hive.openBox(boxName);
  }

  // Create blockchain digital ID (KYC)
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
    try {
      final box = Hive.box(boxName);
      
      // Generate unique blockchain ID
      final blockchainID = _generateBlockchainID(userId);
      
      // Create digital ID payload
      final digitalID = {
        'blockchainID': blockchainID,
        'userId': userId,
        'kyc': {
          'name': name,
          'email': email,
          'phone': phone,
          'country': country,
          'passportNumber': passportNumber,
          'visaDetails': visaDetails,
          'verificationStatus': 'verified',
          'verifiedAt': DateTime.now().toIso8601String(),
        },
        'emergencyContacts': emergencyContacts ?? [],
        'itinerary': itinerary ?? {},
        'tripValidityStart': DateTime.now().toIso8601String(),
        'tripValidityEnd': DateTime.now().add(Duration(days: 30)).toIso8601String(),
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Store in local blockchain box
      await box.put(blockchainID, digitalID);
      
      // In real implementation, this would interact with a blockchain
      print('Digital ID Created: $blockchainID');
      
      return blockchainID;
    } catch (e) {
      print('Error creating Digital ID: $e');
      return '';
    }
  }

  // Get digital ID
  static Future<Map<String, dynamic>?> getDigitalID(String blockchainID) async {
    try {
      final box = Hive.box(boxName);
      return box.get(blockchainID);
    } catch (e) {
      print('Error getting Digital ID: $e');
      return null;
    }
  }

  // Update itinerary
  static Future<bool> updateItinerary({
    required String blockchainID,
    required Map<String, dynamic> itinerary,
  }) async {
    try {
      final box = Hive.box(boxName);
      Map<String, dynamic> digitalID = box.get(blockchainID) ?? {};
      
      digitalID['itinerary'] = itinerary;
      digitalID['updatedAt'] = DateTime.now().toIso8601String();
      
      await box.put(blockchainID, digitalID);
      return true;
    } catch (e) {
      print('Error updating itinerary: $e');
      return false;
    }
  }

  // Add emergency contact
  static Future<bool> addEmergencyContact({
    required String blockchainID,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    try {
      final box = Hive.box(boxName);
      Map<String, dynamic> digitalID = box.get(blockchainID) ?? {};
      
      List<dynamic> contacts = digitalID['emergencyContacts'] ?? [];
      contacts.add({
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'addedAt': DateTime.now().toIso8601String(),
      });
      
      digitalID['emergencyContacts'] = contacts;
      await box.put(blockchainID, digitalID);
      
      return true;
    } catch (e) {
      print('Error adding emergency contact: $e');
      return false;
    }
  }

  // Verify digital ID is valid for trip
  static Future<bool> isValidForTrip(String blockchainID) async {
    try {
      final digitalID = await getDigitalID(blockchainID);
      if (digitalID == null) return false;
      
      final now = DateTime.now();
      final validityStart = DateTime.parse(digitalID['tripValidityStart']);
      final validityEnd = DateTime.parse(digitalID['tripValidityEnd']);
      
      return now.isAfter(validityStart) && now.isBefore(validityEnd);
    } catch (e) {
      return false;
    }
  }

  // Generate QR code data for digital ID
  static Future<String> generateQRCodeData(String blockchainID) async {
    try {
      final digitalID = await getDigitalID(blockchainID);
      if (digitalID == null) return '';
      
      return jsonEncode({
        'blockchainID': blockchainID,
        'name': digitalID['kyc']['name'],
        'email': digitalID['kyc']['email'],
        'passportNumber': digitalID['kyc']['passportNumber'],
        'validTill': digitalID['tripValidityEnd'],
      });
    } catch (e) {
      print('Error generating QR code: $e');
      return '';
    }
  }

  // Helper function to generate unique blockchain ID
  static String _generateBlockchainID(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TID-$userId-$timestamp';
  }
}
