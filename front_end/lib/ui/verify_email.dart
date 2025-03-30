import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

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
      home: const VerifyEmailScreen(),
    );
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String otpCode = "";
  bool isOtpFilled = false;

  void updateOtp(String code) {
    setState(() {
      otpCode = code;
      isOtpFilled = code.length == 6; // Jika panjang OTP = 6, ubah tombol menjadi "Verify"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Verify your email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF364822),
              ),
            ),
            const SizedBox(height: 10),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Please enter the verification ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF364822),
                    ),
                  ),
                  TextSpan(
                    text: 'code we\nsent to your email address ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF364822),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: 'to complete\nthe verification process.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF364822),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // OTP Text Field
            OtpTextField(
              numberOfFields: 6,
              borderColor: Colors.black,
              focusedBorderColor: Colors.black,
              cursorColor: Colors.black,
              showFieldAsBox: true,
              borderWidth: 1,
              fieldWidth: 35,
              fieldHeight: 35,
              textStyle: const TextStyle(fontSize: 14),
              onCodeChanged: (code) {
                updateOtp(code); // Update OTP ketika ada perubahan
              },
              onSubmit: (code) {
                updateOtp(code); // Pastikan status juga diperbarui saat submit
              },
            ),

            const SizedBox(height: 20),

            // Verify / Resend Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isOtpFilled) {
                    // Aksi saat OTP lengkap
                    print("Verifying OTP: $otpCode");
                  } else {
                    // Aksi saat OTP belum lengkap
                    print("Resending the code...");
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF99B080),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: Text(
                  isOtpFilled ? 'Verify' : 'Resend the code',
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
