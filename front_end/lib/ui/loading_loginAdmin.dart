import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboardAdmin.dart';

class LoadingLoginAdmin extends StatefulWidget {
  final Map<String, dynamic> adminData;
  final String adminId;

  const LoadingLoginAdmin({
    super.key,
    required this.adminData,
    required this.adminId,
  });

  @override
  State<LoadingLoginAdmin> createState() => _LoadingLoginAdminState();
}

class _LoadingLoginAdminState extends State<LoadingLoginAdmin> {
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

    // Navigasi ke dashboard admin setelah 3 detik dengan membawa data admin
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardAdminPage(
            adminData: widget.adminData,
            adminId: widget.adminId,
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
            Text(
              'Welcome, ${widget.adminData['username']}',
              style: const TextStyle(
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
                : const CircularProgressIndicator(
                    color: Color(0xFF99B080),
                  ),
            const SizedBox(height: 10),
            const Text(
              'Loading your admin dashboard...',
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