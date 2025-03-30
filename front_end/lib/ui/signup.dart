import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
            const SizedBox(height: 20),
            _buildStaticField(icon: Icons.person, label: 'farahsrw'),
            const SizedBox(height: 10),
            _buildStaticField(icon: Icons.email, label: 'farahsrw@gmail.com'),
            const SizedBox(height: 10),
            _buildTextField(icon: Icons.lock, hintText: 'Create your password', isPassword: true),
            const SizedBox(height: 10),
            _buildTextField(icon: Icons.lock, hintText: 'Confirm your password', isPassword: true),
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF99B080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
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

  Widget _buildStaticField({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20, // Ukuran lingkaran lebih kecil
            height: 20, // Ukuran lingkaran lebih kecil
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Center(
              child: Icon(icon, size: 14, color: Colors.white), // Ukuran ikon disesuaikan
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF364822)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required IconData icon, required String hintText, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            width: 20, // Ukuran lingkaran lebih kecil
            height: 20, // Ukuran lingkaran lebih kecil
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: Center(
              child: Icon(icon, size: 14, color: Colors.white), // Ikon disesuaikan
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
      ),
    );
  }
}
