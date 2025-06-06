import 'package:flutter/material.dart';
import 'dart:async';

class LoadingSignUpScreen extends StatefulWidget {
  const LoadingSignUpScreen({super.key});

  @override
  State<LoadingSignUpScreen> createState() => _LoadingSignUpScreenState();
}

class _LoadingSignUpScreenState extends State<LoadingSignUpScreen> 
    with TickerProviderStateMixin {
  // Controllers untuk animasi
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _dotController;
  
  // Animations
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<int> _dotAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    
    // Initialize animations
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // 360 degrees in radians
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _dotAnimation = IntTween(
      begin: 0,
      end: 3,
    ).animate(CurvedAnimation(
      parent: _dotController,
      curve: Curves.linear,
    ));
    
    // Start animations
    _rotationController.repeat();
    _scaleController.repeat(reverse: true);
    _fadeController.forward();
    _dotController.repeat();
    
    // Navigasi ke halaman berikutnya setelah 3 detik
    // Catatan: Tambahkan navigasi sesuai kebutuhan
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      // Tambahkan navigasi ke halaman berikutnya di sini
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => NextPage(),
      //   ),
      // );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Nice to see you!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF364822),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF364822),
                ),
              ),
              const SizedBox(height: 40),
              
              // Animated loading widget
              AnimatedBuilder(
                animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF364822),
                              Color(0xFF99B080),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF364822).withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              
              // Loading text with animated dots
              AnimatedBuilder(
                animation: _dotAnimation,
                builder: (context, child) {
                  String dots = '';
                  for (int i = 0; i < _dotAnimation.value; i++) {
                    dots += '.';
                  }
                  
                  return Text(
                    'Loading$dots',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF364822),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
