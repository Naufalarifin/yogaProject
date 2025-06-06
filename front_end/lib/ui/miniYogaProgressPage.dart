import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard.dart';
import 'miniClassPage.dart';
import 'booking_class.dart';
import 'account.dart';

class MiniYogaProgressPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const MiniYogaProgressPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<MiniYogaProgressPage> createState() => _MiniYogaProgressPageState();
}

class _MiniYogaProgressPageState extends State<MiniYogaProgressPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _currentUserData;
  String? _userId;
  
  // Progress data
  String _userLevel = 'beginner';
  int _progressLevel = 0;
  List<String> _watchedVideos = [];
  
  // Video counts per level
  int _beginnerVideoCount = 0;
  int _intermediateVideoCount = 0;
  int _advancedVideoCount = 0;
  
  // Progress percentages
  double _beginnerProgress = 0.0;
  double _intermediateProgress = 0.0;
  double _advancedProgress = 0.0;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _userId = widget.userId ?? widget.userData?['userId'] ?? widget.userData?['id'];
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _fetchUserProgress();
    await _fetchVideoCountsAndCalculateProgress();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchUserProgress() async {
    if (_userId != null) {
      try {
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

          _currentUserData = {
            ..._currentUserData ?? {},
            'userId': _userId,
            'level': _userLevel,
            'progressLevel': _progressLevel,
            'watchedVideos': _watchedVideos,
          };
        }
      } catch (e) {
        print('Error fetching user progress: $e');
      }
    }
  }

  Future<void> _fetchVideoCountsAndCalculateProgress() async {
    try {
      // Fetch beginner videos
      QuerySnapshot beginnerSnapshot = await _firestore.collection('VidioBeginner').get();
      _beginnerVideoCount = beginnerSnapshot.docs.length;
      
      // Fetch intermediate videos
      QuerySnapshot intermediateSnapshot = await _firestore.collection('VideoIntermediate').get();
      _intermediateVideoCount = intermediateSnapshot.docs.length;
      
      // Fetch advanced videos
      QuerySnapshot advancedSnapshot = await _firestore.collection('VideoAdvanced').get();
      _advancedVideoCount = advancedSnapshot.docs.length;
      
      // Calculate progress for each level
      _calculateLevelProgress(beginnerSnapshot.docs, 'beginner');
      _calculateLevelProgress(intermediateSnapshot.docs, 'intermediate');
      _calculateLevelProgress(advancedSnapshot.docs, 'advanced');
      
    } catch (e) {
      print('Error fetching video counts: $e');
    }
  }

  void _calculateLevelProgress(List<QueryDocumentSnapshot> videos, String level) {
    if (videos.isEmpty) return;
    
    int watchedCount = 0;
    for (var video in videos) {
      if (_watchedVideos.contains(video.id)) {
        watchedCount++;
      }
    }
    
    double progress = watchedCount / videos.length;
    
    setState(() {
      switch (level) {
        case 'beginner':
          _beginnerProgress = progress;
          break;
        case 'intermediate':
          _intermediateProgress = progress;
          break;
        case 'advanced':
          _advancedProgress = progress;
          break;
      }
    });
  }

  void _navigateToPage(String route) {
    Widget page;
    switch (route) {
      case 'home':
        page = DashboardPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      case 'mini_class':
        page = MiniClassPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      case 'yoga_class':
        page = BookingClassPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      case 'account':
        page = AccountPage(
          userData: _currentUserData,
          userId: _userId,
        );
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String username = _currentUserData != null ? _currentUserData!['username'] ?? 'User' : 'User';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2C5530),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccountPage(
                                  userData: _currentUserData,
                                  userId: _userId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF2C5530),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Hello, $username!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C5530),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mini yoga class progress title
                    const Text(
                      'Mini yoga class progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5530),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Classes you've completed section
                    const Text(
                      'classes you\'ve completed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Progress levels
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Beginner Level
                            _buildLevelCard(
                              'Beginner level 1',
                              'Gentle Beginnings',
                              _beginnerProgress,
                              _beginnerVideoCount,
                              _userLevel == 'beginner' || _userLevel == 'intermediate' || _userLevel == 'advanced',
                              const Color(0xFFA3BE8C),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Intermediate Level
                            _buildLevelCard(
                              'Intermediate level 2',
                              'Building Strength',
                              _intermediateProgress,
                              _intermediateVideoCount,
                              _userLevel == 'intermediate' || _userLevel == 'advanced',
                              const Color(0xFF8FA68E),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Advanced Level
                            _buildLevelCard(
                              'Advanced level 3',
                              'Master Flow',
                              _advancedProgress,
                              _advancedVideoCount,
                              _userLevel == 'advanced',
                              const Color(0xFF7A8471),
                            ),
                            
                            // Add bottom padding to prevent content from being hidden behind bottom nav
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLevelCard(
    String levelTitle,
    String subtitle,
    double progress,
    int totalVideos,
    bool isUnlocked,
    Color color,
  ) {
    int watchedVideos = (progress * totalVideos).round();
    int progressPercentage = (progress * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level title and lock status
          Row(
            children: [
              Expanded(
                child: Text(
                  levelTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? const Color(0xFF2C5530) : Colors.grey,
                  ),
                ),
              ),
              if (!isUnlocked)
                Icon(
                  Icons.lock,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
          
          if (isUnlocked) ...[
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress section with circular progress
            Row(
              children: [
                // Circular Progress Indicator
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      // Background circle
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      // Percentage text in center
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '$progressPercentage%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Progress details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress bar (horizontal)
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey.shade200,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Progress text
                      Text(
                        '$watchedVideos of $totalVideos videos completed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Additional progress info
                      Text(
                        '${totalVideos - watchedVideos} videos remaining',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            
            // Locked message with circular indicator
            Row(
              children: [
                // Locked circular indicator
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      // Background circle
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                        ),
                      ),
                      // Lock icon in center
                      Positioned.fill(
                        child: Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Locked message
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level Locked',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete previous level to unlock',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem('Home', Icons.home, false, 'home'),
              _buildNavBarItem('Mini Class', Icons.self_improvement, true, 'mini_class'),
              _buildNavBarItem('Yoga Class', Icons.accessibility_new, false, 'yoga_class'),
              _buildNavBarItem('Account', Icons.person, false, 'account'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(String label, IconData icon, bool isActive, String route) {
    return GestureDetector(
      onTap: () => _navigateToPage(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
          ),
          const SizedBox(height: 2),
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
