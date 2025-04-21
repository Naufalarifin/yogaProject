import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  final String username;
  final String email;

  const SignUpScreen({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  String? passwordError;
  String? confirmPasswordError;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 8) {
      setState(() {
        passwordError = 'Password must be at least 8 characters';
      });
      return false;
    }

    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));

    if (!hasLetter || !hasNumber) {
      setState(() {
        passwordError = 'Password must contain at least one letter and one number';
      });
      return false;
    }

    setState(() {
      passwordError = null;
    });
    return true;
  }

  bool _validateConfirmPassword() {
    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        confirmPasswordError = 'Passwords do not match';
      });
      return false;
    }

    setState(() {
      confirmPasswordError = null;
    });
    return true;
  }

  Future<void> _signUp() async {
    setState(() {
      passwordError = null;
      confirmPasswordError = null;
    });

    bool isPasswordValid = _validatePassword(passwordController.text);
    bool isConfirmPasswordValid = _validateConfirmPassword();

    if (!isPasswordValid || !isConfirmPasswordValid) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // NOTE: Belum di-hash! Jangan simpan password mentah di production
      await FirebaseFirestore.instance.collection('users').add({
        'username': widget.username,
        'email': widget.email,
        'password': passwordController.text, // ⚠️ PASSWORD BELUM DI-HASH!
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        // TODO: Ganti ke navigasi halaman setelah registrasi
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (context) => HomeScreen()),
        //   (route) => false,
        // );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF364822)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset('assets/images/logo.png', height: 60),
            ),
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
              'Create your account',
              style: TextStyle(fontSize: 14, color: Color(0xFF364822)),
            ),
            const SizedBox(height: 10),
            Text(
              'Username: ${widget.username}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF364822)),
            ),
            Text(
              'Email: ${widget.email}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF364822)),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              icon: Icons.lock,
              hintText: 'Create your password',
              isPassword: true,
              controller: passwordController,
              errorText: passwordError,
            ),
            const SizedBox(height: 10),

            _buildTextField(
              icon: Icons.lock,
              hintText: 'Confirm your password',
              isPassword: true,
              controller: confirmPasswordController,
              errorText: confirmPasswordError,
            ),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, size: 14, color: Colors.black54),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'At least 8 characters, containing a letter and number.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF99B080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Sign up',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    required TextEditingController controller,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Center(
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0XFF364822), fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFEFF0E6),
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 12),
      ),
    );
  }
}
