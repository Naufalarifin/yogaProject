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
      home: const RegisterScreen(),
    );
  }
}

// Ubah menjadi StatefulWidget
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isChecked = false; // Deklarasi variabel isChecked

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
            
            const SizedBox(height: 20),Image.asset('assets/images/logo.png', height: 60),
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
            _buildTextField(Icons.person, 'Enter username'),
            const SizedBox(height: 10),
            _buildTextField(Icons.email, 'Enter your email'),
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
                onPressed:
                    isChecked ? () {} : null, // Disabled jika tidak dicentang
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isChecked
                          ? const Color(0xFF99B080)
                          : Colors.grey[400], // Warna berubah sesuai checkbox
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

  Widget _buildTextField(
    IconData icon,
    String hintText, {
    bool isPassword = false,
  }) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        // ignore: deprecated_member_use
        fillColor: const Color(
          0xff99b080,
        // ignore: deprecated_member_use
        ).withOpacity(0.1), // Warna dengan 10% opacity
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
