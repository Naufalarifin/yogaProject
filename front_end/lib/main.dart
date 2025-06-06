import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front_end/ui/dashboard.dart';
import 'package:front_end/ui/dashboardAdmin.dart'; // Import dashboard admin
import 'dart:async';
import 'ui/login.dart';
import 'ui/session_manager.dart';
import 'ui/account.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // Handle route generation with arguments
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DashboardPage(
              userData: args?['userData'],
              userId: args?['userId'],
            ),
          );
        } else if (settings.name == '/admin-dashboard') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DashboardAdminPage(
              adminData: args?['adminData'] ?? {},
              adminId: args?['adminId'] ?? '',
            ),
          );
        } else if (settings.name == '/account') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => AccountPage(
              userData: args?['userData'],
              userId: args?['userId'],
            ),
          );
        }
        
        // Default routes without arguments
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          default:
            return MaterialPageRoute(builder: (context) => const SplashScreen());
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Cek apakah sudah login atau belum (user atau admin)
  Future<void> _checkLoginStatus() async {
    // Cek admin login terlebih dahulu
    bool adminLoggedIn = await SessionManager.isAdminLoggedIn();
    
    if (adminLoggedIn) {
      // Jika admin sudah login, ambil data admin dan arahkan ke admin dashboard
      String? adminId = await SessionManager.getAdminId();
      Map<String, dynamic>? adminData = await SessionManager.getAdminData();
      
      print("Admin ID from session: $adminId");
      print("Admin data from session: $adminData");

      // Pastikan adminId dan adminData tidak null sebelum menavigasi
      if (adminId != null && adminData != null) {
        // Navigasi ke admin dashboard dengan data admin
        Navigator.pushReplacementNamed(
          context,
          '/admin-dashboard',
          arguments: {'adminData': adminData, 'adminId': adminId},
        );
        return;
      } else {
        // Jika tidak ada data admin yang valid, clear session dan lanjut cek user
        _navigateToLogin();
      }
    }

    // Cek user login jika admin tidak login
    bool userLoggedIn = await SessionManager.isLoggedIn();

    if (userLoggedIn) {
      // Jika user sudah login, ambil data user dan arahkan ke dashboard
      String? userId = await SessionManager.getUserId();
      Map<String, dynamic>? userData = await SessionManager.getUserData();
      
      print("User ID from session: $userId");
      print("User data from session: $userData");

      // Pastikan userId dan userData tidak null sebelum menavigasi
      if (userId != null && userData != null) {
        // Navigasi ke dashboard dengan data pengguna
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'userData': userData, 'userId': userId},
        );
      } else {
        // Jika tidak ada data yang valid, arahkan ke login
        _navigateToLogin();
      }
    } else {
      // Jika belum login, arahkan ke login
      _navigateToLogin();
    }
  }

  // Fungsi untuk navigasi ke LoginScreen
  void _navigateToLogin() {
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'AmalaYoga',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF364822),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Everyday Flow',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF364822),
              ),
            ),
            const SizedBox(height: 30),
            // Loading indicator
            const CircularProgressIndicator(
              color: Color(0xFF364822),
            ),
          ],
        ),
      ),
    );
  }
}