import 'dart:async'; // 1. นำเข้า Async สำหรับใช้ Timer
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 2. นำเข้า SharedPreferences
import 'package:supabase_flutter/supabase_flutter.dart'; // 3. นำเข้า Supabase
import '../constants/app_colors.dart';
import 'home_page.dart';
import 'stats_page.dart';
import 'calendar_page.dart';
import 'setting_page.dart';
import 'add_record_page.dart';
import '../service/health_advice_service.dart'; // 4. นำเข้า HealthAdviceService สำหรับฟีเจอร์ Health Tips
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Timer? _waterTimer; // ตัวแปรเก็บเวลาสำหรับแจ้งเตือน

  // มี 4 หน้าตรงๆ ตาม Index 0, 1, 2, 3
  final List<Widget> _pages = [
    const HomePage(),     // index 0
    const StatsPage(),    // index 1
    const CalendarPage(), // index 2
    const SettingPage(),  // index 3
  ];

  @override
@override
void initState() {
  super.initState();
  
  // รอให้แอปโหลด UI เสร็จสักครู่แล้วค่อยเช็ค (ป้องกัน Pop-up เด้งแทรกตอนแอปกำลังโหลด)
  Future.delayed(const Duration(seconds: 3), () {
    if (mounted) {
      HealthAdviceService.checkAndShowAdvice(context);
    }
  });
}

Future<void> _triggerHealthTip() async {
  final prefs = await SharedPreferences.getInstance();
  // เช็คสวิตช์เปิด/ปิดจากหน้า Setting
  bool isAdviceOn = prefs.getBool('healthAdvice') ?? true;

  if (isAdviceOn && mounted) {
    await HealthAdviceService.checkAndShowAdvice(context);
  }
}

  @override
  void dispose() {
    _waterTimer?.cancel(); // 5. ยกเลิกจับเวลาตอนปิดแอป ป้องกัน Error
    super.dispose();
  }

  // ==================================================================
  // SMART WATER REMINDER LOGIC (เวอร์ชั่นป้องกันการเตือนรัว 🛡️)
  // ==================================================================
  void _startSmartWaterReminder() {
    Future.delayed(const Duration(seconds: 2), () {
      _processSmartReminder(); 

      // เช็คทุก 1 ชั่วโมงตามปกติ
      _waterTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
        await _processSmartReminder();
      });
    });
  }

  Future<void> _processSmartReminder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 1. เช็คสวิตช์ใน Setting
    bool isWaterReminderOn = prefs.getBool('waterReminder') ?? true;
    if (!isWaterReminderOn) return;

    // 2. เช็คเวลาปัจจุบัน (8:00 - 23:59)
    int currentHour = DateTime.now().hour;
    if (currentHour < 8 || currentHour >= 24) return;

    // 💡 3. ระบบป้องกันการเตือนรัว (เช็คเวลาแจ้งเตือนล่าสุด)
    // ดึงเวลาล่าสุดที่เคยแจ้งเตือนเก็บไว้ในเครื่อง
    String? lastNotifiedStr = prefs.getString('last_water_notification_time');
    if (lastNotifiedStr != null) {
      DateTime lastNotified = DateTime.parse(lastNotifiedStr);
      // ถ้ายังไม่ผ่านไป 1 ชั่วโมง (หรือเวลาที่คุณตั้งไว้ใน Timer) ให้หยุดทำงาน
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

      // --- ผ่านเงื่อนไขทั้งหมด เตรียมแจ้งเตือน ---

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

      // 4. บันทึกลงตาราง notifications 
      await supabase.from('notifications').insert({
        'user_id': user.id,
        'message': msg,
      });

      // 💡 5. บันทึกเวลาที่แจ้งเตือนสำเร็จลงในเครื่อง
      await prefs.setString('last_water_notification_time', DateTime.now().toIso8601String());

    } catch (e) {
      debugPrint('Error Smart Reminder: $e');
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
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
            _buildAddButton(), 
            _buildCustomNavItem('assets/icons/calendar_icon.png', 'calendar', 2),
            _buildCustomNavItem('assets/icons/setting_icon.png', 'settings', 3),
          ],
        ),
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