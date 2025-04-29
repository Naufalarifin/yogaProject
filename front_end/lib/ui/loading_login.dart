import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dashboard.dart';

class LoadingLoginScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;
  
  const LoadingLoginScreen({
    super.key, 
    this.userData,
    this.userId,
  });

  @override
  State<LoadingLoginScreen> createState() => _LoadingLoginScreenState();
}

class _LoadingLoginScreenState extends State<LoadingLoginScreen> {
  late VideoPlayerController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/loading.webm")
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true)
      ..play();
    
    // Simulate loading process with a delay
    Timer(const Duration(seconds: 3), () {
      // Navigate to dashboard after loading completes
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            userData: widget.userData,
            userId: widget.userId,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get username from userData if available
    final String username = widget.userData != null 
        ? widget.userData!['username'] ?? 'User' 
        : 'User';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Hello Again!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C5530),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Signing in as $username',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C5530),
              ),
            ),
            const SizedBox(height: 40),
            _controller.value.isInitialized
                ? SizedBox(
                    height: 60,
                    width: 60,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(
                    color: Color(0xFF2C5530),
                  ),
            const SizedBox(height: 10),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2C5530),
              ),
            ),
          ],
        ),
      ),
    );
  }
}