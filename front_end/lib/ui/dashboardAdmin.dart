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
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = false;
  String _selectedDay = '';
  
  // Untuk navigasi tanggal
  DateTime _displayedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDay = _getDayName(DateTime.now().weekday);
    _fetchBookings();
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

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String formattedDate = DateFormat('d MMM yyyy').format(_selectedDate);
      
      final QuerySnapshot bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('date', isEqualTo: formattedDate)
          .get();

      List<Map<String, dynamic>> fetchedBookings = [];
      
      for (var doc in bookingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        fetchedBookings.add({
          'id': doc.id,
          'title': data['title'] ?? 'Untitled Class',
          'instructor': data['instructor'] ?? 'Unknown',
          'time': data['time'] ?? '8-9.30 am',
          'date': data['date'] ?? formattedDate,
          'capacity': data['capacity'] ?? '10/10',
          ...data,
        });
      }
      
      // Demo data jika tidak ada booking
      if (fetchedBookings.isEmpty) {
        fetchedBookings = [
          {
            'id': '1',
            'title': 'Mind hatta yoga with Ana',
            'instructor': 'Ana',
            'time': '8-9.30 am',
            'date': formattedDate,
            'capacity': '10/10',
          },
          {
            'id': '2',
            'title': 'Afternoon bliss yoga with Stella',
            'instructor': 'Stella',
            'time': '8-9.30 am',
            'date': formattedDate,
            'capacity': '10/10',
          },
          {
            'id': '3',
            'title': 'Yin yoga with Ken',
            'instructor': 'Ken',
            'time': '8-9.30 am',
            'date': formattedDate,
            'capacity': '10/10',
          },
        ];
      }
      
      setState(() {
        _bookings = fetchedBookings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
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
        _fetchBookings();
      });
    }
  }

  void _selectDay(String day) {
    setState(() {
      _selectedDay = day;
      
      // Find next date with this day of week
      final nowWeekday = _selectedDate.weekday;
      int targetWeekday;
      
      switch (day) {
        case 'Monday': targetWeekday = 1; break;
        case 'Tuesday': targetWeekday = 2; break;
        case 'Wednesday': targetWeekday = 3; break;
        case 'Thursday': targetWeekday = 4; break;
        case 'Friday': targetWeekday = 5; break;
        case 'Saturday': targetWeekday = 6; break;
        case 'Sunday': targetWeekday = 7; break;
        default: targetWeekday = nowWeekday;
      }
      
      int daysToAdd = (targetWeekday - nowWeekday) % 7;
      if (daysToAdd == 0 && _selectedDay != _getDayName(_selectedDate.weekday)) {
        daysToAdd = 7;
      }
      
      _selectedDate = _selectedDate.add(Duration(days: daysToAdd));
      _fetchBookings();
    });
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
                      const Text(
                        'Pre-booked yoga class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF364822),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildDateSelector(),
                      const SizedBox(height: 15),
                      _buildDaySelector(),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF364822)))
                          : _buildBookingsList(),
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

Widget _buildHeader() {
  return Container(
    width: double.infinity, // Make the container take the full width
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Add padding for spacing
    color: const Color(0xFF364822), // Green background
    child: Align(
      alignment: Alignment.centerLeft, // Align text to the right
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the right
        children: [
          const Text(
            'AmalaYoga',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hello, admin!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _previousMonth,
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
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right, color: Color(0xFF364822)),
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDayButton('Sunday'),
        _buildDayButton('Monday'),
        _buildDayButton('Tuesday'),
        _buildDayButton('Wednesday'),
        _buildDayButton('Thursday'),
        _buildDayButton('Friday'),
        _buildDayButton('Saturday'),
      ],
    );
  }

  Widget _buildDayButton(String day) {
    final bool isSelected = _selectedDay == day;
    
    return GestureDetector(
      onTap: () => _selectDay(day),
      child: Container(
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFA3BE8C).withOpacity(isSelected ? 1.0 : 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          day,
          style: TextStyle(
            color: Color(0xFF364822),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    if (_bookings.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No yoga classes booked for this date',
            style: TextStyle(
              color: Color(0xFF364822),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _bookings.map((booking) {
        final String formattedDate = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
        return _buildBookingCard(
          title: booking['title'],
          dateTime: '$formattedDate, ${booking['time']}',
          capacity: booking['capacity'],
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard({
    required String title,
    required String dateTime,
    required String capacity,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFA3BE8C).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wed, ${DateFormat('dd MMM yyyy').format(_selectedDate)}, 8-9.30 am',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF364822),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF364822).withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                capacity,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF364822),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}