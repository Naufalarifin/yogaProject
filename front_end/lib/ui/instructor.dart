import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'account.dart';
import 'dashboard.dart';

class InstructorPage extends StatelessWidget {
  final Map<String, dynamic> instructorData;
  final Map<String, dynamic>? userData;
  final String? userId;

  const InstructorPage({
    super.key,
    required this.instructorData,
    this.userData,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Getting instructor details directly from the document fields
    final String name = instructorData['name'] ?? 'Unknown';
    final String imageUrl = instructorData['imageUrl'] ?? '';
    final String description = instructorData['description'] ?? '';
    final String instagram = instructorData['instagram'] ?? '';
    
    print("Instructor description: $description");

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0), // Light cream background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top greeting section
                Text(
                  'Hello, ${userData?['username'] ?? 'Guest'}!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5530),
                  ),
                ),
                const SizedBox(height: 16),

                // Instructor section header
                const Text(
                  'Instructor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5530),
                  ),
                ),
                const SizedBox(height: 20),

                // Instructor name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5530),
                  ),
                ),
                const SizedBox(height: 10),

                // Instructor image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 380,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 380,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2C5530),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 380,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Color(0xFF2C5530),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 380,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name.characters.first.toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C5530),
                              ),
                            ),
                          ),
                        ),
                ),

                // Display Instagram handle if available
                if (instagram.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '@$instagram',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),

                // Show instructor description - Add fallback for empty description
                Container(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    description.isNotEmpty
                        ? description
                        : 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2C5530),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

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
            context,
            'Home',
            Icons.home,
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardPage(
                    userData: userData,
                    userId: userId,
                  ),
                ),
              );
            },
          ),
          _buildNavBarItem(
            context,
            'Mini Class',
            Icons.self_improvement,
            false,
            onTap: () {
              // Navigate to mini class page
            },
          ),
          _buildNavBarItem(
            context,
            'Yoga Class',
            Icons.accessibility_new,
            false,
            onTap: () {
              // Navigate to yoga class page
            },
          ),
          _buildNavBarItem(
            context,
            'Account',
            Icons.person,
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountPage(
                    userData: userData,
                    userId: userId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
    BuildContext context,
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
}
