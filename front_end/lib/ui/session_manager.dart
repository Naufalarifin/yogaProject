import 'dart:convert';  // Import untuk jsonEncode dan jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import untuk Timestamp

class SessionManager {
  // Kunci untuk menyimpan data
  static const String keyUserId = 'userId';
  static const String keyIsLoggedIn = 'isLoggedIn';
  static const String keyUserData = 'userData';  // Ubah kunci untuk menyimpan userData sebagai JSON

  // Menyimpan data login
  static Future<void> saveLoginSession(String userId, Map<String, dynamic> userData) async {
    try {
      print("Attempting to save session...");
      final prefs = await SharedPreferences.getInstance();

      // Simpan userId
      await prefs.setString(keyUserId, userId);

      // Konversi userData untuk menangani Timestamp
      Map<String, dynamic> convertedUserData = _convertTimestampToString(userData);

      // Simpan userData sebagai JSON string
      String userDataJson = jsonEncode(convertedUserData);
      await prefs.setString(keyUserData, userDataJson);

      await prefs.setBool(keyIsLoggedIn, true);
      print("Session saved successfully");
    } catch (e) {
      print("Error saving session: $e");
      // Rethrow error untuk penanganan di tempat lain
      rethrow;
    }
  }

  // Mengonversi Timestamp menjadi String agar bisa diserialisasi
  static Map<String, dynamic> _convertTimestampToString(Map<String, dynamic> userData) {
    Map<String, dynamic> convertedData = {};

    userData.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Timestamp to String (DateTime or millisecondsSinceEpoch)
        convertedData[key] = value.toDate().toIso8601String();  // Convert Timestamp to ISO8601 String
      } else {
        convertedData[key] = value;  // If it's not Timestamp, keep the original value
      }
    });

    return convertedData;
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

  // Mengonversi String ke Timestamp saat mengambil data
  static Map<String, dynamic> _convertStringToTimestamp(Map<String, dynamic> userData) {
    Map<String, dynamic> convertedData = {};

    userData.forEach((key, value) {
      if (value is String && key == 'createdAt') {
        // Misalnya, jika key 'createdAt', ubah dari String ISO8601 ke Timestamp
        convertedData[key] = Timestamp.fromDate(DateTime.parse(value));  // Convert String back to Timestamp
      } else {
        convertedData[key] = value;  // Keep the original value
      }
    });

    return convertedData;
  }

  // Logout
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyIsLoggedIn);
      await prefs.remove(keyUserId);
      await prefs.remove(keyUserData);  // Hapus userData juga saat logout
      print("Logout successful");
    } catch (e) {
      print("Error during logout: $e");
      rethrow;
    }
  }
}
