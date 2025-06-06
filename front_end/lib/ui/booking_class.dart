import 'package:flutter/material.dart';
import 'package:front_end/ui/miniClassPage.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'account.dart'; // Import account page
import 'bookingDetail.dart';

class BookingClassPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const BookingClassPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<BookingClassPage> createState() => _BookingClassPageState();
}

// Class untuk halaman kelas yoga
class YogaClassesPage extends StatefulWidget {
  final List<DateTime> availableDates;
  final String dayName;
  final Map<String, dynamic>? userData;
  final String? userId;
  
  const YogaClassesPage({
    super.key,
    required this.availableDates,
    required this.dayName,
    this.userData,
    this.userId,
  });

  @override
  State<YogaClassesPage> createState() => _YogaClassesPageState();
}

class _YogaClassesPageState extends State<YogaClassesPage> {
  late DateTime _selectedDate;
  int _currentDateIndex = 0;
  List<Map<String, dynamic>> yogaClasses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.availableDates.isNotEmpty ? widget.availableDates[0] : DateTime.now();
    _fetchYogaClasses();
  }

  void _nextDate() {
    if (_currentDateIndex < widget.availableDates.length - 1) {
      setState(() {
        _currentDateIndex++;
        _selectedDate = widget.availableDates[_currentDateIndex];
        _fetchYogaClasses(); // Fetch classes for new date
      });
    }
  }

  void _prevDate() {
    if (_currentDateIndex > 0) {
      setState(() {
        _currentDateIndex--;
        _selectedDate = widget.availableDates[_currentDateIndex];
        _fetchYogaClasses(); // Fetch classes for new date
      });
    }
  }

  // Function to fetch yoga classes from Firebase based on specific date
  Future<void> _fetchYogaClasses() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Format the selected date to match Firebase format (YYYY-MM-DD)
      String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      print('Fetching classes for date: $dateString'); // Debug log
      
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('jadwalYoga')
          .where('date', isEqualTo: dateString)
          .get();

      List<Map<String, dynamic>> fetchedClasses = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // MENAMPILKAN SEMUA CLASS TANPA FILTER
        List<dynamic> bookedBy = data['bookedBy'] ?? [];
        bool alreadyBookedByUser = widget.userId != null && bookedBy.contains(widget.userId);
        
        print('Found class: ${data['className']} on ${data['date']}'); // Debug log
        
        fetchedClasses.add({
          'id': doc.id,
          'name': '${data['className']} with ${data['instructor']}',
          'time': data['time'],
          'spots': '${data['spotleft']}/10 spots left',
          'spotsLeft': data['spotleft'],
          'instructor': data['instructor'],
          'className': data['className'],
          'harga': data['harga'],
          'bookedBy': data['bookedBy'] ?? [],
          'date': data['date'],
          'image': _getImageForClass(data['className']),
          'alreadyBooked': alreadyBookedByUser, // Tambahkan status booking untuk UI
        });
      }

      setState(() {
        yogaClasses = fetchedClasses;
        isLoading = false;
      });
      
      print('Total classes: ${fetchedClasses.length}'); // Debug log
    } catch (e) {
      print('Error fetching yoga classes: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading yoga classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper function to get image based on class name
  String _getImageForClass(String className) {
    if (className.toLowerCase().contains('hatha')) {
      return 'assets/yoga1.jpg';
    } else if (className.toLowerCase().contains('bliss') || className.toLowerCase().contains('afternoon')) {
      return 'assets/yoga2.jpg';
    } else if (className.toLowerCase().contains('yin')) {
      return 'assets/yoga3.jpg';
    } else {
      return 'assets/yoga1.jpg'; // Default image
    }
  }

  // Function to handle booking
  Future<void> _bookClass(Map<String, dynamic> yogaClass) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book a class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cek apakah user sudah booking class ini
    if (yogaClass['alreadyBooked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already booked this class'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (yogaClass['spotsLeft'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No spots available for this class'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Navigate ke BookingDetailPage dan tunggu result
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailPage(
            yogaClass: yogaClass,
            userData: widget.userData,
            userId: widget.userId,
            selectedDate: _selectedDate,
          ),
        ),
      );

      // Jika booking berhasil (result == true), refresh data
      if (result == true) {
        await _fetchYogaClasses(); // Refresh list untuk update tampilan
      }
    } catch (e) {
      print('Error booking class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigation methods for bottom nav bar
  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _navigateToMiniClass() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MiniClassPage(
          userData: widget.userData,
          userId: widget.userId,
        ),
      ),
    );
  }

  void _navigateToAccount() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AccountPage(
          userData: widget.userData,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header tanpa AppBar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yoga Classes',
                    style: TextStyle(
                      color: Color(0xFF2C5530),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Yoga Class Everyday',
                    style: TextStyle(
                      color: Color(0xFF2C5530),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date navigator
                  if (widget.availableDates.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Color(0xFF2C5530)),
                          onPressed: _currentDateIndex > 0 ? _prevDate : null,
                          color: _currentDateIndex > 0 ? const Color(0xFF2C5530) : Colors.grey,
                        ),
                        Text(
                          '${DateFormat('E, d MMM yyyy').format(_selectedDate)}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF2C5530)),
                          onPressed: _currentDateIndex < widget.availableDates.length - 1 ? _nextDate : null,
                          color: _currentDateIndex < widget.availableDates.length - 1 ? const Color(0xFF2C5530) : Colors.grey,
                        ),
                      ],
                    )
                  else
                    Text(
                      '${DateFormat('E, d MMM yyyy').format(_selectedDate)}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  
                  if (widget.availableDates.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Showing ${_currentDateIndex + 1} of ${widget.availableDates.length} ${widget.dayName}s in ${DateFormat('MMMM yyyy').format(_selectedDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // List of yoga classes
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2C5530),
                      ),
                    )
                  : yogaClasses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No yoga classes available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'for ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: yogaClasses.length,
                          itemBuilder: (context, index) {
                            final yogaClass = yogaClasses[index];
                            bool isAlreadyBooked = yogaClass['alreadyBooked'] ?? false;
                            bool hasSpots = yogaClass['spotsLeft'] > 0;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: isAlreadyBooked 
                                      ? Border.all(color: Colors.green, width: 2)
                                      : null,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Yoga image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            yogaClass['image'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 100,
                                              height: 100,
                                              color: Colors.grey.shade300,
                                              child: Icon(
                                                Icons.fitness_center,
                                                color: Colors.grey.shade700,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                          if (isAlreadyBooked)
                                            Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(8.0),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 16.0),
                                    
                                    // Yoga class details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            yogaClass['name'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isAlreadyBooked 
                                                  ? Colors.green.shade700 
                                                  : const Color(0xFF2C5530),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            yogaClass['spots'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: hasSpots 
                                                  ? Colors.grey.shade700 
                                                  : Colors.red,
                                            ),
                                          ),
                                          Text(
                                            yogaClass['time'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (isAlreadyBooked)
                                            const Text(
                                              'Already Booked',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Book button
                                    ElevatedButton(
                                      onPressed: isAlreadyBooked 
                                          ? null 
                                          : (hasSpots ? () => _bookClass(yogaClass) : null),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isAlreadyBooked
                                            ? Colors.green
                                            : (hasSpots ? const Color(0xFFA3BE8C) : Colors.grey),
                                        foregroundColor: isAlreadyBooked
                                            ? Colors.white
                                            : const Color(0xFF2C5530),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text(
                                        isAlreadyBooked 
                                            ? 'Booked' 
                                            : (hasSpots ? 'Book' : 'Full'),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
              _buildNavBarItem(
                'Home', 
                Icons.home, 
                false, 
                onTap: _navigateToHome,
              ),
              _buildNavBarItem(
                'Mini Class', 
                Icons.self_improvement, 
                false, 
                onTap: _navigateToMiniClass,
              ),
              _buildNavBarItem(
                'Yoga Class', 
                Icons.accessibility_new, 
                true, // Current page is active
                onTap: () {}, // Already on this page
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
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
            size: 22,
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

class _BookingClassPageState extends State<BookingClassPage> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  // Date state for the calendar
  DateTime _selectedDate = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _dateSpecificallySelected = false;
  
  // List of all days of the week
  final List<String> _weekdays = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Show date picker dialog using Flutter's built-in MaterialDatePicker
  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C5530),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedYear = picked.year;
        _selectedMonth = picked.month;
        _dateSpecificallySelected = true;
      });
    }
  }
  
  // Clear specific date selection
  void _clearDateSelection() {
    setState(() {
      _dateSpecificallySelected = false;
    });
  }

  // Get all available dates from Firebase for a specific weekday in the selected month
  Future<List<DateTime>> _getAvailableDatesForWeekday(String weekdayName) async {
    try {
      List<DateTime> availableDates = [];
      
      // Get start and end of the selected month
      DateTime startOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
      DateTime endOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
      
      // Format dates for Firebase query
      String startDateString = DateFormat('yyyy-MM-dd').format(startOfMonth);
      String endDateString = DateFormat('yyyy-MM-dd').format(endOfMonth);
      
      print('Searching for $weekdayName classes from $startDateString to $endDateString');
      
      // Query Firebase for classes in the selected month
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('jadwalYoga')
          .where('date', isGreaterThanOrEqualTo: startDateString)
          .where('date', isLessThanOrEqualTo: endDateString)
          .get();
      
      // Filter dates that match the selected weekday
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String dateString = data['date'];
        
        try {
          DateTime classDate = DateTime.parse(dateString);
          String classWeekday = DateFormat('EEEE').format(classDate);
          
          if (classWeekday == weekdayName && !availableDates.contains(classDate)) {
            availableDates.add(classDate);
          }
        } catch (e) {
          print('Error parsing date: $dateString');
        }
      }
      
      // Sort dates
      availableDates.sort();
      
      print('Found ${availableDates.length} available $weekdayName dates');
      return availableDates;
      
    } catch (e) {
      print('Error fetching available dates: $e');
      return [];
    }
  }

  Future<void> _searchClasses(String query) async {
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
      // Get current date and next 30 days for search
      DateTime now = DateTime.now();
      DateTime futureDate = now.add(const Duration(days: 30));
      
      String startDate = DateFormat('yyyy-MM-dd').format(now);
      String endDate = DateFormat('yyyy-MM-dd').format(futureDate);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('jadwalYoga')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      List<Map<String, dynamic>> allClasses = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Check if user already booked this class
        List<dynamic> bookedBy = data['bookedBy'] ?? [];
        bool alreadyBookedByUser = widget.userId != null && bookedBy.contains(widget.userId);
        
        allClasses.add({
          'id': doc.id,
          'className': data['className'] ?? '',
          'instructor': data['instructor'] ?? '',
          'time': data['time'] ?? '',
          'date': data['date'] ?? '',
          'spotsLeft': data['spotleft'] ?? 0,
          'harga': data['harga'] ?? 0,
          'bookedBy': bookedBy,
          'alreadyBooked': alreadyBookedByUser,
        });
      }

      // Filter classes based on search query
      List<Map<String, dynamic>> filteredClasses = allClasses.where((classData) {
        final className = classData['className'].toString().toLowerCase();
        final instructor = classData['instructor'].toString().toLowerCase();
        final searchQuery = query.toLowerCase().trim();
        
        return className.contains(searchQuery) || instructor.contains(searchQuery);
      }).toList();

      // Sort by date
      filteredClasses.sort((a, b) {
        try {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _searchResults = filteredClasses;
        _isLoadingSearch = false;
      });

    } catch (e) {
      print('Error searching classes: $e');
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
    }
  }

  Future<void> _bookClassFromSearch(Map<String, dynamic> yogaClass) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book a class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (yogaClass['alreadyBooked'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already booked this class'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (yogaClass['spotsLeft'] <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No spots available for this class'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      DateTime classDate = DateTime.parse(yogaClass['date']);
      
      // Create formatted class data for BookingDetailPage
      Map<String, dynamic> formattedClass = {
        'id': yogaClass['id'],
        'name': '${yogaClass['className']} with ${yogaClass['instructor']}',
        'className': yogaClass['className'],
        'instructor': yogaClass['instructor'],
        'time': yogaClass['time'],
        'spotsLeft': yogaClass['spotsLeft'],
        'spots': '${yogaClass['spotsLeft']}/10 spots left',
        'harga': yogaClass['harga'],
        'bookedBy': yogaClass['bookedBy'],
        'date': yogaClass['date'],
        'alreadyBooked': yogaClass['alreadyBooked'],
      };

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BookingDetailPage(
            yogaClass: formattedClass,
            userData: widget.userData,
            userId: widget.userId,
            selectedDate: classDate,
          ),
        ),
      );

      if (result == true) {
        // Refresh search results
        _searchClasses(_searchQuery);
      }
    } catch (e) {
      print('Error booking class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navigation methods for bottom nav bar
  void _navigateToHome() {
    Navigator.pop(context);
  }

  void _navigateToMiniClass() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MiniClassPage(
          userData: widget.userData,
          userId: widget.userId,
        ),
      ),
    );
  }

  void _navigateToAccount() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AccountPage(
          userData: widget.userData,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the username from userData
    final String username = widget.userData != null 
        ? widget.userData!['username'] ?? 'User' 
        : 'User';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan struktur yang sama seperti Mini Class Page
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                  child: Text(
                    'Hello, $username!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C5530),
                    ),
                  ),
                ),

                // Search Bar
                Container(
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
                  child: TextFormField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      if (value.isNotEmpty) {
                        _searchClasses(value);
                      } else {
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search yoga classes...',
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
                          'No classes found for "$_searchQuery"',
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
                        Text(
                          'Search Results',
                          style: const TextStyle(
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
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final classData = _searchResults[index];
                          bool isAlreadyBooked = classData['alreadyBooked'] ?? false;
                          bool hasSpots = classData['spotsLeft'] > 0;
                          
                          DateTime classDate;
                          try {
                            classDate = DateTime.parse(classData['date']);
                          } catch (e) {
                            classDate = DateTime.now();
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: isAlreadyBooked 
                                  ? Border.all(color: Colors.green, width: 2)
                                  : Border.all(color: Colors.grey.shade300),
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
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${classData['className']} with ${classData['instructor']}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isAlreadyBooked 
                                              ? Colors.green.shade700 
                                              : const Color(0xFF2C5530),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormat('E, MMM d').format(classDate)} • ${classData['time']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${classData['spotsLeft']}/10 spots left',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hasSpots ? Colors.grey.shade700 : Colors.red,
                                        ),
                                      ),
                                      if (isAlreadyBooked)
                                        const Text(
                                          'Already Booked',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: isAlreadyBooked 
                                      ? null 
                                      : (hasSpots ? () => _bookClassFromSearch(classData) : null),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isAlreadyBooked
                                        ? Colors.green
                                        : (hasSpots ? const Color(0xFFA3BE8C) : Colors.grey),
                                    foregroundColor: isAlreadyBooked
                                        ? Colors.white
                                        : const Color(0xFF2C5530),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  child: Text(
                                    isAlreadyBooked 
                                        ? 'Booked' 
                                        : (hasSpots ? 'Book' : 'Full'),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
                
                const SizedBox(height: 30),
                
                // Yoga Class Everyday section
                const Text(
                  'Yoga Class Everyday',
                  style: TextStyle(
                    color: Color(0xFF2C5530),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Month selector with date picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFF2C5530)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month - 1,
                            _selectedDate.day,
                          );
                          _selectedMonth = _selectedDate.month;
                          _selectedYear = _selectedDate.year;
                          _dateSpecificallySelected = false;
                        });
                      },
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showDatePicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2C5530), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _dateSpecificallySelected 
                                      ? DateFormat('dd MMM yyyy').format(_selectedDate)
                                      : DateFormat('MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C5530),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2C5530)),
                              ],
                            ),
                          ),
                        ),
                        if (_dateSpecificallySelected)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF2C5530), size: 20),
                            onPressed: _clearDateSelection,
                            tooltip: 'Clear date selection',
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Color(0xFF2C5530)),
                      onPressed: () {
                        setState(() {
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            _selectedDate.month + 1,
                            _selectedDate.day,
                          );
                          _selectedMonth = _selectedDate.month;
                          _selectedYear = _selectedDate.year;
                          _dateSpecificallySelected = false;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Day of week grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2C5530),
                      ),
                    ),
                    if (_dateSpecificallySelected)
                      Text(
                        'Selected: ${_weekdays[_selectedDate.weekday % 7]}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C5530),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Weekday grid - show only selected day or all days
                _dateSpecificallySelected
                    ? _buildSingleDayButton(_weekdays[_selectedDate.weekday % 7])
                    : GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 3.0,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _weekdays.map((day) {
                          return _buildDayButton(day);
                        }).toList(),
                      ),
                
                // Adding extra space at the bottom for better scrolling
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
  
  // Day button widget
  Widget _buildDayButton(String day) {
    return GestureDetector(
      onTap: () async {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2C5530),
              ),
            );
          },
        );
        
        // Get available dates for this weekday from Firebase
        List<DateTime> availableDates = await _getAvailableDatesForWeekday(day);
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        if (availableDates.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YogaClassesPage(
                availableDates: availableDates,
                dayName: day,
                userData: widget.userData,
                userId: widget.userId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No yoga classes available for $day in ${DateFormat('MMMM yyyy').format(_selectedDate)}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
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
  
  // Single day button for when a specific date is selected
  Widget _buildSingleDayButton(String day) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YogaClassesPage(
              availableDates: [_selectedDate],
              dayName: day,
              userData: widget.userData,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        decoration: BoxDecoration(
          color: const Color(0xFF2C5530),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            day,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  // Bottom navigation bar
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
              _buildNavBarItem(
                'Home', 
                Icons.home, 
                false, 
                onTap: _navigateToHome,
              ),
              _buildNavBarItem(
                'Mini Class', 
                Icons.self_improvement, 
                false, 
                onTap: _navigateToMiniClass,
              ),
              _buildNavBarItem(
                'Yoga Class', 
                Icons.accessibility_new, 
                true, // Current page is active
                onTap: () {}, // Already on this page
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
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
            size: 22,
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
