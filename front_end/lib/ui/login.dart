import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register.dart';
import 'loginAdmin.dart';
import 'loading_login.dart';
import 'session_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signIn() async {
  try {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    print("Querying Firestore for user: $username");
    final QuerySnapshot result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    print("Query result docs: ${result.docs.length}");
    if (result.docs.isNotEmpty) {
      // Ambil data user dari dokumen Firestore
      final Map<String, dynamic> userData = result.docs.first.data() as Map<String, dynamic>;
      final String userId = result.docs.first.id;
      
      print("User found: $username, ID: $userId");
      print("User data: $userData");
      
      // Simpan sesi login dengan try-catch
      try {
        print("Saving login session...");
        await SessionManager.saveLoginSession(userId, userData);
        print("Session saved successfully");
      } catch (e) {
        print("Error saving session: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful but failed to save session: $e')),
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful! Welcome back!')),
      );
      
      print("Navigating to dashboard");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingLoginScreen(
            userData: userData,
            userId: userId,
          ),
        ),
      );
    } else {
      print("No user found with username: $username and provided password");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oops! Username atau password salah, coba lagi ya :)')),
      );
    }
  } catch (e) {
    print("Error during sign in: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Something went wrong: $e')),
    );
  }
}

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }
  
  void navigateToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginAdminScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kode build UI login seperti di kode asli
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Image.asset('assets/images/logo.png', height: 60),
            const SizedBox(height: 20),
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF364822),
              ),
            ),
            const Text(
              'Sign In to your account',
              style: TextStyle(fontSize: 14, color: Color(0xFF364822)),
            ),
            const SizedBox(height: 20),
            _buildTextField(Icons.person, 'Enter your username', controller: _usernameController),
            const SizedBox(height: 10),
            _buildTextField(Icons.lock, 'Enter your password', controller: _passwordController, isPassword: true),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF99B080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: navigateToRegister,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Or Sign Up',
                  style: TextStyle(
                    color: Color(0xFF364822),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: navigateToAdmin,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'login as admin',
                  style: TextStyle(
                    color: Color(0xFF364822),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hintText, {
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xff99b080).withOpacity(0.1),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF364822),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}