import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DashboardAdminPage extends StatefulWidget {
  final Map<String, dynamic> adminData;
  final String adminId;

  const DashboardAdminPage({
    super.key,
    required this.adminData,
    required this.adminId,
  });

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _yogaClasses = [];
  bool _isLoading = false;
  String _selectedDay = '';
  bool _showingDayClasses = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _getDayName(DateTime.now().weekday);
    _fetchYogaClasses();
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  // Logout function
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFF364822),
              ),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFF364822),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from admin panel?',
            style: TextStyle(
              color: Color(0xFF364822),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() {
    // Clear any stored admin data if needed
    // Navigate back to login page
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Replace with your login route
      (Route<dynamic> route) => false,
    );
    
    // Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully logged out'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Fetch yoga classes berdasarkan tanggal spesifik
  Future<void> _fetchYogaClasses() async {
    setState(() {
      _isLoading = true;
      _showingDayClasses = false;
    });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      print('Fetching yoga classes for date: $formattedDate');
      
      final QuerySnapshot yogaSnapshot = await _firestore
          .collection('jadwalYoga')
          .where('date', isEqualTo: formattedDate)
          .get();

      await _processYogaClasses(yogaSnapshot);
      
    } catch (e) {
      print('Error fetching yoga classes: $e');
      setState(() {
        _isLoading = false;
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

  // Fetch yoga classes berdasarkan hari dalam bulan yang dipilih
  Future<void> _fetchYogaClassesByDay(String day) async {
    setState(() {
      _isLoading = true;
      _showingDayClasses = true;
      _selectedDay = day;
    });

    try {
      // Get start and end of the selected month
      DateTime startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      DateTime endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      
      String startDate = DateFormat('yyyy-MM-dd').format(startOfMonth);
      String endDate = DateFormat('yyyy-MM-dd').format(endOfMonth);
      
      print('Fetching $day classes from $startDate to $endDate');
      
      final QuerySnapshot yogaSnapshot = await _firestore
          .collection('jadwalYoga')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .where('day', isEqualTo: day)
          .get();

      await _processYogaClasses(yogaSnapshot);
      
    } catch (e) {
      print('Error fetching yoga classes by day: $e');
      setState(() {
        _isLoading = false;
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

  // Process yoga classes data
  Future<void> _processYogaClasses(QuerySnapshot yogaSnapshot) async {
    List<Map<String, dynamic>> fetchedClasses = [];
    
    for (var doc in yogaSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      List<dynamic> bookedByIds = data['bookedBy'] ?? [];
      List<Map<String, dynamic>> bookedUsers = [];
      
      for (String userId in bookedByIds) {
        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            bookedUsers.add({
              'userId': userId,
              'username': userData['username'] ?? 'Unknown User',
              'email': userData['email'] ?? 'No Email',
            });
          }
        } catch (e) {
          print('Error fetching user data for $userId: $e');
          bookedUsers.add({
            'userId': userId,
            'username': 'Unknown User',
            'email': 'No Email',
          });
        }
      }
      
      fetchedClasses.add({
        'id': doc.id,
        'className': data['className'] ?? 'Unknown Class',
        'instructor': data['instructor'] ?? 'Unknown Instructor',
        'time': data['time'] ?? 'Unknown Time',
        'date': data['date'] ?? '',
        'day': data['day'] ?? '',
        'spotleft': data['spotleft'] ?? 0,
        'totalSpots': 10,
        'harga': data['harga'] ?? 0,
        'bookedBy': bookedByIds,
        'bookedUsers': bookedUsers,
        'bookedCount': bookedByIds.length,
      });
    }
    
    // Sort by date and time
    fetchedClasses.sort((a, b) {
      try {
        int dateComparison = a['date'].toString().compareTo(b['date'].toString());
        if (dateComparison != 0) return dateComparison;
        return a['time'].toString().compareTo(b['time'].toString());
      } catch (e) {
        return 0;
      }
    });
    
    setState(() {
      _yogaClasses = fetchedClasses;
      _isLoading = false;
    });
    
    print('Found ${fetchedClasses.length} yoga classes');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF364822),
              onPrimary: Colors.white,
              surface: Color(0xFFFCF9F3),
              onSurface: Color(0xFF364822),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedDay = _getDayName(picked.weekday);
      });
      _fetchYogaClasses();
    }
  }

  // Show form to add new yoga class
  void _showAddYogaClassForm() {
    final TextEditingController classNameController = TextEditingController();
    final TextEditingController instructorController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController hargaController = TextEditingController();
    final TextEditingController spotLeftController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedDay = _getDayName(selectedDate.weekday);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New Yoga Class',
                style: TextStyle(
                  color: Color(0xFF364822),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(
                        labelText: 'Instructor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        labelText: 'Time (e.g., 8-9.30 am)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hargaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (Rp)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: spotLeftController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Available Spots',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date Picker
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedDate = picked;
                                  selectedDay = _getDayName(picked.weekday);
                                });
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Day Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Day',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedDay,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _saveNewClass(
                    classNameController.text,
                    instructorController.text,
                    timeController.text,
                    hargaController.text,
                    spotLeftController.text,
                    selectedDate,
                    selectedDay,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364822),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show form to add new mini class
  void _showAddMiniClassForm() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    String selectedLevel = 'beginner'; // Default level

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add New Mini Class',
                style: TextStyle(
                  color: Color(0xFF364822),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: 'Video Link',
                        border: OutlineInputBorder(),
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Level:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF364822),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Level Selection
                    Row(
                      children: [
                        Expanded(
                          child: _buildLevelOption(
                            'Beginner',
                            selectedLevel == 'beginner',
                            () => setDialogState(() => selectedLevel = 'beginner'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLevelOption(
                            'Intermediate',
                            selectedLevel == 'intermediate',
                            () => setDialogState(() => selectedLevel = 'intermediate'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLevelOption(
                            'Advanced',
                            selectedLevel == 'advanced',
                            () => setDialogState(() => selectedLevel = 'advanced'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _saveMiniClass(
                    nameController.text,
                    linkController.text,
                    selectedLevel,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364822),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show form to add new instructor
  void _showAddInstructorForm() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Add New Instructor',
            style: TextStyle(
              color: Color(0xFF364822),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Instructor Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Enter instructor description...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => _saveInstructor(
                nameController.text,
                descriptionController.text,
                imageUrlController.text,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF364822),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk opsi level
  Widget _buildLevelOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA3BE8C) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF364822) : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF364822) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Save new yoga class to Firebase
  Future<void> _saveNewClass(
    String className,
    String instructor,
    String time,
    String harga,
    String spotLeft,
    DateTime date,
    String day,
  ) async {
    if (className.isEmpty || instructor.isEmpty || time.isEmpty || 
        harga.isEmpty || spotLeft.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      int hargaInt = int.parse(harga);
      int spotLeftInt = int.parse(spotLeft);
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      await _firestore.collection('jadwalYoga').add({
        'className': className,
        'instructor': instructor,
        'time': time,
        'harga': hargaInt,
        'spotleft': spotLeftInt,
        'date': formattedDate,
        'day': day,
        'bookedBy': [], // Empty array as requested
      });

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yoga class added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the list
      if (_showingDayClasses) {
        _fetchYogaClassesByDay(_selectedDay);
      } else {
        _fetchYogaClasses();
      }

    } catch (e) {
      print('Error saving class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save new mini class to Firebase
  Future<void> _saveMiniClass(
    String name,
    String link,
    String level,
  ) async {
    if (name.isEmpty || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate link format (basic validation)
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid URL starting with http:// or https://'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Determine which collection to use based on level
      String collectionName;
      switch (level) {
        case 'beginner':
          collectionName = 'VidioBeginner';
          break;
        case 'intermediate':
          collectionName = 'VideoIntermediate';
          break;
        case 'advanced':
          collectionName = 'VideoAdvanced';
          break;
        default:
          collectionName = 'VidioBeginner';
      }

      // Add to the appropriate collection
      await _firestore.collection(collectionName).add({
        'name': name,
        'link': link,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mini class added successfully to $collectionName!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error saving mini class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving mini class: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Save new instructor to Firebase
  Future<void> _saveInstructor(
    String name,
    String description,
    String imageUrl,
  ) async {
    if (name.isEmpty || description.isEmpty || imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate image URL format (basic validation)
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid image URL starting with http:// or https://'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Add to instructors collection
      await _firestore.collection('instructors').add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instructor added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error saving instructor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving instructor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBookingDetails(Map<String, dynamic> yogaClass) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '${yogaClass['className']} Details',
            style: const TextStyle(
              color: Color(0xFF364822),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Instructor', yogaClass['instructor']),
                _buildDetailRow('Time', yogaClass['time']),
                _buildDetailRow('Date', yogaClass['date']),
                _buildDetailRow('Day', yogaClass['day']),
                _buildDetailRow('Spots Left', '${yogaClass['spotleft']}/${yogaClass['totalSpots']}'),
                _buildDetailRow('Price', 'Rp ${yogaClass['harga']}'),
                const SizedBox(height: 16),
                Text(
                  'Booked Users (${yogaClass['bookedCount']}):',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF364822),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (yogaClass['bookedUsers'].isEmpty)
                  const Text(
                    'No users have booked this class yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...yogaClass['bookedUsers'].map<Widget>((user) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA3BE8C).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF364822),
                            ),
                          ),
                          Text(
                            'Email: ${user['email']}',
                            style: const TextStyle(
                              color: Color(0xFF364822),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF364822)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF364822),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF364822)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Add Buttons Section - RESPONSIVE LAYOUT
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yoga Class Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF364822),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Responsive Add Buttons
                          _buildResponsiveAddButtons(),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (!_showingDayClasses) _buildDateSelector(),
                      if (_showingDayClasses) _buildDayViewHeader(),
                      const SizedBox(height: 15),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF364822)))
                          : _buildYogaClassesList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive Add Buttons Widget
  Widget _buildResponsiveAddButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if screen is small (mobile)
        if (constraints.maxWidth < 600) {
          // Mobile layout - Stack buttons vertically
          return Column(
            children: [
              // First row - 2 buttons
              Row(
                children: [
                  Expanded(
                    child: _buildAddButton(
                      'Add Instructor',
                      Icons.person_add,
                      _showAddInstructorForm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAddButton(
                      'Add Mini Class',
                      Icons.video_library,
                      _showAddMiniClassForm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Second row - 2 buttons (Add Yoga Class + Logout)
              Row(
                children: [
                  Expanded(
                    child: _buildAddButton(
                      'Add Yoga Class',
                      Icons.add,
                      _showAddYogaClassForm,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLogoutButton(),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Tablet/Desktop layout - All buttons in one row
          return Row(
            children: [
              Expanded(
                child: _buildAddButton(
                  'Add Instructor',
                  Icons.person_add,
                  _showAddInstructorForm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAddButton(
                  'Add Mini Class',
                  Icons.video_library,
                  _showAddMiniClassForm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAddButton(
                  'Add Yoga Class',
                  Icons.add,
                  _showAddYogaClassForm,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLogoutButton(),
              ),
            ],
          );
        }
      },
    );
  }

  // Individual Add Button Widget
  Widget _buildAddButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
        size: 16,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF364822),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        minimumSize: const Size(0, 44), // Minimum height for touch targets
      ),
    );
  }

  // Logout Button Widget
  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: _showLogoutDialog,
      icon: const Icon(
        Icons.logout,
        color: Colors.white,
        size: 16,
      ),
      label: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        minimumSize: const Size(0, 44), // Minimum height for touch targets
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: const Color(0xFF364822),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Title and greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AmalaYoga Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, ${widget.adminData['username'] ?? 'admin'}!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Right side - Logout button for header (optional)
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 24,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              _selectedDay = _getDayName(_selectedDate.weekday);
            });
            _fetchYogaClasses();
          },
          icon: const Icon(Icons.chevron_left, color: Color(0xFF364822)),
        ),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Row(
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF364822),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFF364822)),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
              _selectedDay = _getDayName(_selectedDate.weekday);
            });
            _fetchYogaClasses();
          },
          icon: const Icon(Icons.chevron_right, color: Color(0xFF364822)),
        ),
      ],
    );
  }

  Widget _buildDayViewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All $_selectedDay classes',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF364822),
              ),
            ),
            Text(
              'in ${DateFormat('MMMM yyyy').format(_selectedDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showingDayClasses = false;
              _selectedDay = _getDayName(_selectedDate.weekday);
            });
            _fetchYogaClasses();
          },
          icon: const Icon(Icons.calendar_today, size: 16),
          label: const Text('Back to Date View'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF364822),
          ),
        ),
      ],
    );
  }

  Widget _buildYogaClassesList() {
    if (_yogaClasses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No yoga classes scheduled',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showingDayClasses 
                    ? 'for $_selectedDay in ${DateFormat('MMMM yyyy').format(_selectedDate)}'
                    : 'for ${DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _yogaClasses.map((yogaClass) {
        return _buildYogaClassCard(yogaClass);
      }).toList(),
    );
  }

  Widget _buildYogaClassCard(Map<String, dynamic> yogaClass) {
    final int bookedCount = yogaClass['bookedCount'];
    final int totalSpots = yogaClass['totalSpots'];
    final int spotsLeft = yogaClass['spotleft'];
    
    return GestureDetector(
      onTap: () => _showBookingDetails(yogaClass),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFA3BE8C).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF364822).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${yogaClass['className']} with ${yogaClass['instructor']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF364822),
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bookedCount > 0 ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$bookedCount booked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_showingDayClasses)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF364822).withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    yogaClass['date'],
                    style: TextStyle(
                      color: const Color(0xFF364822).withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: const Color(0xFF364822).withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  yogaClass['time'],
                  style: TextStyle(
                    color: const Color(0xFF364822).withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.people,
                  size: 16,
                  color: const Color(0xFF364822).withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '$spotsLeft/$totalSpots spots left',
                  style: TextStyle(
                    color: spotsLeft > 0 ? const Color(0xFF364822).withOpacity(0.8) : Colors.red,
                    fontSize: 14,
                    fontWeight: spotsLeft == 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp ${yogaClass['harga']}',
                  style: const TextStyle(
                    color: Color(0xFF364822),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Tap for details',
                  style: TextStyle(
                    color: const Color(0xFF364822).withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
