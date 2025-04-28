import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'session_manager.dart'; 
import 'login.dart';
import 'account.dart';
import 'instructor.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const DashboardPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<Map<String, dynamic>> _instructors = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchInstructors();
  }

  // Metode untuk mengambil data instruktur dari Firestore
  Future<void> _fetchInstructors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mengambil data dari Firestore Collection
      final QuerySnapshot instructorsSnapshot = 
          await _firestore.collection('instructors').get();
      
      // Debug
      print('Documents count: ${instructorsSnapshot.docs.length}');
      
      if (instructorsSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempList = [];
        
        // Memproses setiap dokumen instruktur
        for (var doc in instructorsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing instructor: ${doc.id}');
          print('Instructor data: $data');
          
          // Menambahkan id dokumen ke dalam data
          tempList.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown',
            'imageUrl': data['imageUrl'] ?? '',
            'description': data['description'] ?? '',
            ...data, 
          });
        }
        
        print('Instructors loaded: ${tempList.length}');
        setState(() {
          _instructors.clear();
          _instructors.addAll(tempList);
          _isLoading = false;
        });
      } else {
        print('No instructors found in Firestore');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching instructors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Metode untuk logout
  Future<void> _logout() async {
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

  @override
  Widget build(BuildContext context) {
    // Mengambil username dari userData, jika tidak ada gunakan 'Guest'
    final String username = widget.userData != null ? widget.userData!['username'] ?? 'Guest' : 'Guest';
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AmalaYoga',
                      style: TextStyle(
                        color: Color(0xFF2C5530),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Tambahkan tombol logout
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFF2C5530)),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Hello, $username!', // Menampilkan username dari Firestore
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'What do you need?',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildSectionHeader('Popular virtual mini class'),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    // Navigate to mini class details
                  },
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/yoga_pose.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildLevelButton('Beginner level 1', true),
                    const SizedBox(width: 10),
                    _buildLevelButton('Intermediate level 2', false),
                  ],
                ),
                _buildSeeAllRow('See all'),
                const SizedBox(height: 25),
                _buildSectionHeader('Yoga class everyday'),
                const SizedBox(height: 15),
                _buildDayButton('Sunday'),
                const SizedBox(height: 10),
                _buildDayButton('Tuesday'),
                const SizedBox(height: 10),
                _buildDayButton('Thursday'),
                _buildSeeAllRow('See all'),
                const SizedBox(height: 25),
                _buildSectionHeader('Instructor'),
                const SizedBox(height: 15),
                _buildInstructorsList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // Widget untuk menampilkan daftar instruktur dari Firestore
  Widget _buildInstructorsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2C5530),
        ),
      );
    }

    if (_instructors.isEmpty) {
      return const Center(
        child: Text(
          'No instructors available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    // Membatasi jumlah instruktur yang ditampilkan maksimal 3
    final displayedInstructors = _instructors.length > 3 
        ? _instructors.sublist(0, 3) 
        : _instructors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: displayedInstructors.map((instructor) {
        return _buildInstructorItemFromUrl(instructor);
      }).toList(),
    );
  }

  // Widget untuk menampilkan instruktur dengan gambar dari URL
  Widget _buildInstructorItemFromUrl(Map<String, dynamic> instructor) {
    final String name = instructor['name'] ?? 'Unknown';
    final String imageUrl = instructor['imageUrl'] ?? '';
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to instructor profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstructorPage(
                  instructorData: instructor,
                  userData: widget.userData,
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2C5530),
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print('Error loading image: $error');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              name.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2C5530),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFFA3BE8C).withOpacity(0.3),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C5530),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Kode widget helper tidak berubah
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF2C5530),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLevelButton(String text, bool active) {
    return Text(
      text,
      style: TextStyle(
        color: active ? const Color(0xFF2C5530) : Colors.grey.shade700,
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSeeAllRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to see all
            },
            child: Row(
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF2C5530),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF2C5530),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(String day) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFA3BE8C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          day,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2C5530),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFA3BE8C).withOpacity(0.4),
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem('Home', Icons.home, true),
            _buildNavBarItem('Mini Class', Icons.self_improvement, false),
            _buildNavBarItem('Yoga Class', Icons.accessibility_new, false),
            _buildNavBarItem('Account', Icons.person, false, onTap: () {
              // Navigate to account page instead of showing profile dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccountPage(
                    userData: widget.userData,
                    userId: widget.userId,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(
    String label, 
    IconData icon, 
    bool isActive, 
    {VoidCallback? onTap}
  ) {
    return GestureDetector(
      onTap: onTap ?? () {
        // Default navigation handler
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
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