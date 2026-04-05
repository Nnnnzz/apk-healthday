import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. นำเข้า Supabase
import '../constants/app_colors.dart';
import '../screens/main_screen.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final supabase = Supabase.instance.client; // สร้าง Instance Supabase
  bool _isLoading = true; // โหลดข้อมูลตอนเปิดหน้า

  // ====================================================================
  // STATE VARIABLES (ตัวแปรเก็บค่าเป้าหมาย)
  // ====================================================================
  int _stepsGoal = 8000;
  int _waterGoal = 8;
  int _sleepGoal = 8;

  @override
  void initState() {
    super.initState();
    _loadExistingGoals(); // ดึงข้อมูลตอนเปิดหน้า
  }

  // ฟังก์ชันดึงเป้าหมายเดิมจาก Database
  Future<void> _loadExistingGoals() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('user_goals')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            _stepsGoal = data['target_steps'] ?? 8000;
            _waterGoal = data['target_water'] ?? 8;
            _sleepGoal = data['target_sleep'] ?? 8;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ====================================================================
  // LOGIC FUNCTIONS (ฟังก์ชันจัดการการบวก/ลบ)
  // ====================================================================
  void _updateSteps(int delta) {
    setState(() {
      // เพิ่ม/ลด ทีละ 500 ก้าว และไม่ให้ต่ำกว่า 0
      _stepsGoal = (_stepsGoal + (delta * 500)).clamp(0, 50000);
    });
  }

  void _updateWater(int delta) {
    setState(() {
      // เพิ่ม/ลด ทีละ 1 แก้ว และไม่ให้ต่ำกว่า 0
      _waterGoal = (_waterGoal + delta).clamp(0, 50);
    });
  }

  void _updateSleep(int delta) {
    setState(() {
      // เพิ่ม/ลด ทีละ 1 ชั่วโมง และไม่ให้ต่ำกว่า 0
      _sleepGoal = (_sleepGoal + delta).clamp(0, 24);
    });
  }

  // ฟังก์ชันเซฟข้อมูลลง Supabase แล้วกลับไปรีเฟรชหน้า Home
 // ฟังก์ชันเซฟข้อมูลลง Supabase แล้วกลับไปรีเฟรชหน้า Home
  Future<void> _saveGoals() async {
    // setState(() => _isLoading = true); // ถ้ามีตัวแปร _isLoading ให้เปิดคอมเมนต์นี้
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // ✅ 1. ใช้ upsert และต้องใส่ onConflict: 'user_id' เพื่อบังคับให้มัน "เขียนทับ" เป้าหมายเดิมของ user คนนี้
      await supabase.from('user_goals').upsert({
        'user_id': user.id,
        'target_steps': _stepsGoal,
        'target_water': _waterGoal,
        'target_sleep': _sleepGoal,
      }, onConflict: 'user_id'); // ⚠️ ตรงนี้สำคัญมาก ถ้าไม่ใส่ ข้อมูลอาจจะไม่ยอมอัปเดต

      if (!mounted) return;

      // แสดงแจ้งเตือนว่า Save สำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goals updated successfully! 🎯', style: TextStyle(fontFamily: 'Poppins-Medium')),
          backgroundColor: Color(0xFF2D7D9A),
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ 2. กดย้อนกลับไปหน้า MainScreen (เพื่อล้าง Stack และบังคับหน้า Home ดึงข้อมูลใหม่เอี่ยม)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );

    } catch (e) {
      debugPrint("Error saving goals: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving goals: $e'), backgroundColor: Colors.red),
      );
      // setState(() => _isLoading = false); // ถ้ามีตัวแปร _isLoading ให้เปิดคอมเมนต์นี้
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // 1. วงกลมแสงฟุ้งพื้นหลัง (Background Orbs)
          _buildBackgroundOrbs(),

          // 2. เนื้อหาหลัก
          SafeArea(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: AppColors.primaryOrangeGradient.colors.first))
              : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 50),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildQuote(),
                  const SizedBox(height: 25),
                  
                  // การ์ด Activity (Steps)
                  _buildGoalCard(
                    title: "Activity",
                    iconPath: 'assets/icons/activity2_icon.png',
                    fallbackIcon: Icons.directions_walk_rounded,
                    iconGradient: AppColors.stepsGradient,
                    value: _stepsGoal,
                    unit: "steps",
                    recommendedText: "(Recommended: 8,000 - 10,000 steps)",
                    onDecrease: () => _updateSteps(-1),
                    onIncrease: () => _updateSteps(1),
                  ),
                  const SizedBox(height: 20),

                  // การ์ด Water
                  _buildGoalCard(
                    title: "Water",
                    iconPath: 'assets/icons/water2_icon.png',
                    fallbackIcon: Icons.water_drop_rounded,
                    iconGradient: AppColors.waterGradient,
                    value: _waterGoal,
                    unit: "glasses",
                    recommendedText: "(Recommended: 8-10 glasses or 2 liters)",
                    onDecrease: () => _updateWater(-1),
                    onIncrease: () => _updateWater(1),
                  ),
                  const SizedBox(height: 20),

                  // การ์ด Sleep
                  _buildGoalCard(
                    title: "Sleep",
                    iconPath: 'assets/icons/sleep2_icon.png',
                    fallbackIcon: Icons.bedtime_rounded,
                    iconGradient: AppColors.sleepGradient,
                    value: _sleepGoal,
                    unit: "hours",
                    recommendedText: "(Recommended: 7-9 hours)",
                    onDecrease: () => _updateSleep(-1),
                    onIncrease: () => _updateSleep(1),
                  ),
                  const SizedBox(height: 35),

                  // ปุ่ม Save
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // MAIN COMPONENTS
  // ====================================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ปุ่ม Back
          GestureDetector(
            onTap: () => Navigator.pop(context), // หน้า Setting ให้กดย้อนกลับปกติ
            child: Container(
              padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10, right: 10),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyText),
                  SizedBox(width: 5),
                  Text("Back", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium', fontSize: 16)),
                ],
              ),
            ),
          ),
          const Text(
            "Goals",
            style: TextStyle(
              color: AppColors.greyText,
              fontSize: 18,
              fontFamily: 'Poppins-Medium',
            ),
          ),
          const SizedBox(width: 60), // สำหรับบาลานซ์ให้ Title ตรงกลาง
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "\"Good goals are the\nfoundation of good health.\"",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.darkText, // สีน้ำเงินเข้ม
          fontSize: 18,
          fontFamily: 'Poppins-SemiBold', 
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String iconPath,
    required IconData fallbackIcon,
    required LinearGradient iconGradient,
    required int value,
    required String unit,
    required String recommendedText,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // แถบหัวข้อ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryOrangeGradient, 
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // ไอคอนวงกลม
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: iconGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  ),
                  child: Image.asset(
                    iconPath,
                    width: 22,
                    height: 22,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 16,
                    fontFamily: 'Poppins-SemiBold',
                  ),
                ),
              ],
            ),
          ),
          
          // ส่วนเนื้อหาตัวเลขบวกลบ
          Padding(
            padding: const EdgeInsets.only(top: 25, bottom: 15, left: 15, right: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // กล่อง Stepper ควบคุมตัวเลข
                    Container(
                      height: 40,
                      width: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ปุ่มลบ
                          InkWell(
                            onTap: onDecrease,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              child: Icon(Icons.remove, size: 20, color: Colors.grey),
                            ),
                          ),
                          // ตัวเลขตรงกลาง
                          Text(
                            "$value",
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Poppins-SemiBold',
                              color: AppColors.darkText,
                            ),
                          ),
                          // ปุ่มบวก
                          InkWell(
                            onTap: onIncrease,
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              child: Icon(Icons.add, size: 20, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    // หน่วย (steps, glasses, hours)
                    SizedBox(
                      width: 60,
                      child: Text(
                        unit,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontFamily: 'Poppins-Medium',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // คำแนะนำ
                Text(
                  recommendedText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins-Regular',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GestureDetector(
        onTap: _saveGoals, // เรียกใช้ฟังก์ชันเซฟที่เขียนอัปเดตแล้ว
        child: Container(
          height: 55,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryOrangeGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrangeGradient.colors.last.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Poppins-SemiBold',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // HELPER WIDGETS
  // ====================================================================

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryOrangeGradient.scale(0.7),
            ),
          ),
        ),
        Positioned(top: 100, right: -80, child: _orb(250, AppColors.primaryBlueGradient)),
        Positioned(top: 400, left: -100, child: _orb(250, AppColors.primaryBlueGradient)),
        Positioned(bottom: -100, right: -50, child: _orb(400, AppColors.primaryOrangeGradient)),
      ],
    );
  }

  Widget _orb(double size, LinearGradient gradient) {
    return Opacity(
      opacity: 0.3,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}