import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a random registration code
  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate a new registration code
  Future<Map<String, dynamic>> generateCode({
    required String generatedBy,
    required String role,
    required int maxUses,
  }) async {
    try {
      final code = _generateCode();

      await _firestore.collection('registration_codes').add({
        'code': code,
        'role': role,
        'maxUses': maxUses,
        'usedCount': 0,
        'active': true,
        'generatedBy': generatedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'code': code, 'message': 'Code generated successfully'};
    } catch (e) {
      print('Generate code error: $e');
      return {'success': false, 'message': 'Failed to generate code'};
    }
  }

  /// Validate a registration code WITHOUT using it (for checking before signup)
  Future<Map<String, dynamic>> validateCode(String code) async {
    try {
      if (code.isEmpty) {
        return {'valid': false, 'message': 'Code is empty'};
      }

      final querySnapshot = await _firestore
          .collection('registration_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('active', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'valid': false, 'message': 'Invalid or inactive code'};
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Check if code has uses remaining
      if (data['usedCount'] >= data['maxUses']) {
        return {'valid': false, 'message': 'Code has been fully used'};
      }

      return {
        'valid': true,
        'role': data['role'],
        'codeId': doc.id,
        'message': 'Code is valid'
      };
    } catch (e) {
      print('Validate code error: $e');
      return {'valid': false, 'message': 'Failed to validate code'};
    }
  }

  /// Mark a code as used (call this AFTER successful signup)
  Future<void> markCodeAsUsed(String codeId) async {
    try {
      final docRef = _firestore.collection('registration_codes').doc(codeId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final newUsedCount = (data['usedCount'] ?? 0) + 1;

      await docRef.update({
        'usedCount': FieldValue.increment(1),
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      // If maxUses reached, deactivate
      if (newUsedCount >= data['maxUses']) {
        await docRef.update({'active': false});
      }
    } catch (e) {
      print('Mark code as used error: $e');
    }
  }

  /// Validate and use a registration code (combined operation)
  Future<Map<String, dynamic>> validateAndUseCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection('registration_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('active', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {'success': false, 'message': 'Invalid or inactive code'};
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Check if code has uses remaining
      if (data['usedCount'] >= data['maxUses']) {
        return {'success': false, 'message': 'Code has been fully used'};
      }

      // Increment used count
      await doc.reference.update({
        'usedCount': FieldValue.increment(1),
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      // If maxUses reached, deactivate
      if (data['usedCount'] + 1 >= data['maxUses']) {
        await doc.reference.update({'active': false});
      }

      return {
        'success': true,
        'role': data['role'],
        'message': 'Code validated successfully'
      };
    } catch (e) {
      print('Validate and use code error: $e');
      return {'success': false, 'message': 'Failed to validate code'};
    }
  }

  /// Get all registration codes (Admin only)
  Stream<QuerySnapshot> getAllCodes() {
    return _firestore
        .collection('registration_codes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Deactivate a registration code
  Future<Map<String, dynamic>> deactivateCode(String codeId) async {
    try {
      await _firestore.collection('registration_codes').doc(codeId).update({
        'active': false,
      });
      return {'success': true, 'message': 'Code deactivated successfully'};
    } catch (e) {
      print('Deactivate code error: $e');
      return {'success': false, 'message': 'Failed to deactivate code'};
    }
  }

  /// Delete a registration code
  Future<Map<String, dynamic>> deleteCode(String codeId) async {
    try {
      await _firestore.collection('registration_codes').doc(codeId).delete();
      return {'success': true, 'message': 'Code deleted successfully'};
    } catch (e) {
      print('Delete code error: $e');
      return {'success': false, 'message': 'Failed to delete code'};
    }
  }

  /// Reactivate a registration code
  Future<Map<String, dynamic>> reactivateCode(String codeId) async {
    try {
      await _firestore.collection('registration_codes').doc(codeId).update({
        'active': true,
      });
      return {'success': true, 'message': 'Code reactivated successfully'};
    } catch (e) {
      print('Reactivate code error: $e');
      return {'success': false, 'message': 'Failed to reactivate code'};
    }
  }
}