import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dashboard.dart';
import 'booking_class.dart';
import 'package:front_end/ui/miniClassPage.dart';
import 'account.dart';

class BookedClassesPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const BookedClassesPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<BookedClassesPage> createState() => _BookedClassesPageState();
}

class _BookedClassesPageState extends State<BookedClassesPage> {
  List<Map<String, dynamic>> bookedClasses = [];
  bool isLoading = true;
  DateTime? selectedDate;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchBookedClasses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch booked classes from Firebase
  Future<void> _fetchBookedClasses() async {
    if (widget.userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('jadwalYoga')
          .where('bookedBy', arrayContains: widget.userId)
          .get();

      List<Map<String, dynamic>> fetchedClasses = [];

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Parse date
        DateTime classDate;
        try {
          if (data['date'] is String) {
            classDate = DateTime.parse(data['date']);
          } else if (data['date'] is Timestamp) {
            classDate = (data['date'] as Timestamp).toDate();
          } else {
            classDate = DateTime.now();
          }
        } catch (e) {
          classDate = DateTime.now();
        }

        fetchedClasses.add({
          'id': doc.id,
          'className': data['className'] ?? 'Unknown Class',
          'instructor': data['instructor'] ?? 'Unknown Instructor',
          'time': data['time'] ?? 'No time specified',
          'date': classDate,
          'dateString': data['date'],
          'location': data['location'] ?? 'Sindangbarang, Bogor Barat, Bogor City, West Java 16117',
          'harga': data['harga'] ?? 0,
          'spotleft': data['spotleft'] ?? 0,
        });
      }

      // Sort by date (newest first)
      fetchedClasses.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        bookedClasses = fetchedClasses;
        isLoading = false;
      });

    } catch (e) {
      print('Error fetching booked classes: $e');
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading booked classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter classes based on search and date
  List<Map<String, dynamic>> get filteredClasses {
    List<Map<String, dynamic>> filtered = bookedClasses;

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((classData) {
        final className = classData['className'].toString().toLowerCase();
        final instructor = classData['instructor'].toString().toLowerCase();
        final query = searchQuery.toLowerCase();
        
        // Split query into words for partial matching
        final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();
        
        // Check if any query word matches className or instructor
        return queryWords.any((word) => 
          className.contains(word) || instructor.contains(word)
        ) || className.contains(query) || instructor.contains(query);
      }).toList();
    }

    // Filter by selected date
    if (selectedDate != null) {
      filtered = filtered.where((classData) {
        final classDate = classData['date'] as DateTime;
        return DateFormat('yyyy-MM-dd').format(classDate) == 
               DateFormat('yyyy-MM-dd').format(selectedDate!);
      }).toList();
    }

    return filtered;
  }

  // Show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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
        selectedDate = picked;
      });
    }
  }

  // Clear date filter
  void _clearDateFilter() {
    setState(() {
      selectedDate = null;
    });
  }

  // Navigate to specific page
  void _navigateToPage(String route) {
    switch (route) {
      case 'home':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              userData: widget.userData,
              userId: widget.userId,
            ),
          ),
        );
        break;
      case 'mini_class':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MiniClassPage(
              userData: widget.userData,
              userId: widget.userId,
            ),
          ),
        );
        break;
      case 'yoga_class':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingClassPage(
              userData: widget.userData,
              userId: widget.userId,
            ),
          ),
        );
        break;
      case 'account':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccountPage(
              userData: widget.userData,
              userId: widget.userId,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.userData != null 
        ? widget.userData!['username'] ?? 'User' 
        : 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        bottom: false, // Bottom navigation sudah memiliki SafeArea sendiri
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with back arrow
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2C5530),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
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

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by class name or instructor...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Found ${filteredClasses.length} class${filteredClasses.length != 1 ? 'es' : ''} matching "$searchQuery"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Date filter section
              Row(
                children: [
                  const Text(
                    'Booked Class',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C5530),
                    ),
                  ),
                  const Spacer(),
                  // Date filter button
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selectedDate != null ? const Color(0xFF2C5530) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2C5530)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: selectedDate != null ? Colors.white : const Color(0xFF2C5530),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            selectedDate != null 
                                ? DateFormat('dd MMM').format(selectedDate!)
                                : 'Filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedDate != null ? Colors.white : const Color(0xFF2C5530),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.clear,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Booked classes list
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2C5530),
                        ),
                      )
                    : filteredClasses.isEmpty
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
                                  searchQuery.isNotEmpty || selectedDate != null
                                      ? 'No classes found with current filters'
                                      : 'No booked classes yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (searchQuery.isNotEmpty || selectedDate != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = '';
                                        selectedDate = null;
                                        _searchController.clear();
                                      });
                                    },
                                    child: const Text(
                                      'Clear filters',
                                      style: TextStyle(color: Color(0xFF2C5530)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchBookedClasses,
                            color: const Color(0xFF2C5530),
                            child: ListView.builder(
                              itemCount: filteredClasses.length,
                              itemBuilder: (context, index) {
                                final classData = filteredClasses[index];
                                return _buildClassCard(classData);
                              },
                            ),
                          ),
              ),
              
              // Tambahkan padding bottom untuk memberikan ruang dengan bottom nav
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Build class card widget
  Widget _buildClassCard(Map<String, dynamic> classData) {
    final DateTime classDate = classData['date'];
    final String formattedDate = DateFormat('E, d MMM yyyy').format(classDate);
    final bool isPastClass = classDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA3BE8C).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isPastClass 
            ? Border.all(color: Colors.grey.shade400, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${classData['className']} with ${classData['instructor']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPastClass ? Colors.grey.shade600 : const Color(0xFF2C5530),
                  ),
                ),
              ),
              if (isPastClass)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 14,
              color: isPastClass ? Colors.grey.shade500 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            classData['time'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isPastClass ? Colors.grey.shade500 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: isPastClass ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  classData['location'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isPastClass ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
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
          height: 60, // Tinggi yang konsisten
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem('Home', Icons.home, false, 'home'),
              _buildNavBarItem('Mini Class', Icons.self_improvement, false, 'mini_class'),
              _buildNavBarItem('Yoga Class', Icons.accessibility_new, false, 'yoga_class'),
              _buildNavBarItem('Account', Icons.person, true, 'account'), // Current page
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
            size: 22, // Ukuran yang konsisten
            color: isActive ? const Color(0xFF2C5530) : Colors.black54,
          ),
          const SizedBox(height: 2), // Spacing yang konsisten
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2C5530) : Colors.black54,
              fontSize: 11, // Ukuran font yang konsisten
            ),
          ),
        ],
      ),
    );
  }
}
