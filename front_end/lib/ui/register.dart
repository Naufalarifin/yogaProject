import 'package:flutter/material.dart';
import 'signup.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isChecked = false;
  
  // Tambahkan controller untuk username dan email
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  
  @override
  void dispose() {
    // Bersihkan controller saat widget dihapus
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Create your account',
              style: TextStyle(fontSize: 14, color: Color(0xFF364822)),
            ),
            const SizedBox(height: 20),
            _buildTextField(Icons.person, 'Enter username', controller: usernameController),
            const SizedBox(height: 10),
            _buildTextField(Icons.email, 'Enter your email', controller: emailController),
            const SizedBox(height: 10),

            // Checkbox dengan setState()
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  activeColor: const Color(0xFF6B7A52),
                  onChanged: (bool? value) {
                    setState(() {
                      isChecked = value ?? false;
                    });
                  },
                ),
                const Text(
                  'I Agree with Terms & Condition',
                  style: TextStyle(fontSize: 14, color: Color(0xFF364822)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol Continue
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isChecked ? _navigateToSignUpScreen : null, // Navigasi ke SignUpScreen
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isChecked ? const Color(0xFF99B080) : Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk navigasi ke SignUpScreen dengan data username dan email
  void _navigateToSignUpScreen() {
    if (usernameController.text.isEmpty || emailController.text.isEmpty) {
      // Validasi input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and email')),
      );
      return;
    }

    // Validasi format email sederhana
    if (!emailController.text.contains('@') || !emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpScreen(
          username: usernameController.text,
          email: emailController.text,
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hintText, {
    bool isPassword = false,
    required TextEditingController controller,
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