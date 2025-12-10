import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up a new user
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    String role = 'user',
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('User created successfully: ${userCredential.user!.uid}');
      notifyListeners();
      return {'success': true, 'message': 'Account created successfully'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'weak-password':
          message = 'The password is too weak';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for this email';
          break;
        case 'invalid-email':
          message = 'The email address is invalid';
          break;
        default:
          message = e.message ?? 'An error occurred';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Sign up error: $e');
      return {'success': false, 'message': 'Failed to create account'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user is disabled
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['disabled'] == true) {
          await _auth.signOut();
          return {
            'success': false,
            'message': 'Your account has been disabled. Please contact support.'
          };
        }
      }
      
      print('User logged in: ${userCredential.user!.uid}');
      notifyListeners();
      return {'success': true, 'message': 'Logged in successfully'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Wrong password';
          break;
        case 'invalid-email':
          message = 'The email address is invalid';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
        default:
          message = e.message ?? 'Login failed';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Failed to login'};
    }
  }

  /// Get current user document
  Future<DocumentSnapshot?> getCurrentUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      return await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('User logged out');
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  /// Get current user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // Check if user is logged in
      if (currentUser == null) {
        print('getUserData: No user is currently logged in');
        return null;
      }

      print('getUserData: Fetching data for user ${currentUser!.uid}');

      // Fetch user document from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('getUserData: Found user data: ${data['username']}');
        return data;
      } else {
        print('getUserData: User document does not exist in Firestore');
        // If document doesn't exist, create one with basic info
        await _firestore.collection('users').doc(currentUser!.uid).set({
          'uid': currentUser!.uid,
          'email': currentUser!.email,
          'username': currentUser!.email?.split('@')[0] ?? 'User',
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Fetch again
        doc = await _firestore.collection('users').doc(currentUser!.uid).get();
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  /// Get user data by ID
  Future<Map<String, dynamic>?> getUserDataById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Get user data by ID error: $e');
      return null;
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    try {
      if (currentUser == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'admin';
      }
      return false;
    } catch (e) {
      print('Check admin error: $e');
      return false;
    }
  }

  /// Get user role
  Future<String> getUserRole() async {
    try {
      if (currentUser == null) return 'user';

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'] ?? 'user';
      }
      return 'user';
    } catch (e) {
      print('Get role error: $e');
      return 'user';
    }
  }

  /// Get all users (Admin only)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Get users error: $e');
      return [];
    }
  }

  /// Update user role (Admin only)
  Future<Map<String, dynamic>> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
      return {'success': true, 'message': 'User role updated successfully'};
    } catch (e) {
      print('Update role error: $e');
      return {'success': false, 'message': 'Failed to update user role'};
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    String? username,
    String? email,
  }) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      Map<String, dynamic> updates = {};
      
      if (username != null) {
        updates['username'] = username;
      }
      
      if (email != null) {
        updates['email'] = email;
        // Also update email in Firebase Auth
        await currentUser!.verifyBeforeUpdateEmail(email);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(currentUser!.uid).update(updates);
      }

      notifyListeners();
      return {'success': true, 'message': 'Profile updated successfully'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'invalid-email':
          message = 'The email address is invalid';
          break;
        case 'email-already-in-use':
          message = 'This email is already in use';
          break;
        case 'requires-recent-login':
          message = 'Please log in again to update your email';
          break;
        default:
          message = e.message ?? 'Failed to update profile';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Update profile error: $e');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'invalid-email':
          message = 'The email address is invalid';
          break;
        default:
          message = e.message ?? 'Failed to send reset email';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Reset password error: $e');
      return {'success': false, 'message': 'Failed to send reset email'};
    }
  }

  /// Delete user account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      String userId = currentUser!.uid;

      // Delete user data from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete user from Firebase Auth
      await currentUser!.delete();

      notifyListeners();
      return {'success': true, 'message': 'Account deleted successfully'};
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'requires-recent-login') {
        message = 'Please log in again to delete your account';
      } else {
        message = e.message ?? 'Failed to delete account';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('Delete account error: $e');
      return {'success': false, 'message': 'Failed to delete account'};
    }
  }
}