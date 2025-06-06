import 'dart:convert';  // Import untuk jsonEncode dan jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import untuk Timestamp

class SessionManager {
  // Kunci untuk menyimpan data user
  static const String keyUserId = 'userId';
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserData = 'userData';  // Ubah kunci untuk menyimpan userData sebagai JSON

  // Kunci untuk menyimpan data admin
  static const String keyAdminId = 'adminId';
  static const String keyIsAdminLoggedIn = 'isAdminLoggedIn';
  static const String keyAdminData = 'adminData';

  // ===== USER SESSION METHODS =====

  // Menyimpan data login user
  static Future<void> saveLoginSession(String userId, Map<String, dynamic> userData) async {
    try {
      print("Attempting to save user session...");
      final prefs = await SharedPreferences.getInstance();

      // Simpan userId
      await prefs.setString(keyUserId, userId);

      // Konversi userData untuk menangani Timestamp
      Map<String, dynamic> convertedUserData = _convertTimestampToString(userData);

      // Simpan userData sebagai JSON string
      String userDataJson = jsonEncode(convertedUserData);
      await prefs.setString(keyUserData, userDataJson);

      await prefs.setBool(keyIsLoggedIn, true);
      print("User session saved successfully");
    } catch (e) {
      print("Error saving user session: $e");
      // Rethrow error untuk penanganan di tempat lain
      rethrow;
    }
  }

  // Mengecek status login user
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyIsLoggedIn) ?? false;
    } catch (e) {
      print("Error checking user login status: $e");
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

  // Mendapatkan UserData
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userDataJson = prefs.getString(keyUserData);

      // Jika userData ada, dekodekan JSON menjadi Map
      if (userDataJson != null) {
        Map<String, dynamic> userData = jsonDecode(userDataJson);

        // Mengonversi kembali Timestamp (String ke DateTime)
        userData = _convertStringToTimestamp(userData);

        return userData;
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyIsLoggedIn);
      await prefs.remove(keyUserId);
      await prefs.remove(keyUserData);  // Hapus userData juga saat logout
      print("User logout successful");
    } catch (e) {
      print("Error during user logout: $e");
      rethrow;
    }
  }

  // ===== ADMIN SESSION METHODS =====

  // Menyimpan data login admin
  static Future<void> saveAdminSession(String adminId, Map<String, dynamic> adminData) async {
    try {
      print("Attempting to save admin session...");
      final prefs = await SharedPreferences.getInstance();

      // Simpan adminId
      await prefs.setString(keyAdminId, adminId);

      // Konversi adminData untuk menangani Timestamp
      Map<String, dynamic> convertedAdminData = _convertTimestampToString(adminData);

      // Simpan adminData sebagai JSON string
      String adminDataJson = jsonEncode(convertedAdminData);
      await prefs.setString(keyAdminData, adminDataJson);

      await prefs.setBool(keyIsAdminLoggedIn, true);
      print("Admin session saved successfully");
    } catch (e) {
      print("Error saving admin session: $e");
      // Rethrow error untuk penanganan di tempat lain
      rethrow;
    }
  }

  // Mengecek status login admin
  static Future<bool> isAdminLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(keyIsAdminLoggedIn) ?? false;
    } catch (e) {
      print("Error checking admin login status: $e");
      return false;
    }
  }

  // Mendapatkan AdminId
  static Future<String?> getAdminId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyAdminId);
    } catch (e) {
      print("Error getting admin ID: $e");
      return null;
    }
  }

  // Mendapatkan AdminData
  static Future<Map<String, dynamic>?> getAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? adminDataJson = prefs.getString(keyAdminData);

      // Jika adminData ada, dekodekan JSON menjadi Map
      if (adminDataJson != null) {
        Map<String, dynamic> adminData = jsonDecode(adminDataJson);

        // Mengonversi kembali Timestamp (String ke DateTime)
        adminData = _convertStringToTimestamp(adminData);

        return adminData;
      }
      return null;
    } catch (e) {
      print("Error getting admin data: $e");
      return null;
    }
  }

  // Logout admin
  static Future<void> adminLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyIsAdminLoggedIn);
      await prefs.remove(keyAdminId);
      await prefs.remove(keyAdminData);
      print("Admin logout successful");
    } catch (e) {
      print("Error during admin logout: $e");
      rethrow;
    }
  }

  // Clear all sessions (user and admin)
  static Future<void> clearAllSessions() async {
    try {
      await logout();
      await adminLogout();
      print("All sessions cleared");
    } catch (e) {
      print("Error clearing all sessions: $e");
      rethrow;
    }
  }

  // ===== HELPER METHODS =====

  // Mengonversi Timestamp menjadi String agar bisa diserialisasi
  static Map<String, dynamic> _convertTimestampToString(Map<String, dynamic> data) {
    Map<String, dynamic> convertedData = {};

    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to String (DateTime or millisecondsSinceEpoch)
        convertedData[key] = value.toDate().toIso8601String();  // Convert Timestamp to ISO8601 String
      } else {
        convertedData[key] = value;  // If it's not Timestamp, keep the original value
      }
    });

    return convertedData;
  }

  // Mengonversi String ke Timestamp saat mengambil data
  static Map<String, dynamic> _convertStringToTimestamp(Map<String, dynamic> data) {
    Map<String, dynamic> convertedData = {};

    data.forEach((key, value) {
      if (value is String && key == 'createdAt') {
        // Misalnya, jika key 'createdAt', ubah dari String ISO8601 ke Timestamp
        convertedData[key] = Timestamp.fromDate(DateTime.parse(value));  // Convert String back to Timestamp
      } else {
        convertedData[key] = value;  // Keep the original value
      }
    });

    return convertedData;
  }
}