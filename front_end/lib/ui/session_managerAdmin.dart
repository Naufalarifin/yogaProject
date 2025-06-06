class SessionManagerAdmin {
  // Static variables untuk menyimpan session data
  static bool _isUserLoggedIn = false;
  static bool _isAdminLoggedIn = false;
  static String? _userId;
  static String? _adminId;
  static Map<String, dynamic>? _userData;
  static Map<String, dynamic>? _adminData;

  // User session methods
  static Future<void> saveUserSession(String userId, Map<String, dynamic> userData) async {
    _isUserLoggedIn = true;
    _userId = userId;
    _userData = userData;
  }

  static Future<bool> isLoggedIn() async {
    return _isUserLoggedIn;
  }

  static Future<String?> getUserId() async {
    return _userId;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    return _userData;
  }

  static Future<void> clearUserSession() async {
    _isUserLoggedIn = false;
    _userId = null;
    _userData = null;
  }

  // Admin session methods
  static Future<void> saveAdminSession(String adminId, Map<String, dynamic> adminData) async {
    _isAdminLoggedIn = true;
    _adminId = adminId;
    _adminData = adminData;
  }

  static Future<bool> isAdminLoggedIn() async {
    return _isAdminLoggedIn;
  }

  static Future<String?> getAdminId() async {
    return _adminId;
  }

  static Future<Map<String, dynamic>?> getAdminData() async {
    return _adminData;
  }

  static Future<void> clearAdminSession() async {
    _isAdminLoggedIn = false;
    _adminId = null;
    _adminData = null;
  }

  // Clear all sessions
  static Future<void> clearAllSessions() async {
    await clearUserSession();
    await clearAdminSession();
  }
}