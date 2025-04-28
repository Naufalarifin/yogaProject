import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_manager.dart';
import 'login.dart';
import 'dashboard.dart';

class AccountPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const AccountPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  @override
  Widget build(BuildContext context) {
    // Use userData if available, otherwise use default values
    final String username = widget.userData != null ? widget.userData!['username'] ?? 'Guest' : 'Guest';
    final String email = widget.userData != null ? widget.userData!['email'] ?? 'No email' : 'No email';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0), // Light cream background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top greeting
              Text(
                'Hello, $username!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5530),
                ),
              ),
              const SizedBox(height: 16),
              
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'What do you need?',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // My Account Section
              const Text(
                'My Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C5530),
                ),
              ),
              const SizedBox(height: 16),
              
              // User info card - Clickable
              GestureDetector(
                onTap: () {
                  _showAccountDetails(context);
                },
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Navigation items with arrows
              _buildNavigationItem(
                'Booked classes', 
                Icons.calendar_today,
                onTap: () {
                  _navigateToBookedClasses();
                },
              ),
              _buildNavigationItem(
                'Track yoga class', 
                Icons.track_changes,
                onTap: () {
                  _navigateToTrackYogaClass();
                },
              ),
              _buildNavigationItem(
                'Mini yoga class progress', 
                Icons.show_chart,
                onTap: () {
                  _navigateToMiniYogaProgress();
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // Helper method to create navigation items with arrows
  Widget _buildNavigationItem(String title, IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C5530),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  // Bottom navigation bar
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFA3BE8C).withOpacity(0.4),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            'Home', 
            Icons.home, 
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    userData: widget.userData,
                    userId: widget.userId,
                  ),
                ),
              );
            },
          ),
          _buildNavBarItem(
            'Mini Class', 
            Icons.self_improvement, 
            false,
            onTap: () {
              _navigateToMiniClass();
            },
          ),
          _buildNavBarItem(
            'Yoga Class', 
            Icons.accessibility_new, 
            false,
            onTap: () {
              _navigateToYogaClass();
            },
          ),
          _buildNavBarItem(
            'Account', 
            Icons.person, 
            true,
            onTap: () {
              // Already on account page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    String label, 
    IconData icon, 
    bool isActive, 
    {required VoidCallback onTap}
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2C5530) : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToBookedClasses() {
    // Navigate to booked classes page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Booked Classes')),
    );
    // TODO: Implement actual navigation when page is available
  }

  void _navigateToTrackYogaClass() {
    // Navigate to track yoga class page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Track Yoga Class')),
    );
    // TODO: Implement actual navigation when page is available
  }

  void _navigateToMiniYogaProgress() {
    // Navigate to mini yoga progress page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Mini Yoga Class Progress')),
    );
    // TODO: Implement actual navigation when page is available
  }

  void _navigateToMiniClass() {
    // Navigate to mini class page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Mini Class')),
    );
    // TODO: Implement actual navigation when page is available
  }

  void _navigateToYogaClass() {
    // Navigate to yoga class page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Yoga Class')),
    );
    // TODO: Implement actual navigation when page is available
  }

  // Show account details dialog
  void _showAccountDetails(BuildContext context) {
    if (widget.userData == null) return;
    
    // Format date if available
    String formattedDate = 'N/A';
    if (widget.userData!.containsKey('createdAt')) {
      if (widget.userData!['createdAt'] is Timestamp) {
        final timestamp = widget.userData!['createdAt'] as Timestamp;
        final dateTime = timestamp.toDate();
        formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else {
        formattedDate = widget.userData!['createdAt'].toString();
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Account Details',
          style: TextStyle(
            color: Color(0xFF2C5530),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileItem('Username', widget.userData!['username'] ?? 'N/A'),
              _buildProfileItem('Email', widget.userData!['email'] ?? 'N/A'),
              _buildProfileItem('Registered', formattedDate),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF2C5530)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C5530),
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
          const Divider(),
        ],
      ),
    );
  }
  
  // Logout method
  Future<void> _logout(BuildContext context) async {
    try {
      await SessionManager.logout();
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }
}