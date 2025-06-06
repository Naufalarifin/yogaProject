import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'dashboard.dart';
import 'miniClassPage.dart';
import 'account.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> yogaClass;
  final Map<String, dynamic>? userData;
  final String? userId;
  final DateTime selectedDate;

  const BookingDetailPage({
    super.key,
    required this.yogaClass,  // Data kelas yoga yang dibooking
    this.userData,           // Data user
    this.userId,             // ID pengguna
    required this.selectedDate, // Tanggal yang dipilih
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  String? selectedBank;
  bool showPaymentDetails = false;
  bool isProcessingPayment = false;
  Timer? paymentTimer;
  int paymentTimeLeft = 1800; // 30 minutes in seconds
  
  // Bank options
  final List<Map<String, String>> banks = [
    {'name': 'BCA', 'account': '7001081618999241'},
    {'name': 'BRI', 'account': '7001081618999242'},
    {'name': 'Mandiri', 'account': '7001081618999243'},
    {'name': 'BSI', 'account': '7001081618999244'},
  ];

  @override
  void dispose() {
    paymentTimer?.cancel();
    super.dispose();
  }

  void startPaymentTimer() {
    paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (paymentTimeLeft > 0) {
        setState(() {
          paymentTimeLeft--;
        });
      } else {
        timer.cancel();
        // Auto cancel payment if time runs out
        _cancelPayment();
      }
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _selectBank(String bankName, String accountNumber) {
    setState(() {
      selectedBank = bankName;
      showPaymentDetails = true;
    });
    startPaymentTimer();
  }

  void _cancelPayment() {
    setState(() {
      showPaymentDetails = false;
      selectedBank = null;
      paymentTimeLeft = 1800;
    });
    paymentTimer?.cancel();
  }

  void _copyAccountNumber(String accountNumber) {
    Clipboard.setData(ClipboardData(text: accountNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account number copied to clipboard'),
        backgroundColor: Color(0xFF2C5530),
      ),
    );
  }

  Future<void> _completeBooking() async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to complete booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isProcessingPayment = true;
    });

    try {
      // Update Firebase document to book the class
      await FirebaseFirestore.instance
          .collection('jadwalYoga')
          .doc(widget.yogaClass['id'])
          .update({
        'bookedBy': FieldValue.arrayUnion([widget.userId]),
        'spotleft': FieldValue.increment(-1),
      });

      // Stop timer
      paymentTimer?.cancel();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // PERBAIKAN: Kembali ke halaman yoga class dengan result
        // Pop hingga kembali ke YogaClassesPage dan trigger refresh
        Navigator.of(context).pop(true); // Return true sebagai result
      }
    } catch (e) {
      setState(() {
        isProcessingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method untuk navigasi ke halaman lain
  void _navigateToPage(String route) {
    // Jangan navigasi jika sudah di halaman yang sama
    if (route == 'yogaclass') return;
    
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
        
      case 'miniclass':
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
        
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String className = widget.yogaClass['className'] ?? 'No Name';
    final String instructor = widget.yogaClass['instructor'] ?? 'Unknown Instructor';
    final int price = widget.yogaClass['harga'] ?? 0;
    final String time = widget.yogaClass['time'] ?? 'No Time';
    final String dateFormatted = DateFormat('E, d MMM yyyy').format(widget.selectedDate); // Format the date

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
          'Booking Detail',
          style: TextStyle(
            color: Color(0xFF2C5530),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false, // Bottom navigation sudah memiliki SafeArea sendiri
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Hello, ${widget.userData?['username'] ?? 'User'}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C5530),
                  ),
                ),

                const SizedBox(height: 8),

                // Search bar (non-functional for now)
                // Your search bar code here...
                
                const SizedBox(height: 24),

                // Yoga Class Everyday title
                const Text(
                  'Yoga Class Everyday',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C5530),
                  ),
                ),

                const SizedBox(height: 16),

                // Class details card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$className with $instructor',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C5530),
                              ),
                            ),
                          ),
                          Text(
                            'IDR ${NumberFormat('#,###').format(price)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C5530),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Payment section
                const Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bank selection
                ...banks.map((bank) => _buildBankOption(bank['name']!, bank['account']!)),
                
                const SizedBox(height: 20),
                
                // Payment details (shown when bank is selected)
                if (showPaymentDetails) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA3BE8C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFA3BE8C),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Before',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              formatTime(paymentTimeLeft), // Show remaining time for payment
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Virtual Account Number',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              banks.firstWhere((bank) => bank['name'] == selectedBank)['account']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C5530),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _copyAccountNumber(
                                banks.firstWhere((bank) => bank['name'] == selectedBank)['account']!
                              ),
                              child: const Text(
                                'Copy',
                                style: TextStyle(
                                  color: Color(0xFF2C5530),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Payment instructions
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Instructions:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C5530),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. Transfer exact amount: IDR ${NumberFormat('#,###').format(widget.yogaClass['harga'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '2. Use the virtual account number above',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '3. Keep your transaction receipt',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                '4. Click "Done" after payment completion',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelPayment,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isProcessingPayment ? null : _completeBooking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C5530),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isProcessingPayment
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Done',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // PERBAIKAN: Tambahkan padding bottom untuk memberikan ruang dengan bottom nav
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
    
  Widget _buildBankOption(String bankName, String accountNumber) {
    bool isSelected = selectedBank == bankName;
    
    return GestureDetector(
      onTap: showPaymentDetails ? null : () => _selectBank(bankName, accountNumber),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8), // Mengurangi margin
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Padding yang lebih efisien
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C5530) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2C5530) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 12,
                        color: Color(0xFF2C5530),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              bankName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF2C5530) : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_up,
                color: Color(0xFF2C5530),
              ),
            ] else ...[
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }
    
  // PERBAIKAN: Bottom navigation bar yang konsisten dengan halaman lainnya
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16), // Padding yang konsisten
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem('Home', Icons.home, false, 'home'),
              _buildNavBarItem('Mini Class', Icons.self_improvement, false, 'miniclass'),
              _buildNavBarItem('Yoga Class', Icons.accessibility_new, true, 'yogaclass'),
              _buildNavBarItem('Account', Icons.person, false, 'account'),
            ],
          ),
        ),
      ),
    );
  }
    
  // PERBAIKAN: NavBar item yang konsisten dengan halaman lainnya
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
