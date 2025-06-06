import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'booking_class.dart';
import 'account.dart';
import 'dashboard.dart'; // Import dashboard untuk navigasi
import 'beginnerVideosPage.dart';
import 'intermediateVideosPage.dart';
import 'advancedVideosPage.dart';

class MiniClassPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const MiniClassPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<MiniClassPage> createState() => _MiniClassPageState();
}

class _MiniClassPageState extends State<MiniClassPage> {
  final List<Map<String, dynamic>> _beginnerVideos = [];
  final List<Map<String, dynamic>> _intermediateVideos = [];
  final List<Map<String, dynamic>> _advancedVideos = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _currentUserData;
  String? _userId;
  
  // User progress tracking (read-only for display)
  String _userLevel = 'beginner';
  int _progressLevel = 0;
  List<String> _watchedVideos = [];

  // Search functionality
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _userId = widget.userId ?? widget.userData?['userId'] ?? widget.userData?['id'];
    _initializeUserProgress();
    _fetchAllVideos();
  }

  // Initialize user progress from userData or Firebase (read-only)
  Future<void> _initializeUserProgress() async {
    if (_userId != null) {
      try {
        // Get user data from Firebase
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_userId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _userLevel = userData['level'] ?? 'beginner';
            _progressLevel = userData['progressLevel'] ?? 0;
            _watchedVideos = List<String>.from(userData['watchedVideos'] ?? []);
          });

          // Update current user data
          _currentUserData = {
            ..._currentUserData ?? {},
            'userId': _userId,
            'level': _userLevel,
            'progressLevel': _progressLevel,
            'watchedVideos': _watchedVideos,
          };
        } else {
          // Create default user data if doesn't exist
          String username = _currentUserData?['username'] ?? 'User';
          String email = _currentUserData?['email'] ?? '';
          
          await _firestore.collection('users').doc(_userId).set({
            'level': 'beginner',
            'progressLevel': 0,
            'watchedVideos': [],
            'username': username,
            'email': email,
            'userId': _userId,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          setState(() {
            _userLevel = 'beginner';
            _progressLevel = 0;
            _watchedVideos = [];
          });
          
          // Update current user data
          _currentUserData = {
            ..._currentUserData ?? {},
            'userId': _userId,
            'level': 'beginner',
            'progressLevel': 0,
            'watchedVideos': [],
            'username': username,
            'email': email,
          };
        }
      } catch (e) {
        print('MiniClassPage - Error initializing user progress: $e');
      }
    }
  }

  // Fetch all videos from different collections
  Future<void> _fetchAllVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch beginner videos
      await _fetchBeginnerVideos();
      // Fetch intermediate videos
      await _fetchIntermediateVideos();
      // Fetch advanced videos
      await _fetchAdvancedVideos();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch beginner videos
  Future<void> _fetchBeginnerVideos() async {
    try {
      final QuerySnapshot videosSnapshot = 
          await _firestore.collection('VidioBeginner').get();
      
      if (videosSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempList = [];
        
        for (var doc in videosSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          String videoId = _extractYoutubeVideoId(data['link'] ?? '');
          
          tempList.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Title',
            'link': data['link'] ?? '',
            'videoId': videoId,
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'level': 'beginner',
            'isWatched': _watchedVideos.contains(doc.id),
            ...data, 
          });
        }
        
        setState(() {
          _beginnerVideos.clear();
          _beginnerVideos.addAll(tempList);
        });
      }
    } catch (e) {
      print('Error fetching beginner videos: $e');
    }
  }

  // Fetch intermediate videos
  Future<void> _fetchIntermediateVideos() async {
    try {
      final QuerySnapshot videosSnapshot = 
          await _firestore.collection('VideoIntermediate').get();
      
      if (videosSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempList = [];
        
        for (var doc in videosSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          String videoId = _extractYoutubeVideoId(data['link'] ?? '');
          
          tempList.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Title',
            'link': data['link'] ?? '',
            'videoId': videoId,
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'level': 'intermediate',
            'isWatched': _watchedVideos.contains(doc.id),
            ...data, 
          });
        }
        
        setState(() {
          _intermediateVideos.clear();
          _intermediateVideos.addAll(tempList);
        });
      }
    } catch (e) {
      print('Error fetching intermediate videos: $e');
    }
  }

  // Fetch advanced videos
  Future<void> _fetchAdvancedVideos() async {
    try {
      final QuerySnapshot videosSnapshot = 
          await _firestore.collection('VideoAdvanced').get();
      
      if (videosSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempList = [];
        
        for (var doc in videosSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          String videoId = _extractYoutubeVideoId(data['link'] ?? '');
          
          tempList.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Title',
            'link': data['link'] ?? '',
            'videoId': videoId,
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'level': 'advanced',
            'isWatched': _watchedVideos.contains(doc.id),
            ...data, 
          });
        }
        
        setState(() {
          _advancedVideos.clear();
          _advancedVideos.addAll(tempList);
        });
      }
    } catch (e) {
      print('Error fetching advanced videos: $e');
    }
  }

  // Extract YouTube video ID from URL
  String _extractYoutubeVideoId(String videoUrl) {
    if (videoUrl.isEmpty) return '';
    
    try {
      RegExp regExp = RegExp(
        r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
        caseSensitive: false,
      );
      
      final match = regExp.firstMatch(videoUrl);
      if (match != null && match.group(1) != null) {
        return match.group(1)!;
      }
    } catch (e) {
      print('Error extracting video ID: $e');
    }
    
    return '';
  }

  // Extract YouTube thumbnail from video URL
  String _extractYoutubeThumbnail(String videoUrl) {
    if (videoUrl.isEmpty) return '';
    
    try {
      String videoId = _extractYoutubeVideoId(videoUrl);
      if (videoId.isNotEmpty) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    } catch (e) {
      print('Error extracting thumbnail: $e');
    }
    
    return '';
  }

  // Search videos across all levels
  Future<void> _searchVideos(String query) async {
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
      List<Map<String, dynamic>> allVideos = [];
      
      // Combine all videos from different levels
      allVideos.addAll(_beginnerVideos.map((video) => {...video, 'level': 'beginner'}));
      allVideos.addAll(_intermediateVideos.map((video) => {...video, 'level': 'intermediate'}));
      allVideos.addAll(_advancedVideos.map((video) => {...video, 'level': 'advanced'}));
      
      // Filter videos based on search query
      List<Map<String, dynamic>> filteredVideos = allVideos.where((video) {
        final videoName = video['name'].toString().toLowerCase();
        final searchQuery = query.toLowerCase().trim();
        
        return videoName.contains(searchQuery);
      }).toList();

      setState(() {
        _searchResults = filteredVideos;
        _isLoadingSearch = false;
      });

    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
    }
  }

  // Navigate to specific level page (NO PROGRESS TRACKING HERE)
  void _navigateToLevelPage(String level) {
    Widget targetPage;
    
    switch (level) {
      case 'beginner':
        targetPage = BeginnerVideosPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      case 'intermediate':
        targetPage = IntermediateVideosPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      case 'advanced':
        targetPage = AdvancedVideosPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      default:
        targetPage = BeginnerVideosPage(
          userData: _currentUserData,
          userId: _userId,
        );
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  // PERBAIKAN: Navigation methods for bottom nav bar
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          userData: _currentUserData,
          userId: _userId,
        ),
      ),
    );
  }

  void _navigateToYogaClass() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingClassPage(
          userData: _currentUserData,
          userId: _userId,
        ),
      ),
    );
  }

  void _navigateToAccount() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AccountPage(
          userData: _currentUserData,
          userId: _userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String username = _currentUserData != null ? _currentUserData!['username'] ?? 'User' : 'User';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Hello, $username!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C5530),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.isNotEmpty) {
                      _searchVideos(value);
                    } else {
                      setState(() {
                        _searchResults = [];
                        _isSearching = false;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search videos...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
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
            ),

            // Search Results
            if (_isSearching) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            'No videos found for "$_searchQuery"',
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
                            final video = _searchResults[index];
                            return _buildSearchVideoItem(video);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 20),

            // Title Section dengan informasi user level
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Virtual mini class',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5530),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // User level badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5530),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          'Current Level: ${_userLevel.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Platform info untuk web
                      if (kIsWeb)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'Web Ready',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Level Categories
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2C5530),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Beginner Level Section
                          _buildLevelSection(
                            'Beginner Level 1',
                            _beginnerVideos,
                            'beginner',
                            const Color(0xFFA3BE8C),
                            _userLevel == 'beginner' || _userLevel == 'intermediate' || _userLevel == 'advanced',
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Intermediate Level Section
                          _buildLevelSection(
                            'Intermediate Level 2',
                            _intermediateVideos,
                            'intermediate',
                            const Color(0xFF8FA68E),
                            _userLevel == 'intermediate' || _userLevel == 'advanced',
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Advanced Level Section
                          _buildLevelSection(
                            'Advanced Level 3',
                            _advancedVideos,
                            'advanced',
                            const Color(0xFF7A8471),
                          _userLevel == 'advanced',
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLevelSection(
    String title,
    List<Map<String, dynamic>> videos,
    String level,
    Color color,
    bool isUnlocked,
  ) {
    // Count watched videos for this level
    int watchedCount = videos.where((video) => video['isWatched'] == true).length;
    int totalCount = videos.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked ? color : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF2C5530) : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (!isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LOCKED',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isUnlocked && totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$watchedCount/$totalCount completed',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Progress bar for unlocked levels
        if (isUnlocked && totalCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? watchedCount / totalCount : 0.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        
        // Videos Grid or Lock Message
        if (!isUnlocked)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 32,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete previous level to unlock',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (videos.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No videos available for this level',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              // Video thumbnails (show first 3) - INCREASED SIZE AND SPACING
              SizedBox(
                height: 100, // Increased from 70 to 100
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: videos.length > 3 ? 3 : videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return _buildVideoThumbnail(video, color);
                  },
                ),
              ),
              
              const SizedBox(height: 16), // Increased spacing
              
              // View All Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToLevelPage(level),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text('View All ${videos.length} Videos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: const Color(0xFF2C5530),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildVideoThumbnail(Map<String, dynamic> video, Color levelColor) {
    final String name = video['name'] ?? 'Unknown Title';
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';
    final bool isWatched = video['isWatched'] ?? false;

    return Container(
      width: 120, // Increased from 90 to 120
      margin: const EdgeInsets.only(right: 20), // Increased spacing between items
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail - INCREASED SIZE
          Stack(
            children: [
              Container(
                width: 120, // Increased from 90 to 120
                height: 68, // Increased from 45 to 68 (maintaining 16:9 aspect ratio)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), // Slightly larger border radius
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: levelColor.withOpacity(0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return Container(
                                  color: levelColor.withOpacity(0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 24, // Increased icon size
                                      color: Color(0xFF2C5530),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: levelColor.withOpacity(0.3),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 24, // Increased icon size
                                  color: Color(0xFF2C5530),
                                ),
                              ),
                            ),
                      // Play button overlay
                      const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          size: 28, // Increased from 20 to 28
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Watched indicator
              if (isWatched)
                Positioned(
                  top: 4, // Adjusted position
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 6), // Increased spacing
          
          // Video title
          Text(
            name,
            style: TextStyle(
              fontSize: 11, // Slightly increased font size
              fontWeight: FontWeight.w500,
              color: isWatched ? Colors.grey : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchVideoItem(Map<String, dynamic> video) {
    final String name = video['name'] ?? 'Unknown Title';
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';
    final bool isWatched = video['isWatched'] ?? false;
    final String level = video['level'] ?? 'beginner';
    final bool isUnlocked = level == 'beginner' || 
                            (level == 'intermediate' && (_userLevel == 'intermediate' || _userLevel == 'advanced')) ||
                            (level == 'advanced' && _userLevel == 'advanced');

    Color levelColor;
    switch (level) {
      case 'intermediate':
        levelColor = const Color(0xFF8FA68E);
        break;
      case 'advanced':
        levelColor = const Color(0xFF7A8471);
        break;
      default:
        levelColor = const Color(0xFFA3BE8C);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Increased margin
      padding: const EdgeInsets.all(16), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Increased border radius
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Thumbnail - INCREASED SIZE
          Stack(
            children: [
              Container(
                width: 100, // Increased from 80 to 100
                height: 75, // Increased from 60 to 75
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: levelColor.withOpacity(0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return Container(
                                  color: levelColor.withOpacity(0.3),
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 24, // Increased icon size
                                      color: Color(0xFF2C5530),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: levelColor.withOpacity(0.3),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 24, // Increased icon size
                                  color: Color(0xFF2C5530),
                                ),
                              ),
                            ),
                      // Play button overlay
                      const Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          size: 30, // Increased from 24 to 30
                          color: Colors.white,
                        ),
                      ),
                      // Lock overlay for locked videos
                      if (!isUnlocked)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 20, // Increased icon size
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Watched indicator
              if (isWatched && isUnlocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3), // Increased padding
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10, // Increased icon size
                    ),
                  ),
                ),
            ],
          ),

        const SizedBox(width: 16), // Increased spacing

        // Video Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 15, // Increased font size
                  fontWeight: FontWeight.w600,
                  color: isWatched ? Colors.grey : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // Increased spacing
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Increased padding
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10), // Increased border radius
                    ),
                    child: Text(
                      level.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11, // Increased font size
                        color: Color(0xFF2C5530),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'LOCKED',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isWatched && isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'WATCHED',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 12), // Added spacing before button

        // Action Button
        ElevatedButton(
          onPressed: isUnlocked 
              ? () => _navigateToLevelPage(level)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isUnlocked ? levelColor : Colors.grey.shade300,
            foregroundColor: isUnlocked ? const Color(0xFF2C5530) : Colors.grey.shade600,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18), // Increased border radius
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased padding
          ),
          child: Text(
            isUnlocked ? 'View' : 'Locked',
            style: const TextStyle(fontSize: 13), // Increased font size
          ),
        ),
      ],
    ),
  );
}

  // PERBAIKAN: Bottom navigation bar yang sesuai dengan dashboard dan account page
  Widget _buildBottomNavBar() {
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
              _buildNavBarItem(
                'Home', 
                Icons.home, 
                false, 
                onTap: _navigateToHome,
              ),
              _buildNavBarItem(
                'Mini Class', 
                Icons.self_improvement, 
                true, // Current page is active
                onTap: () {}, // Already on this page
              ),
              _buildNavBarItem(
                'Yoga Class', 
                Icons.accessibility_new, 
                false,
                onTap: _navigateToYogaClass,
              ),
              _buildNavBarItem(
                'Account', 
                Icons.person, 
                false,
                onTap: _navigateToAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PERBAIKAN: NavBar item yang sesuai dengan dashboard dan account page
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
            size: 22, // Ukuran yang lebih kecil
          ),
          const SizedBox(height: 2), // Kurangi spacing
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2C5530) : Colors.black54,
              fontSize: 11, // Ukuran font yang lebih kecil
            ),
          ),
        ],
      ),
    );
  }
}
