import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front_end/ui/dashboard.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'ui/login.dart';
import 'ui/session_manager.dart';  // Pastikan sudah ada import SessionManager
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
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/account': (context) => const AccountPage(),
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

  // Cek apakah sudah login atau belum
  Future<void> _checkLoginStatus() async {
    bool loggedIn = await SessionManager.isLoggedIn();

    if (loggedIn) {
      // Jika sudah login, ambil data user dan arahkan ke dashboard
      String? userId = await SessionManager.getUserId();
      Map<String, dynamic>? userData = await SessionManager.getUserData();  // Ambil username dengan benar

      // Pastikan userId dan username tidak null sebelum menavigasi
      if (userId != null && userData != null) {
        // Navigasi ke halaman loading login dengan data pengguna
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'userData': userData, 'userId': userId},  // Mengirimkan data pengguna ke HomePage
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
          ],
        ),
      ),
    );
  }
}
