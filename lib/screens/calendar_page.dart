import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../screens/main_screen.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final supabase = Supabase.instance.client;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  bool _isLoading = false;
  Map<String, dynamic>? _userGoals;
  List<Map<String, dynamic>> _currentDayEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchDataForDay(_focusedDay);
  }

  Future<void> _fetchDataForDay(DateTime day) async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      if (_userGoals == null) {
        final goalData = await supabase.from('user_goals').select().eq('user_id', user.id).maybeSingle();
        _userGoals = goalData ?? {'target_steps': 8000, 'target_water': 8, 'target_sleep': 8};
      }

      final String formattedDate = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

      final record = await supabase
          .from('daily_records')
          .select()
          .eq('user_id', user.id)
          .eq('record_date', formattedDate)
          .maybeSingle();

      List<Map<String, dynamic>> newEvents = [];

      if (record != null) {
        int steps = record['steps'] ?? 0;
        int water = record['water_glasses'] ?? 0;
        int sleep = record['sleep_hours'] ?? 0;
        String mood = record['mood'] ?? 'none';
        String note = record['detail_note'] ?? '';

        int targetSteps = _userGoals?['target_steps'] ?? 8000;
        int targetWater = _userGoals?['target_water'] ?? 8;
        int targetSleep = _userGoals?['target_sleep'] ?? 8;

        newEvents.add({
          'type': 'steps', 'label': 'Steps:', 'value': '$steps', 'unit': '', 
          'isGoalMet': steps >= targetSteps && steps > 0
        });
        newEvents.add({
          'type': 'water', 'label': 'Waters:', 'value': '$water', 'unit': '', 
          'isGoalMet': water >= targetWater && water > 0
        });
        newEvents.add({
          'type': 'sleep', 'label': 'Sleeps:', 'value': '$sleep', 'unit': 'hours', 
          'isGoalMet': sleep >= targetSleep && sleep > 0
        });
        
        String displayMood = mood == 'none' ? 'None' : mood[0].toUpperCase() + mood.substring(1);
        newEvents.add({
          'type': 'mood', 'label': 'Moods:', 'value': displayMood, 'unit': '', 
          'isGoalMet': mood != 'none' 
        });

        if (note.isNotEmpty) {
          newEvents.add({'type': 'note', 'value': note});
        }
      }

      if (mounted) {
        setState(() {
          _currentDayEvents = newEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching calendar data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
          SafeArea(
            // ✅ ครอบทั้งหน้าด้วย SingleChildScrollView เพื่อให้เลื่อนได้ทั้งหมด
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildQuote(),
                  const SizedBox(height: 20),
                  _buildCalendarCard(),
                  const SizedBox(height: 20),
                  // ✅ เอา Expanded ออก เพราะไม่จำเป็นต้องบังคับยืดสุดจอแล้ว
                  _buildDailyRecordsContainer(),
                  const SizedBox(height: 40), // เผื่อระยะด้านล่างให้เลื่อนได้สุดไม่บังปุ่ม Navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientText(String text, LinearGradient gradient, TextStyle style) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (route) => false),
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
            child: Center(child: Text("History", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText))),
          ),
          const SizedBox(width: 60), 
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return const Text(
      "“Frame your health with memories”",
      style: TextStyle(fontSize: 16, fontFamily: 'Poppins-Medium', color: Color(0xFF2D7D9A), fontStyle: FontStyle.italic),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _fetchDataForDay(selectedDay);
          }
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontFamily: 'Poppins-Medium'),
        ),
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(fontFamily: 'Poppins-Medium'),
          weekendTextStyle: TextStyle(color: Colors.red, fontFamily: 'Poppins-Medium'),
          todayDecoration: BoxDecoration(color: AppColors.darkText, shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: Color(0xFFFFA726), shape: BoxShape.circle),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_selectedDay?.day} ${_getMonthName(_selectedDay?.month ?? 1)} ${_selectedDay?.year}",
                      style: const TextStyle(fontSize: 18, fontFamily: 'Poppins-Medium', color: Color(0xFF2D7D9A)),
                    ),
                    const Divider(height: 25, color: Colors.black12),
                    // ✅ เอา Expanded ออก และโชว์ข้อมูลได้เลย (มันจะดันกล่องให้ยาวลงไปเอง)
                    _isLoading 
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF2D7D9A))),
                        )
                      : (_currentDayEvents.isEmpty ? _buildEmptyState() : _buildEventList(_currentDayEvents)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> events) {
    // ✅ เปลี่ยนจาก ListView.builder มาเป็น Column เพิ่อให้ไม่เกิดปัญหาเลื่อนจอซ้อนกัน
    return Column(
      children: events.map((item) {
        return item['type'] == 'note' ? _buildNoteCard(item['value']) : _buildStatRow(item);
      }).toList(),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> item) {
    final theme = _getStatTheme(item['type']);
    final bool isMet = item['isGoalMet'] ?? false; 
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Image.asset(
            theme.iconPath, width: 28, height: 28, fit: BoxFit.contain,
            errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: theme.gradient.colors.first, size: 28),
          ),
          const SizedBox(width: 15),
          _buildGradientText(
            item['label'], 
            theme.gradient, 
            const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16)
          ),
          const SizedBox(width: 10),
          Text(
            "${item['value']} ${item['unit']}",
            style: const TextStyle(fontSize: 16, color: Colors.black87, fontFamily: 'Poppins-Medium'),
          ),
          if (isMet) ...[
            const Spacer(),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4001D8C1), 
                    blurRadius: 6,
                    offset: Offset(0, 1),
                  )
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF01D8C1),
                size: 20,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildNoteCard(String note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Text(note, style: const TextStyle(fontSize: 15, color: Colors.black54, fontFamily: 'Poppins-Medium')),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, color: Colors.grey, size: 50),
            SizedBox(height: 10),
            Text("No records for this day", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium')),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: -30, left: -20, child: _orb(100, AppColors.primaryOrangeGradient)),
        Positioned(top: 80, right: -50, child: _orb(200, AppColors.primaryBlueGradient)),
        Positioned(bottom: 150, left: -80, child: _orb(200, AppColors.primaryBlueGradient)),
        Positioned(bottom: 0, right: -30, child: _orb(250, AppColors.primaryOrangeGradient)),
      ],
    );
  }

  Widget _orb(double size, LinearGradient gradient) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
            child: Container(color: Colors.transparent),
          ),
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