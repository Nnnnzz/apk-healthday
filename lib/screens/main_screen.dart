import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'calendar_page.dart';
import 'setting_page.dart';
import 'add_record_page.dart';
import '../service/health_advice_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  Timer? _waterTimer;

  final List<Widget> _pages = [
    const HomePage(),
    const StatsPage(),
    const CalendarPage(),
    const SettingPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // 1. เริ่มระบบแจ้งเตือนดื่มน้ำ
    _startSmartWaterReminder();

    // 2. เริ่มระบบคำแนะนำสุขภาพ
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _triggerHealthAdvice();
      }
    });
  }

  Future<void> _triggerHealthAdvice() async {
    final prefs = await SharedPreferences.getInstance();
    bool isAdviceOn = prefs.getBool('health_advice_enabled') ?? true;

    if (isAdviceOn && mounted) {
      await HealthAdviceService.checkAndShowAdvice(context);
    }
  }

  @override
  void dispose() {
    _waterTimer?.cancel();
    super.dispose();
  }

  void _startSmartWaterReminder() {
    Future.delayed(const Duration(seconds: 2), () {
      _processSmartReminder();

      _waterTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
        await _processSmartReminder();
      });
    });
  }

  Future<void> _processSmartReminder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isWaterReminderOn = prefs.getBool('waterReminder') ?? true;
    if (!isWaterReminderOn) return;

    int currentHour = DateTime.now().hour;
    if (currentHour < 8 || currentHour >= 24) return;

    String? lastNotifiedStr = prefs.getString('last_water_notification_time');
    if (lastNotifiedStr != null) {
      DateTime lastNotified = DateTime.parse(lastNotifiedStr);
      if (DateTime.now().difference(lastNotified).inMinutes < 60) {
        return;
      }
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final String todayDate = DateTime.now().toIso8601String().split('T')[0];

      final responses = await Future.wait([
        supabase.from('user_goals').select('target_water').eq('user_id', user.id).maybeSingle(),
        supabase.from('daily_records').select('water_glasses').eq('user_id', user.id).eq('record_date', todayDate).maybeSingle(),
      ]);

      int targetWater = responses[0]?['target_water'] ?? 8;
      int currentWater = responses[1]?['water_glasses'] ?? 0;

      if (currentWater >= targetWater) return;

      String msg = "💧 It's time to drink water! ($currentWater/$targetWater glasses)";

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.white)),
            backgroundColor: const Color(0xFF2D7D9A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.only(bottom: 120, left: 20, right: 20),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      await supabase.from('notifications').insert({'user_id': user.id, 'message': msg});
      await prefs.setString('last_water_notification_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error Smart Reminder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      // ✅ จัดรูปแบบ Bottom Bar ใหม่
      bottomNavigationBar: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 85,
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
                
                // เว้นที่ตรงกลางให้ปุ่มลอย
                const SizedBox(width: 60), 
                
                _buildCustomNavItem('assets/icons/calendar_icon.png', 'calendar', 2),
                _buildCustomNavItem('assets/icons/setting_icon.png', 'settings', 3),
              ],
            ),
          ),
          // ปุ่ม Add ลอยนูนตรงกลาง
          Positioned(
            top: -25,
            child: _buildAddButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem(String iconPath, String label, int index) {
    bool isSelected = _currentIndex == index;
    final Color selectedColor = AppColors.primaryBlueGradient.colors.last;
    final Color unselectedColor = AppColors.greyText;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60, // ล็อกความกว้างไอคอนให้เท่ากัน
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 26,
              height: 26,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRecordPage()),
        );
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryOrangeGradient,
          border: Border.all(color: Colors.white, width: 4), // ขอบนูนสีขาว
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryOrangeGradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 38),
      ),
    );
  }
}