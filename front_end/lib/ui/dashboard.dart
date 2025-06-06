import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'session_manager.dart'; 
import 'login.dart';
import 'account.dart';
import 'instructor.dart';
import 'booking_class.dart';
import 'miniClassPage.dart';
import 'chatbotPage.dart'; // Import halaman chatbot baru

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
  Map<String, dynamic>? _currentUserData;
  String? _currentUserId;

  // Search functionality
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _currentUserId = widget.userId;
    _fetchUserData();
    _fetchInstructors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Metode untuk navigasi ke chatbot
  void _navigateToChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatbotPage(
          userData: _currentUserData,
          userId: _currentUserId,
        ),
      ),
    );
  }

  // Metode untuk mengambil data user dari Firestore
  Future<void> _fetchUserData() async {
    if (_currentUserId != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(_currentUserId).get();
        if (userDoc.exists) {
          setState(() {
            _currentUserData = userDoc.data();
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  // Metode untuk mengambil data instruktur dari Firestore
  Future<void> _fetchInstructors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot instructorsSnapshot = 
          await _firestore.collection('instructors').get();
      
      print('Documents count: ${instructorsSnapshot.docs.length}');
      
      if (instructorsSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempList = [];
        
        for (var doc in instructorsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing instructor: ${doc.id}');
          print('Instructor data: $data');
          
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

  // Search functionality - mencari di semua kategori
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
    });

    try {
      List<Map<String, dynamic>> allResults = [];
      
      // Search Mini Class Videos
      await _searchMiniClassVideos(query, allResults);
      
      // Search Yoga Classes
      await _searchYogaClasses(query, allResults);
      
      // Search Instructors
      await _searchInstructors(query, allResults);

      setState(() {
        _searchResults = allResults;
        _isLoadingSearch = false;
      });

    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
    }
  }

  // Search Mini Class Videos
  Future<void> _searchMiniClassVideos(String query, List<Map<String, dynamic>> results) async {
    try {
      // Search in VidioBeginner
      QuerySnapshot beginnerSnapshot = await _firestore.collection('VidioBeginner').get();
      for (var doc in beginnerSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().trim();
        if (name.toLowerCase().contains(query.toLowerCase().trim())) {
          results.add({
            'id': doc.id,
            'type': 'mini_class',
            'category': 'Beginner Video',
            'name': name,
            'level': 'beginner',
            'link': data['link'] ?? '',
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'description': 'Virtual mini class - Beginner level',
            ...data,
          });
        }
      }

      // Search in VideoIntermediate
      QuerySnapshot intermediateSnapshot = await _firestore.collection('VideoIntermediate').get();
      for (var doc in intermediateSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().trim();
        if (name.toLowerCase().contains(query.toLowerCase().trim())) {
          results.add({
            'id': doc.id,
            'type': 'mini_class',
            'category': 'Intermediate Video',
            'name': name,
            'level': 'intermediate',
            'link': data['link'] ?? '',
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'description': 'Virtual mini class - Intermediate level',
            ...data,
          });
        }
      }

      // Search in VideoAdvanced
      QuerySnapshot advancedSnapshot = await _firestore.collection('VideoAdvanced').get();
      for (var doc in advancedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().trim();
        if (name.toLowerCase().contains(query.toLowerCase().trim())) {
          results.add({
            'id': doc.id,
            'type': 'mini_class',
            'category': 'Advanced Video',
            'name': name,
            'level': 'advanced',
            'link': data['link'] ?? '',
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'description': 'Virtual mini class - Advanced level',
            ...data,
          });
        }
      }
    } catch (e) {
      print('Error searching mini class videos: $e');
    }
  }

  // Search Yoga Classes
  Future<void> _searchYogaClasses(String query, List<Map<String, dynamic>> results) async {
    try {
      // Get current date and next 30 days for search
      DateTime now = DateTime.now();
      DateTime futureDate = now.add(const Duration(days: 30));
      
      String startDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      String endDate = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';

      QuerySnapshot yogaSnapshot = await _firestore
          .collection('jadwalYoga')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      for (var doc in yogaSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final className = (data['className'] ?? '').toString().trim();
        final instructor = (data['instructor'] ?? '').toString().trim();
        
        if (className.toLowerCase().contains(query.toLowerCase().trim()) || 
            instructor.toLowerCase().contains(query.toLowerCase().trim())) {
          
          // Check if user already booked this class
          List<dynamic> bookedBy = data['bookedBy'] ?? [];
          bool alreadyBookedByUser = _currentUserId != null && bookedBy.contains(_currentUserId);
          
          results.add({
            'id': doc.id,
            'type': 'yoga_class',
            'category': 'Yoga Class',
            'name': '$className with $instructor',
            'className': className,
            'instructor': instructor,
            'time': data['time'] ?? '',
            'date': data['date'] ?? '',
            'spotsLeft': data['spotleft'] ?? 0,
            'harga': data['harga'] ?? 0,
            'alreadyBooked': alreadyBookedByUser,
            'description': 'Yoga class on ${data['date']} at ${data['time']}',
            ...data,
          });
        }
      }
    } catch (e) {
      print('Error searching yoga classes: $e');
    }
  }

  // Search Instructors - HANYA BERDASARKAN NAME
  Future<void> _searchInstructors(String query, List<Map<String, dynamic>> results) async {
    try {
      print('=== INSTRUCTOR SEARCH DEBUG ===');
      print('Search query: "$query"');
      print('Available instructors: ${_instructors.length}');
      
      final searchQuery = query.toLowerCase().trim();
      
      for (var instructor in _instructors) {
        // Debug: Print instructor data
        print('Checking instructor: ${instructor['id']}');
        
        // Ambil HANYA field name, pastikan tidak null dan trim
        final name = (instructor['name'] ?? '').toString().trim();
        
        print('Name: "$name"');
        
        // Check apakah name mengandung search query
        final nameContains = name.toLowerCase().contains(searchQuery);
        
        print('Name contains "$searchQuery": $nameContains');
        
        if (nameContains) {
          print('✓ MATCH FOUND - Adding instructor to results');
          results.add({
            'id': instructor['id'],
            'type': 'instructor',
            'category': 'Instructor',
            'name': name,
            'imageUrl': instructor['imageUrl'] ?? '',
            'description': instructor['description'] ?? 'Yoga Instructor',
            'instagram': instructor['instagram'] ?? '',
            // Simpan data asli untuk navigasi
            'originalData': instructor,
          });
        } else {
          print('✗ NO MATCH');
        }
        print('---');
      }
      
      print('=== END INSTRUCTOR SEARCH DEBUG ===');
    } catch (e) {
      print('Error searching instructors: $e');
    }
  }

  // Extract YouTube thumbnail from video URL
  String _extractYoutubeThumbnail(String videoUrl) {
    if (videoUrl.isEmpty) return '';
    
    try {
      RegExp regExp = RegExp(
        r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
        caseSensitive: false,
      );
      
      final match = regExp.firstMatch(videoUrl);
      if (match != null && match.group(1) != null) {
        String videoId = match.group(1)!;
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    } catch (e) {
      print('Error extracting thumbnail: $e');
    }
    
    return '';
  }

  // Navigate to appropriate page based on search result type
  void _navigateToSearchResult(Map<String, dynamic> result) {
    switch (result['type']) {
      case 'mini_class':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MiniClassPage(
              userData: _currentUserData,
              userId: _currentUserId,
            ),
          ),
        );
        break;
      case 'yoga_class':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingClassPage(
              userData: _currentUserData,
              userId: _currentUserId,
            ),
          ),
        );
        break;
      case 'instructor':
        // Gunakan originalData jika ada, atau result itu sendiri
        final instructorData = result['originalData'] ?? result;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstructorPage(
              instructorData: instructorData,
              userData: _currentUserData,
              userId: _currentUserId,
            ),
          ),
        );
        break;
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

  // Metode untuk navigasi ke halaman booking class
  void _navigateToBookingClass() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingClassPage(
          userData: _currentUserData,
          userId: _currentUserId,
        ),
      ),
    );
  }

  // Metode untuk navigasi ke halaman mini class
  void _navigateToMiniClass() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MiniClassPage(
          userData: _currentUserData,
          userId: _currentUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String username = _currentUserData != null ? _currentUserData!['username'] ?? 'Guest' : 'Guest';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: SafeArea(
        child: SingleChildScrollView(
          // PERBAIKAN: Kurangi padding bottom yang berlebihan
          padding: const EdgeInsets.only(bottom: 20), // Dari 100 menjadi 20
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
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFF2C5530)),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Hello, $username!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Enhanced Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      if (value.isNotEmpty) {
                        _performSearch(value);
                      } else {
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search videos, classes, or instructors...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                // Search Results
                if (_isSearching) ...[
                  const SizedBox(height: 16),
                  if (_isLoadingSearch)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2C5530),
                      ),
                    )
                  else if (_searchResults.isEmpty && _searchQuery.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No results found for "$_searchQuery"',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else if (_searchResults.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Search Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C5530),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C5530),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_searchResults.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return _buildSearchResultItem(result);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],

                // Rest of the dashboard content (hanya tampil jika tidak sedang search)
                if (!_isSearching) ...[
                  const SizedBox(height: 25),
                  _buildSectionHeader('Popular virtual mini class'),
                  const SizedBox(height: 15),
                  const SizedBox(height: 10),
                  
                  // FIXED: Responsive image grid with proper sizing
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double imageWidth = (constraints.maxWidth - 10) / 2;
                      double imageHeight = imageWidth * 0.8;
                      
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: imageWidth,
                                  height: imageHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFA3BE8C).withOpacity(0.3),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/yoga_pose1.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFA3BE8C).withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.self_improvement,
                                              size: 40,
                                              color: Color(0xFF2C5530),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildLevelButton('Beginner level 1', false),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  width: imageWidth,
                                  height: imageHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFFA3BE8C).withOpacity(0.3),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/yoga_pose2.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFA3BE8C).withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.self_improvement,
                                              size: 40,
                                              color: Color(0xFF2C5530),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildLevelButton('Intermediate level 2', false),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  _buildSeeAllRow('See all', onTap: _navigateToMiniClass),
                  const SizedBox(height: 25),
                  _buildSectionHeader('Yoga class everyday'),
                  const SizedBox(height: 15),
                  _buildDayButton('Sunday'),
                  const SizedBox(height: 10),
                  _buildDayButton('Tuesday'),
                  const SizedBox(height: 10),
                  _buildDayButton('Thursday'),
                  _buildSeeAllRow('See all', onTap: _navigateToBookingClass),
                  const SizedBox(height: 25),
                  _buildSectionHeader('Instructor'),
                  const SizedBox(height: 15),
                  _buildInstructorsList(),
                  // PERBAIKAN: Kurangi spacing di akhir
                  const SizedBox(height: 10), // Dari 20 menjadi 10
                ],
              ],
            ),
          ),
        ),
      ),
      // PERBAIKAN: Posisi floating action button yang lebih tepat
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20), // Dari 80 menjadi 20
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C5530).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToChatbot,
          backgroundColor: const Color(0xFF2C5530),
          foregroundColor: Colors.white,
          elevation: 0,
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // Build search result item
  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    Color categoryColor;
    IconData categoryIcon;
    
    switch (result['type']) {
      case 'mini_class':
        categoryColor = const Color(0xFFA3BE8C);
        categoryIcon = Icons.play_circle_outline;
        break;
      case 'yoga_class':
        categoryColor = const Color(0xFF8FA68E);
        categoryIcon = Icons.accessibility_new;
        break;
      case 'instructor':
        categoryColor = const Color(0xFF7A8471);
        categoryIcon = Icons.person;
        break;
      default:
        categoryColor = Colors.grey;
        categoryIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToSearchResult(result),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail/Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: categoryColor.withOpacity(0.3),
              ),
              child: result['type'] == 'mini_class' && result['thumbnailUrl'] != null && result['thumbnailUrl'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: result['thumbnailUrl'],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: Icon(categoryIcon, color: categoryColor, size: 24),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(categoryIcon, color: categoryColor, size: 24),
                        ),
                      ),
                    )
                  : result['type'] == 'instructor' && result['imageUrl'] != null && result['imageUrl'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: result['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Icon(categoryIcon, color: categoryColor, size: 24),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(categoryIcon, color: categoryColor, size: 24),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(categoryIcon, color: categoryColor, size: 24),
                        ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result['category'],
                      style: TextStyle(
                        fontSize: 10,
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Name
                  Text(
                    result['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C5530),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Description
                  Text(
                    result['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Additional info for yoga classes
                  if (result['type'] == 'yoga_class') ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (result['alreadyBooked'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BOOKED',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (result['spotsLeft'] != null)
                          Text(
                            ' • ${result['spotsLeft']} spots left',
                            style: TextStyle(
                              fontSize: 10,
                              color: result['spotsLeft'] > 0 ? Colors.grey.shade600 : Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Arrow icon
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF2C5530),
              size: 20,
            ),
          ],
        ),
      ),
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

  Widget _buildInstructorItemFromUrl(Map<String, dynamic> instructor) {
    final String name = instructor['name'] ?? 'Unknown';
    final String imageUrl = instructor['imageUrl'] ?? '';
    
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InstructorPage(
                    instructorData: instructor,
                    userData: _currentUserData,
                    userId: _currentUserId,
                  ),
                ),
              );
            },
            child: Container(
              width: 70, // Fixed size for consistency
              height: 70,
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
                        return Container(
                          color: const Color(0xFFA3BE8C).withOpacity(0.3),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C5530),
                              ),
                            ),
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
                            fontSize: 20,
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Widget helper methods
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
        fontSize: 14, // Slightly smaller for mobile
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSeeAllRow(String text, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onTap ?? () {},
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
    return GestureDetector(
      onTap: _navigateToBookingClass,
      child: Container(
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
      ),
    );
  }

  // PERBAIKAN: Bottom navigation bar dengan tinggi yang lebih sesuai
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
      child: SafeArea(
        top: false,
        child: Container(
          // PERBAIKAN: Tinggi yang lebih kompak
          height: 60, // Dari 70 menjadi 60
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16), // Kurangi padding vertical
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem('Home', Icons.home, true),
              _buildNavBarItem('Mini Class', Icons.self_improvement, false, onTap: _navigateToMiniClass),
              _buildNavBarItem('Yoga Class', Icons.accessibility_new, false, onTap: _navigateToBookingClass),
              _buildNavBarItem('Account', Icons.person, false, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountPage(
                      userData: _currentUserData,
                      userId: _currentUserId,
                    ),
                  ),
                );
              }),
            ],
          ),
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
      onTap: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
            size: 22,
          ),
          const SizedBox(height: 2), // Kurangi spacing
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2C5530) : Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
