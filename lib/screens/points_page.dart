import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../screens/main_screen.dart';
import 'rewards_page.dart';
import 'add_record_page.dart'; // อย่าลืมนำเข้าหน้า AddRecord

class PointPage extends StatefulWidget {
  const PointPage({super.key});

  @override
  State<PointPage> createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  int _totalPoints = 0;
  List<Map<String, dynamic>> _dayEvents = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPointsData(_selectedDate);
  }

  // ✅ เพิ่มฟังก์ชันนำทางไปยัง Index ที่ต้องการใน MainScreen
  void _navigateToIndex(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  Future<void> _fetchPointsData(DateTime date) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final String formattedDate = date.toIso8601String().split('T')[0];

      final responses = await Future.wait([
        supabase
            .from('users')
            .select('points')
            .eq('user_id', user.id)
            .maybeSingle(),
        supabase
            .from('daily_records')
            .select()
            .eq('user_id', user.id)
            .eq('record_date', formattedDate)
            .maybeSingle(),
      ]);

      int fetchedTotalPoints = responses[0]?['points'] ?? 0;
      final recordData = responses[1];
      List<Map<String, dynamic>> newEvents = [];

      if (recordData != null) {
        int steps = recordData['steps'] ?? 0;
        int water = recordData['water_glasses'] ?? 0;
        int sleep = recordData['sleep_hours'] ?? 0;
        String mood = recordData['mood'] ?? 'none';

        // ดึงสถานะโบนัส
        bool stepRewarded = recordData['step_rewarded'] ?? false;
        bool waterRewarded = recordData['water_rewarded'] ?? false;
        bool sleepRewarded = recordData['sleep_rewarded'] ?? false;
        bool moodRewarded = recordData['mood_rewarded'] ?? false;

        if (steps > 0) {
          int stepPoints = (steps ~/ 1000) * 10;
          if (stepRewarded) stepPoints += 100;
          int stepPoints = (steps ~/ 1000) * 10; // แต้มรายหน่วย
          if (stepRewarded) stepPoints += 100; // บวกโบนัสเป้าหมาย
          newEvents.add({
            'type': 'steps',
            'label': 'Steps:',
            'value': '$steps',
            'unit': 'steps',
            'points': stepPoints > 0 ? stepPoints : null,
          });
        }
        if (water > 0) {
          int waterPoints = water * 5;
          if (waterRewarded) waterPoints += 50;
          newEvents.add({
            'type': 'water',
            'label': 'Waters:',
            'value': '$water',
            'unit': 'glasses',
            'points': waterPoints > 0 ? waterPoints : null,
          });
        }
        if (sleep > 0) {
          int sleepPoints = sleep * 10;
          if (sleepRewarded) sleepPoints += 50;
          newEvents.add({
            'type': 'sleep',
            'label': 'Sleeps:',
            'value': '$sleep',
            'unit': 'hours',
            'points': sleepPoints > 0 ? sleepPoints : null,
          });
        }
        if (mood != 'none') {
          String displayMood = mood[0].toUpperCase() + mood.substring(1);
          newEvents.add({
            'type': 'mood',
            'label': 'Moods:',
            'value': displayMood,
            'unit': '',
            'points': moodRewarded ? 20 : null,
          });
        }
      }

      if (mounted) {
        setState(() {
          _totalPoints = fetchedTotalPoints;
          _dayEvents = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching points data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPointsRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Center(
          child: Text(
            "HealthDay Points Rules",
            style: TextStyle(
              fontFamily: 'Poppins-SemiBold',
              color: Color(0xFF2D7D9A),
              fontSize: 18,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRuleItem('assets/icons/water2_icon.png', AppColors.waterGradient, "Water", "5 Pts / glass\n+50 Pts Goal Bonus"),
            _buildRuleItem('assets/icons/sleep2_icon.png', AppColors.sleepGradient, "Sleep", "10 Pts / hour\n+50 Pts Goal Bonus"),
            _buildRuleItem('assets/icons/activity2_icon.png', AppColors.stepsGradient, "Steps", "10 Pts / 1,000 steps\n+100 Pts Goal Bonus"),
            _buildRuleItem('assets/icons/mood2_icon.png', AppColors.moodGradient, "Mood", "20 Pts for daily check-in"),
            const SizedBox(height: 10),
            const Text("*Goal Bonus is awarded once per day", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Got it!", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String assetPath, LinearGradient gradient, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: Image.asset(assetPath, width: 20, height: 20, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins-Medium')),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _fetchPointsData(_selectedDate),
          color: const Color(0xFF2D7D9A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeader(context),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D7D9A),
                      ),
                    ),
                  )
                else ...[
                  _buildPointsCard(),
                  const SizedBox(height: 20),
                  _buildDailyRecordsContainer(),
                  const SizedBox(height: 140),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(gradient: AppColors.primaryBlueGradient),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars_rounded, color: AppColors.lightText, size: 28),
                      SizedBox(width: 10),
                      Text('Current Balance', style: TextStyle(fontSize: 18, color: AppColors.lightText, fontFamily: 'Poppins-Medium')),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showPointsRules,
                    child: const Icon(Icons.info_outline_rounded, color: AppColors.lightText, size: 22),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RewardsShopPage(userPoints: _totalPoints)),
                );
                _fetchPointsData(_selectedDate);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryOrangeGradient,
                ),
                child: Center(
                  child: Text(
                    '$_totalPoints Pts',
                    style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.lightText, fontFamily: 'Poppins-SemiBold'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRecordsContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins-Medium',
                        color: Color(0xFF2D7D9A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: AppColors.primaryBlueGradient.colors.first
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildNavButton(
                      Icons.arrow_back_ios_rounded,
                      () => _changeDate(-1),
                    ),
                    const SizedBox(width: 15),
                    _buildNavButton(
                      Icons.arrow_forward_ios_rounded,
                      () => _changeDate(1),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 25, color: Colors.black12),
            if (_dayEvents.isEmpty) _buildEmptyState() else ..._dayEvents.map((item) => _buildStatRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> item) {
    final theme = _getStatTheme(item['type']);
    final points = item['points'] as int?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Image.asset(theme.iconPath, width: 24, height: 24, fit: BoxFit.contain, errorBuilder: (c, e, s) => Icon(Icons.check_circle_outline, color: theme.gradient.colors.first, size: 24)),
          const SizedBox(width: 15),
          
          // ส่วนเนื้อหา (หัวข้อ และ จำนวน อยู่บรรทัดเดียวกัน)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // หัวข้อ (เช่น Steps:, Waters:)
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => theme.gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: Text(item['label'], style: const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 15)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("${item['value']} ${item['unit']}".trim(), style: const TextStyle(fontSize: 16, color: Colors.black87, fontFamily: 'Poppins-SemiBold'), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          // คะแนนที่ได้รับ (+Pts)
          if (points != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: theme.gradient.colors.first.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => theme.gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text('+$points Pts', style: const TextStyle(fontFamily: 'Poppins-SemiBold', fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  _StatTheme _getStatTheme(String type) {
    switch (type) {
      case 'steps': return _StatTheme('assets/icons/activity2_icon.png', AppColors.stepsGradient);
      case 'water': return _StatTheme('assets/icons/water2_icon.png', AppColors.waterGradient);
      case 'sleep': return _StatTheme('assets/icons/sleep2_icon.png', AppColors.sleepGradient);
      case 'mood': return _StatTheme('assets/icons/mood2_icon.png', AppColors.moodGradient);
      default: return _StatTheme('assets/icons/activity2_icon.png', AppColors.stepsGradient);
    }
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, color: Colors.grey, size: 40),
            SizedBox(height: 10),
            Text(
              "No activity recorded",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontFamily: 'Poppins-Medium',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.greyText),
                  SizedBox(width: 5),
                  Text("Back", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium')),
                ],
              ),
            ),
          ),
          const Expanded(child: Center(child: Text("Points", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText)))),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: AppColors.greyText),
      ),
    );
  }

  String _getMonthName(int month) => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month - 1];

  void _changeDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _fetchPointsData(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchPointsData(_selectedDate);
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.lightText,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/icons/home_icon.png', 'home', 0),
          _buildNavItem('assets/icons/stat_icon.png', 'stats', 1),
          _buildAddButton(),
          _buildNavItem('assets/icons/calendar_icon.png', 'calendar', 2),
          _buildNavItem('assets/icons/setting_icon.png', 'settings', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, int index) {
    return GestureDetector(
      onTap: () => _navigateToIndex(index), // ✅ เรียกใช้ฟังก์ชันนำทาง
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconPath, width: 28, height: 28, color: AppColors.greyText),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.greyText, fontFamily: 'Poppins')),
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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryOrangeGradient,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 35),
      ),
    );
  }
}

class _StatTheme {
  final String iconPath;
  final LinearGradient gradient;
  _StatTheme(this.iconPath, this.gradient);
}
