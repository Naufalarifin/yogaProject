import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'booking_class.dart';
import 'account.dart';
import 'miniClassPage.dart';
import 'dashboard.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BeginnerVideosPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const BeginnerVideosPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<BeginnerVideosPage> createState() => _BeginnerVideosPageState();
}

class _BeginnerVideosPageState extends State<BeginnerVideosPage> {
  final List<Map<String, dynamic>> _beginnerVideos = [];
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _currentUserData;
  String? _userId;
  
  // User progress tracking
  String _userLevel = 'beginner';
  int _progressLevel = 0;
  List<String> _watchedVideos = [];
  int _totalBeginnerVideos = 0;

  @override
  void initState() {
    super.initState();
    _currentUserData = widget.userData;
    _userId = widget.userId ?? widget.userData?['userId'] ?? widget.userData?['id'];
    _initializeUserProgress();
    _fetchBeginnerVideos();
  }

  // Initialize user progress from userData or Firebase
  Future<void> _initializeUserProgress() async {
    if (_userId != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_userId!)
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
        print('Error initializing user progress: $e');
      }
    }
  }

  // Metode untuk mengambil data video beginner dari Firestore
  Future<void> _fetchBeginnerVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot videosSnapshot = 
          await _firestore.collection('VidioBeginner').get();
      
      print('Beginner videos count: ${videosSnapshot.docs.length}');
      
      if (videosSnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempList = [];
        
        for (var doc in videosSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing video: ${doc.id}');
          print('Video data: $data');
          
          String videoId = _extractYoutubeVideoId(data['link'] ?? '');
          
          tempList.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Title',
            'link': data['link'] ?? '',
            'videoId': videoId,
            'thumbnailUrl': _extractYoutubeThumbnail(data['link'] ?? ''),
            'isWatched': _watchedVideos.contains(doc.id),
            ...data, 
          });
        }
        
        setState(() {
          _beginnerVideos.clear();
          _beginnerVideos.addAll(tempList);
          _totalBeginnerVideos = tempList.length;
          _isLoading = false;
        });
        
        print('Successfully loaded ${_beginnerVideos.length} videos');
      } else {
        print('No beginner videos found in Firestore');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching beginner videos: $e');
      setState(() {
        _isLoading = false;
      });
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

  // Navigate to video player page with progress tracking
  void _playVideo(String videoId, String videoTitle, String videoUrl, String docId) async {
    if (!_watchedVideos.contains(docId)) {
      await _markVideoAsWatched(docId);
    }
    
    if (videoId.isNotEmpty) {
      if (kIsWeb) {
        _showWebVideoPlayer(videoId, videoTitle);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YouTubePlayerPage(
              videoId: videoId,
              videoTitle: videoTitle,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid video URL'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mark video as watched and update progress
  Future<void> _markVideoAsWatched(String videoId) async {
    if (_userId == null) return;
    
    try {
      if (!_watchedVideos.contains(videoId)) {
        setState(() {
          _watchedVideos.add(videoId);
          
          for (int i = 0; i < _beginnerVideos.length; i++) {
            if (_beginnerVideos[i]['id'] == videoId) {
              _beginnerVideos[i]['isWatched'] = true;
              break;
            }
          }
        });
        
        if (_userLevel == 'beginner') {
          int newProgress = _progressLevel + 1;
          
          setState(() {
            _progressLevel = newProgress;
          });
          
          if (newProgress >= _totalBeginnerVideos) {
            await _upgradeToIntermediate();
          } else {
            await _firestore.collection('users').doc(_userId!).update({
              'progressLevel': newProgress,
              'watchedVideos': _watchedVideos,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            
            _currentUserData = {
              ..._currentUserData ?? {},
              'userId': _userId,
              'progressLevel': newProgress,
              'watchedVideos': _watchedVideos,
            };
          }
        } else {
          await _firestore.collection('users').doc(_userId!).update({
            'watchedVideos': _watchedVideos,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error marking video as watched: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating progress: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upgrade user to intermediate level and reset progress
  Future<void> _upgradeToIntermediate() async {
    if (_userId == null) return;
    
    try {
      await _firestore.collection('users').doc(_userId!).update({
        'level': 'intermediate',
        'progressLevel': 0,
        'watchedVideos': _watchedVideos,
        'lastUpdated': FieldValue.serverTimestamp(),
        'levelUpgradeDate': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _userLevel = 'intermediate';
        _progressLevel = 0;
      });
      
      _currentUserData = {
        ..._currentUserData ?? {},
        'userId': _userId,
        'level': 'intermediate',
        'progressLevel': 0,
        'watchedVideos': _watchedVideos,
      };
      
      _showLevelUpgradeDialog();
      
    } catch (e) {
      print('Error upgrading user level: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error upgrading level: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show level upgrade dialog when user completes all beginner videos
  void _showLevelUpgradeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Level Up!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎉 Congratulations!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You have completed all beginner level videos and have been upgraded to:',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C5530),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'INTERMEDIATE LEVEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can now access intermediate level content, and you can still watch beginner videos anytime!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MiniClassPage(
                      userData: _currentUserData,
                      userId: _userId,
                    ),
                  ),
                );
              },
              child: const Text(
                'Continue to Intermediate',
                style: TextStyle(
                  color: Color(0xFF2C5530),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Menampilkan video untuk web menggunakan iframe YouTube
  void _showWebVideoPlayer(String videoId, String videoTitle) {
    if (kIsWeb) {
      print('Web platform detected but not supported in mobile build');
      return;
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C5530),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            videoTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        child: WebViewWidget(
                          controller: WebViewController()
                            ..setJavaScriptMode(JavaScriptMode.unrestricted)
                            ..setBackgroundColor(const Color(0x00000000))
                            ..setNavigationDelegate(
                              NavigationDelegate(
                                onProgress: (int progress) {},
                                onPageStarted: (String url) {},
                                onPageFinished: (String url) {},
                                onWebResourceError: (WebResourceError error) {},
                              ),
                            )
                            ..loadRequest(Uri.parse('https://www.youtube.com/embed/$videoId?autoplay=1&enablejsapi=1')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  // Navigate to specific page
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
      backgroundColor: const Color(0xFFFCF9F3),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MiniClassPage(
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
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'What do you need?',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title Section dengan informasi platform dan progress
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA3BE8C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Beginner level 3',
                          style: TextStyle(
                            color: Color(0xFF2C5530),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5530),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _userLevel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (kIsWeb)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'Web Player Ready',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  if (_userLevel == 'beginner')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress: $_progressLevel/$_totalBeginnerVideos videos completed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2C5530),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _totalBeginnerVideos > 0 
                                ? _progressLevel / _totalBeginnerVideos 
                                : 0.0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA3BE8C)),
                          ),
                        ],
                      ),
                    ),
                    
                  if (_userLevel == 'intermediate')
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are now at intermediate level! You can still access and review beginner videos anytime.',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_userLevel == 'advanced')
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.purple.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are now at advanced level! You can still access and review beginner videos anytime.',
                              style: TextStyle(
                                color: Colors.purple.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Videos List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2C5530),
                      ),
                    )
                  : _beginnerVideos.isEmpty
                      ? const Center(
                          child: Text(
                            'No beginner videos available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            bottom: 16.0, // Reduced bottom padding
                          ),
                          itemCount: _beginnerVideos.length,
                          itemBuilder: (context, index) {
                            final video = _beginnerVideos[index];
                            return _buildVideoItem(video);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    final String name = video['name'] ?? 'Unknown Title';
    final String videoId = video['videoId'] ?? '';
    final String videoUrl = video['link'] ?? '';
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';
    final String docId = video['id'] ?? '';
    final bool isWatched = video['isWatched'] ?? false;

    return GestureDetector(
      onTap: () => _playVideo(videoId, name, videoUrl, docId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 90,
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
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF2C5530),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) {
                                  return Container(
                                    color: const Color(0xFFA3BE8C).withOpacity(0.3),
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_outline,
                                        size: 30,
                                        color: Color(0xFF2C5530),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFFA3BE8C).withOpacity(0.3),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 30,
                                    color: Color(0xFF2C5530),
                                  ),
                                ),
                              ),
                        
                        if (!isWatched)
                          const Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isWatched)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isWatched ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        isWatched ? 'Watched' : (kIsWeb ? 'Tap to play in app' : 'Tap to play'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isWatched ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isWatched ? Icons.check_circle_outline : Icons.play_arrow,
                        size: 16,
                        color: isWatched ? Colors.green : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA3BE8C).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      kIsWeb ? 'YouTube (Embedded)' : 'YouTube Video',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2C5530),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom navigation bar dengan styling yang konsisten
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

  // NavBar item dengan styling yang konsisten
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

// YouTube Player Page - TETAP UNTUK MOBILE
class YouTubePlayerPage extends StatefulWidget {
  final String videoId;
  final String videoTitle;

  const YouTubePlayerPage({
    super.key,
    required this.videoId,
    required this.videoTitle,
  });

  @override
  State<YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        captionLanguage: 'id',
        showLiveFullscreenButton: true,
        forceHD: false,
        useHybridComposition: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isReady && !_isPlayerReady) {
        setState(() {
          _isPlayerReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]); 
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF2C5530),
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              widget.videoTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: () {},
          ),
        ],
        onReady: () {
          print('YouTube player is ready');
          setState(() {
            _isPlayerReady = true;
          });
        },
        onEnded: (data) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video completed!'),
                backgroundColor: Color(0xFF2C5530),
              ),
            );
          }
        },
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: const Color(0xFFFCF9F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C5530),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.videoTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          elevation: 0,
        ),
        body: Column(
          children: [
            Stack(
              children: [
                player,
                if (!_isPlayerReady)
                  Container(
                    height: 200,
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading video...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.videoTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C5530),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF2C5530),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Video Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C5530),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This is a beginner level yoga tutorial video. Follow along at your own pace and remember to listen to your body.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA3BE8C).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Beginner Level',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2C5530),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_isPlayerReady)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_controller.value.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5530),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              _controller.seekTo(Duration.zero);
                              _controller.play();
                            },
                            icon: const Icon(Icons.replay),
                            label: const Text('Restart'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA3BE8C),
                              foregroundColor: const Color(0xFF2C5530),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}