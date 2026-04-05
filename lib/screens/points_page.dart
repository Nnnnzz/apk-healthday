import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. นำเข้า Supabase
import '../constants/app_colors.dart';
import '../screens/main_screen.dart';
import 'rewards_page.dart';

class PointPage extends StatefulWidget {
  const PointPage({super.key});

  @override
  State<PointPage> createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> {
  final supabase = Supabase.instance.client;

  // ====================================================================
  // STATE VARIABLES
  // ====================================================================
  bool _isLoading = true;
  int _totalPoints = 0;
  List<Map<String, dynamic>> _todayEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayPointsData();
  }

  // ฟังก์ชันดึงข้อมูลพอยต์และกิจกรรมของวันนี้
  Future<void> _fetchTodayPointsData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // หาวันที่ปัจจุบัน (YYYY-MM-DD)
      final String todayDate = DateTime.now().toIso8601String().split('T')[0];

      // ดึงข้อมูล 2 อย่างพร้อมกัน: แต้มรวมของ User และ กิจกรรมของวันนี้
      final responses = await Future.wait([
        supabase.from('users').select('points').eq('user_id', user.id).limit(1).maybeSingle(),
        supabase.from('daily_records').select().eq('user_id', user.id).eq('record_date', todayDate).limit(1).maybeSingle(),
      ]);

      int fetchedTotalPoints = responses[0]?['points'] ?? 0;
      final recordData = responses[1];
      List<Map<String, dynamic>> newEvents = [];

      if (recordData != null) {
        int steps = recordData['steps'] ?? 0;
        int water = recordData['water_glasses'] ?? 0;
        int sleep = recordData['sleep_hours'] ?? 0;
        String mood = recordData['mood'] ?? 'none';
        String note = recordData['detail_note'] ?? '';

        // จำลองการให้แต้ม (หรือจะดึงจาก Logic ของแอปคุณก็ได้)
        if (steps > 0) {
          newEvents.add({'type': 'steps', 'label': 'Steps:', 'value': '$steps', 'unit': 'steps', 'points': 20});
        }
        if (water > 0) {
          newEvents.add({'type': 'water', 'label': 'Waters:', 'value': '$water', 'unit': 'glasses', 'points': 5});
        }
        if (sleep > 0) {
          newEvents.add({'type': 'sleep', 'label': 'Sleeps:', 'value': '$sleep', 'unit': 'hours', 'points': 7});
        }
        if (mood != 'none') {
          String displayMood = mood[0].toUpperCase() + mood.substring(1);
          newEvents.add({'type': 'mood', 'label': 'Moods:', 'value': displayMood, 'unit': '', 'points': 3});
        }
        if (note.isNotEmpty) {
          newEvents.add({'type': 'note', 'value': note});
        }
      }

      if (mounted) {
        setState(() {
          _totalPoints = fetchedTotalPoints;
          _todayEvents = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching points data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  _StatTheme _getStatTheme(String type) {
    switch (type) {
      case 'steps': return _StatTheme('assets/icons/activity2_icon.png', const Color(0xFF01D8C1));
      case 'water': return _StatTheme('assets/icons/water2_icon.png',    const Color(0xFF06EFFF));
      case 'sleep': return _StatTheme('assets/icons/sleep2_icon.png',    const Color(0xFFFE83ED));
      case 'mood':  return _StatTheme('assets/icons/mood2_icon.png',     const Color(0xFFFFAC36));
      default:      return _StatTheme('assets/icons/activity2_icon.png', Colors.grey);
    }
  }

  String _getMonthName(int month) => [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ][month - 1];

  // navigate กลับ MainScreen
  void _navigateTo(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // แยกกิจกรรมที่เป็น Note ออกมา
    final statEvents  = _todayEvents.where((e) => e['type'] != 'note').toList();
    final noteEvent   = _todayEvents.where((e) => e['type'] == 'note').firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: AppColors.primaryOrangeGradient.colors.first))
        : Column(
        children: [
          // ===== Header =====
          Container(
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Back + Title row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: Colors.grey),
                          onPressed: () => _navigateTo(0), // กลับ home
                        ),
                        const Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Points',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 60),
                      ],
                    ),
                  ),

                  // ===== Points Card =====
                  GestureDetector(
                    onTap: () async {
                      // กดเข้าหน้ารางวัล รอจนกลับมาแล้วโหลดข้อมูลพอยต์ใหม่ (เผื่อโดนหักพอยต์)
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RewardsShopPage(userPoints: _totalPoints),
                        ),
                      );
                      _fetchTodayPointsData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              // ส่วนบน: Total Points label
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF2D7D9A), Color(0xFF1A4A56)],
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.star_border_rounded,
                                        color: Colors.white, size: 28),
                                    SizedBox(width: 10),
                                    Text(
                                      'Total Points',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ส่วนล่าง: ตัวเลข
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '$_totalPoints Pts',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ===== Today's Stats =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${today.day} ${_getMonthName(today.month)} ${today.year}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2D7D9A),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (statEvents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No records for today',
                            style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                          ),
                        ),
                      )
                    else
                      ...statEvents.map((item) => _buildStatRow(item)),

                    if (noteEvent != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          noteEvent['value'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> item) {
    final theme  = _getStatTheme(item['type']);
    final points = item['points'] as int?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Image.asset(
            theme.iconPath,
            width: 28,
            height: 28,
            color: theme.color,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.broken_image, color: theme.color, size: 28),
          ),
          const SizedBox(width: 14),
          // โชว์ข้อมูล เช่น Steps: 5000 steps
          Expanded(
            child: Text(
              "${item['label']} ${item['value']} ${item['unit']}".trim(),
              style: TextStyle(
                color: theme.color,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (points != null)
            Text(
              '+$points Pts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.color,
                fontFamily: 'Poppins',
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTheme {
  final String iconPath;
  final Color color;
  _StatTheme(this.iconPath, this.color);
}