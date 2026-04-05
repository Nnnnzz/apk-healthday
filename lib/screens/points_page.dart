import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // ==========================================
  // STATE & VARIABLES
  // ==========================================
  bool _isLoading = true;
  int _totalPoints = 0;
  List<Map<String, dynamic>> _dayEvents = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPointsData(_selectedDate);
  }

  // ==========================================
  // LOGIC
  // ==========================================
  Future<void> _fetchPointsData(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final String formattedDate = date.toIso8601String().split('T')[0];

      final responses = await Future.wait([
        supabase.from('users').select('points').eq('user_id', user.id).limit(1).maybeSingle(),
        supabase.from('daily_records').select().eq('user_id', user.id).eq('record_date', formattedDate).limit(1).maybeSingle(),
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
          _dayEvents = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching points data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _fetchPointsData(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primaryBlueGradient.colors.first),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchPointsData(_selectedDate);
    }
  }

  // พากลับไป MainScreen (Home)
  void _backToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true, // ให้เนื้อหาไหลลงไปหลัง Navbar มุมโค้งได้
      body: SafeArea(
        bottom: false, // ปล่อยพื้นที่ด้านล่างให้ Navbar จัดการ
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
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF2D7D9A))),
                )
              else ...[
                _buildPointsCard(),
                const SizedBox(height: 20),
                _buildDailyRecordsContainer(),
                const SizedBox(height: 120), // กัน Navbar บังเนื้อหาล่างสุด
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // UI COMPONENTS
  // ==========================================

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.lightText,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/icons/home_icon.png', 'home'),
          _buildNavItem('assets/icons/stat_icon.png', 'stats'),
          _buildAddButton(),
          _buildNavItem('assets/icons/calendar_icon.png', 'calendar'),
          _buildNavItem('assets/icons/setting_icon.png', 'settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label) {
    return GestureDetector(
      onTap: _backToMain,
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
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryOrangeGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrangeGradient.colors.first.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 35),
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
          const Expanded(
            child: Center(child: Text("Points", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText))),
          ),
          const SizedBox(width: 60), 
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RewardsShopPage(userPoints: _totalPoints)));
        _fetchPointsData(_selectedDate);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(gradient: AppColors.primaryBlueGradient),
                child: const Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.lightText, size: 28),
                    SizedBox(width: 10),
                    Text('Total Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.lightText, fontFamily: 'Poppins-Medium')),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: const BoxDecoration(gradient: AppColors.primaryOrangeGradient),
                child: Center(
                  child: Text('$_totalPoints Pts', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.lightText, fontFamily: 'Poppins-Medium')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyRecordsContainer() {
    final statEvents = _dayEvents.where((e) => e['type'] != 'note').toList();
    final noteEvent = _dayEvents.where((e) => e['type'] == 'note').firstOrNull;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
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
                      style: const TextStyle(fontSize: 18, fontFamily: 'Poppins-Medium', color: Color(0xFF2D7D9A)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primaryBlueGradient.colors.first.withOpacity(0.6)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildNavButton(Icons.arrow_back_ios_rounded, () => _changeDate(-1)),
                    const SizedBox(width: 15),
                    _buildNavButton(Icons.arrow_forward_ios_rounded, () => _changeDate(1)),
                  ],
                ),
              ],
            ),
            const Divider(height: 25, color: Colors.black12),
            if (statEvents.isEmpty)
              _buildEmptyState()
            else
              ...statEvents.map((item) => _buildStatRow(item)),

            if (noteEvent != null) ...[
              const SizedBox(height: 8),
              _buildNoteCard(noteEvent['value']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.backgroundColor, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: AppColors.greyText),
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> item) {
    final theme = _getStatTheme(item['type']);
    final points = item['points'] as int?;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Image.asset(
            theme.iconPath, width: 26, height: 26, fit: BoxFit.contain,
            errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: theme.gradient.colors.first, size: 26),
          ),
          const SizedBox(width: 15),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => theme.gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(item['label'], style: const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text("${item['value']} ${item['unit']}".trim(), style: const TextStyle(fontSize: 16, color: Colors.black87, fontFamily: 'Poppins-Medium')),
          ),
          if (points != null)
             ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => theme.gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text('+$points Pts', style: const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16, fontWeight: FontWeight.bold)),
              ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Text(note, style: const TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'Poppins-Medium')),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_note_outlined, color: Colors.grey, size: 50),
            SizedBox(height: 10),
            Text("No records for this day", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium')),
          ],
        ),
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

  String _getMonthName(int month) => ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][month - 1];
}

class _StatTheme {
  final String iconPath;
  final LinearGradient gradient;
  _StatTheme(this.iconPath, this.gradient);
}