import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoadingSignUpScreen(),
    );
  }
}

class LoadingSignUpScreen extends StatefulWidget {
  const LoadingSignUpScreen({super.key});

  @override
  _LoadingSignUpScreen createState() => _LoadingSignUpScreen();
}

class _LoadingSignUpScreen extends State<LoadingSignUpScreen> {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                color: Color(0xFF364822),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Signing in to your account',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF364822),
              ),
            ),
            const SizedBox(height: 40),
            _controller.value.isInitialized
                ? SizedBox(
                    height: 60,
                    width: 60,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text(
              'Loading...',
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
