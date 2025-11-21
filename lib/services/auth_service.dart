import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String userKey = 'username';
  static const String passKey = 'password';

  /// Ensures there is always a default user and password upon app install
  Future<void> setDefaultUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Force set default credentials (for testing)
    await prefs.setString(userKey, 'admin');
    await prefs.setString(passKey, '1234');
    
    print('Default user set: admin / 1234'); // Debug print
  }

  /// Saves a username and password to SharedPreferences
  Future<void> saveUser(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, username);
    await prefs.setString(passKey, password);
  }

  /// Checks if provided username and password match stored values
  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString(userKey);
    final savedPass = prefs.getString(passKey);
    
    // Debug prints to see what's happening
    print('Attempting login with: $username / $password');
    print('Stored credentials: $savedUser / $savedPass');
    print('Match: ${username == savedUser && password == savedPass}');
    
    if (username == savedUser && password == savedPass) {
      // Store login state
      await prefs.setBool('isLoggedIn', true);
      return true;
    }
    
    return false;
  }

  /// Checks if a user session exists
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  /// Logs out the user by removing login state
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    // Optional: keep credentials stored for next login
  }
}