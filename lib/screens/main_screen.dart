import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'calendar_page.dart';
import 'setting_page.dart';
import 'add_record_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 1. ตัด AddRecordPage ออกจากลิสต์หน้าหลัก เพื่อไม่ให้ Scaffold ซ้อนกัน
  final List<Widget> _pages = [
    const HomePage(),     // index 0
    const StatsPage(),    // index 1
    const CalendarPage(), // index 2 (ขยับขึ้นมา)
    const SettingPage(),  // index 3 (ขยับขึ้นมา)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex > 1 ? _currentIndex - 1 : _currentIndex, 
        // Logic: ถ้า index เป็น 3 (calendar) จะให้โชว์ _pages[2]
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.lightText,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCustomNavItem('assets/icons/home_icon.png', 'home', 0),
            _buildCustomNavItem('assets/icons/stat_icon.png', 'stats', 1),
            _buildAddButton(), // ปุ่มตรงกลาง
            _buildCustomNavItem('assets/icons/calendar_icon.png', 'calendar', 2), // แก้ index เป็น 2
            _buildCustomNavItem('assets/icons/setting_icon.png', 'settings', 3), // แก้ index เป็น 3
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(String iconPath, String label, int index) {
    // ปรับเงื่อนไขเช็คการเลือกให้ตรงกับ index ใหม่
    bool isSelected = _currentIndex == index;
    if (index >= 2 && _currentIndex == index + 1) isSelected = true;
    if (_currentIndex == 100) isSelected = false; // กันรวนตอนกด Add

    final Color selectedColor = AppColors.primaryBlueGradient.colors.last;
    final Color unselectedColor = AppColors.greyText;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 28,
            height: 28,
            color: isSelected ? selectedColor : unselectedColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? selectedColor : unselectedColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    // ปุ่ม Add จะไม่เปลี่ยน Index แต่จะใช้วิธีเปิดหน้าใหม่ (Push)
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRecordPage()),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryOrangeGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrangeGradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 35),
      ),
    );
  }
}