import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // Kunci untuk menyimpan data
  static const String keyUserId = 'userId';
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUsername = 'username';

  // Menyimpan data login
  static Future<void> saveLoginSession(String userId, Map<String, dynamic> userData) async {
    try {
      print("Attempting to save session...");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyIsLoggedIn, true);
      await prefs.setString(keyUserId, userId);
      await prefs.setString(keyUsername, userData['username'] ?? '');
      print("Session saved successfully");
    } catch (e) {
      print("Error saving session: $e");
      // Rethrow error untuk penanganan di tempat lain
      rethrow;
    }
  }

  // Mengecek status login
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyIsLoggedIn) ?? false;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  // Mendapatkan UserId
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyUserId);
    } catch (e) {
      print("Error getting user ID: $e");
      return null;
    }
  }

  // Mendapatkan Username
  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyUsername);
    } catch (e) {
      print("Error getting username: $e");
      return null;
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyIsLoggedIn);
      await prefs.remove(keyUserId);
      await prefs.remove(keyUsername);
      print("Logout successful");
    } catch (e) {
      print("Error during logout: $e");
      rethrow;
    }
  }
}