import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'account.dart'; // Import account page

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
  final Map<String, dynamic>? userData; // Add userData parameter
  final String? userId; // Add userId parameter
  
  const YogaClassesPage({
    super.key,
    required this.availableDates,
    required this.dayName,
    this.userData, // Add userData parameter
    this.userId, // Add userId parameter
  });

  @override
  State<YogaClassesPage> createState() => _YogaClassesPageState();
}

class _YogaClassesPageState extends State<YogaClassesPage> {
  late DateTime _selectedDate;
  int _currentDateIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.availableDates.isNotEmpty ? widget.availableDates[0] : DateTime.now();
  }

  void _nextDate() {
    if (_currentDateIndex < widget.availableDates.length - 1) {
      setState(() {
        _currentDateIndex++;
        _selectedDate = widget.availableDates[_currentDateIndex];
      });
    }
  }

  void _prevDate() {
    if (_currentDateIndex > 0) {
      setState(() {
        _currentDateIndex--;
        _selectedDate = widget.availableDates[_currentDateIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Data dummy untuk kelas yoga
    final List<Map<String, dynamic>> yogaClasses = [
      {
        'name': 'Mind hatha yoga with Ana',
        'time': '8-9.30 am',
        'spots': '0/10 spots left',
        'image': 'assets/yoga1.jpg',
      },
      {
        'name': 'Afternoon bliss yoga with Stella',
        'time': '3-4.30 pm',
        'spots': '0/10 spots left',
        'image': 'assets/yoga2.jpg',
      },
      {
        'name': 'Yin yoga with Ken',
        'time': '7-8.30 pm',
        'spots': '0/10 spots left',
        'image': 'assets/yoga3.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C5530)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yoga Classes',
          style: TextStyle(
            color: Color(0xFF2C5530),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date information and navigation
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            child: ListView.builder(
              itemCount: yogaClasses.length,
              itemBuilder: (context, index) {
                final yogaClass = yogaClasses[index];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Yoga image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          yogaClass['image'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          // Using placeholder for demo
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
                      ),
                      
                      const SizedBox(width: 16.0),
                      
                      // Yoga class details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yogaClass['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C5530),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              yogaClass['spots'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              yogaClass['time'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Book button
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA3BE8C),
                          foregroundColor: const Color(0xFF2C5530),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
              _buildNavBarItem('Home', Icons.home, false),
              _buildNavBarItem('Mini Class', Icons.self_improvement, false),
              _buildNavBarItem('Yoga Class', Icons.accessibility_new, true),
              _buildNavBarItem('Account', Icons.person, false),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavBarItem(String label, IconData icon, bool isActive) {
    Function()? onTap;
    
    if (label == 'Home') {
      onTap = () {
        Navigator.pushReplacementNamed(context, '/dashboard');
      };
    } else if (label == 'Account') {
      onTap = () {
        // Navigate to account with user data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountPage(
              userData: widget.userData,
              userId: widget.userId,
            ),
          ),
        );
      };
    }
    
    return GestureDetector(
      onTap: onTap,
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

class _BookingClassPageState extends State<BookingClassPage> {
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

  // Get all dates for a specific weekday in the selected month
  List<DateTime> _getDatesForWeekday(int weekdayIndex) {
    List<DateTime> dates = [];
    
    // Get the first day of the month
    DateTime firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    
    // Get the last day of the month
    DateTime lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    
    // Find all dates with the selected weekday in this month
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      DateTime currentDate = firstDayOfMonth.add(Duration(days: i));
      if (currentDate.weekday % 7 == weekdayIndex % 7) {
        dates.add(currentDate);
      }
    }
    
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    // Get the username from userData
    final String username = widget.userData != null 
        ? widget.userData!['username'] ?? 'User' 
        : 'User';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C5530)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Yoga Class',
          style: TextStyle(
            color: Color(0xFF2C5530),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: Text(
                  'Hello, $username!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Search bar
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
              
              const SizedBox(height: 24),
              
              // Yoga Class Everyday section
              const Text(
                'Yoga Class Everyday',
                style: TextStyle(
                  color: Color(0xFF2C5530),
                  fontSize: 18,
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
                        // When using arrows, we're not selecting a specific date
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
                        // When using arrows, we're not selecting a specific date
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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
  
  // Day button widget
  Widget _buildDayButton(String day) {
    return GestureDetector(
      onTap: () {
        // Calculate all dates in the current month with this weekday
        final int weekdayIndex = _weekdays.indexOf(day);
        List<DateTime> datesWithWeekday = _getDatesForWeekday(weekdayIndex);
        
        // Navigate to the yoga classes page with all occurrences of this weekday
        // and pass the user data
        if (datesWithWeekday.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YogaClassesPage(
                availableDates: datesWithWeekday,
                dayName: day,
                userData: widget.userData, // Pass userData
                userId: widget.userId, // Pass userId
              ),
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
              userData: widget.userData, // Pass userData
              userId: widget.userId, // Pass userId
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem('Home', Icons.home, false, () {
              Navigator.pop(context);
            }),
            _buildNavBarItem('Mini Class', Icons.self_improvement, false, null),
            _buildNavBarItem('Yoga Class', Icons.accessibility_new, true, null),
            _buildNavBarItem('Account', Icons.person, false, () {
              // Navigate to account page with user data
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
  
  Widget _buildNavBarItem(String label, IconData icon, bool isActive, Function()? onTap) {
    return GestureDetector(
      onTap: onTap,
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