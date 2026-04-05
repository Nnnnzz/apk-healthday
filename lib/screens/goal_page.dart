import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../screens/main_screen.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Controllers สำหรับ TextField
  late TextEditingController _stepsController;
  late TextEditingController _waterController;
  late TextEditingController _sleepController;

  int _stepsGoal = 8000;
  int _waterGoal = 8;
  int _sleepGoal = 8;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController(text: "$_stepsGoal");
    _waterController = TextEditingController(text: "$_waterGoal");
    _sleepController = TextEditingController(text: "$_sleepGoal");
    _loadExistingGoals();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _waterController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGoals() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase.from('user_goals').select().eq('user_id', user.id).maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _stepsGoal = data['target_steps'] ?? 8000;
            _waterGoal = data['target_water'] ?? 8;
            _sleepGoal = data['target_sleep'] ?? 8;
            _stepsController.text = "$_stepsGoal";
            _waterController.text = "$_waterGoal";
            _sleepController.text = "$_sleepGoal";
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateValue(String type, int delta) {
    setState(() {
      if (type == 'steps') {
        _stepsGoal = (_stepsGoal + (delta * 500)).clamp(0, 50000);
        _stepsController.text = "$_stepsGoal";
      } else if (type == 'water') {
        _waterGoal = (_waterGoal + delta).clamp(0, 50);
        _waterController.text = "$_waterGoal";
      } else if (type == 'sleep') {
        _sleepGoal = (_sleepGoal + delta).clamp(0, 24);
        _sleepController.text = "$_sleepGoal";
      }
    });
  }

  Future<void> _saveGoals() async {
    int finalSteps = int.tryParse(_stepsController.text) ?? _stepsGoal;
    int finalWater = int.tryParse(_waterController.text) ?? _waterGoal;
    int finalSleep = int.tryParse(_sleepController.text) ?? _sleepGoal;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");
      await supabase.from('user_goals').upsert({
        'user_id': user.id,
        'target_steps': finalSteps,
        'target_water': finalWater,
        'target_sleep': finalSleep,
      }, onConflict: 'user_id');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals updated successfully! 🎯', style: TextStyle(fontFamily: 'Poppins-Medium')), backgroundColor: Color(0xFF2D7D9A)),
      );
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
    } catch (e) {
      debugPrint("Error saving goals: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Stack(
          children: [
            _buildBackgroundOrbs(),
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
                        _buildGoalCard(
                          title: "Activity",
                          iconPath: 'assets/icons/activity2_icon.png',
                          fallbackIcon: Icons.directions_walk_rounded,
                          iconGradient: AppColors.stepsGradient,
                          controller: _stepsController,
                          unit: "steps",
                          recommendedText: "(Recommended: 8,000 - 10,000 steps)",
                          onDecrease: () => _updateValue('steps', -1),
                          onIncrease: () => _updateValue('steps', 1),
                        ),
                        const SizedBox(height: 20),
                        _buildGoalCard(
                          title: "Water",
                          iconPath: 'assets/icons/water2_icon.png',
                          fallbackIcon: Icons.water_drop_rounded,
                          iconGradient: AppColors.waterGradient,
                          controller: _waterController,
                          unit: "glasses",
                          recommendedText: "(Recommended: 8-10 glasses or 2 liters)",
                          onDecrease: () => _updateValue('water', -1),
                          onIncrease: () => _updateValue('water', 1),
                        ),
                        const SizedBox(height: 20),
                        _buildGoalCard(
                          title: "Sleep",
                          iconPath: 'assets/icons/sleep2_icon.png',
                          fallbackIcon: Icons.bedtime_rounded,
                          iconGradient: AppColors.sleepGradient,
                          controller: _sleepController,
                          unit: "hours",
                          recommendedText: "(Recommended: 7-9 hours)",
                          onDecrease: () => _updateValue('sleep', -1),
                          onIncrease: () => _updateValue('sleep', 1),
                        ),
                        const SizedBox(height: 35),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String iconPath,
    required IconData fallbackIcon,
    required LinearGradient iconGradient,
    required TextEditingController controller,
    required String unit,
    required String recommendedText,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // เปลี่ยนเป็นใสเพื่อทำ Glass
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // ✅ Glass Texture ทับทั้งกล่อง
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryOrangeGradient.scale(0.9), // ส้มเดิมที่ใสขึ้นนิดหน่อย
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: iconGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                      ),
                      child: Image.asset(iconPath, width: 22, height: 22, color: Colors.white, errorBuilder: (c, e, s) => Icon(fallbackIcon, color: Colors.white, size: 22)),
                    ),
                    const SizedBox(width: 12),
                    Text(title, style: const TextStyle(color: AppColors.darkText, fontSize: 16, fontFamily: 'Poppins-SemiBold')),
                  ],
                ),
              ),
              Container(
                color: Colors.white.withOpacity(0.4), // ส่วนสีขาวที่ใสขึ้น
                padding: const EdgeInsets.only(top: 25, bottom: 15, left: 15, right: 15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 40,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(onPressed: onDecrease, icon: const Icon(Icons.remove, size: 18, color: Colors.grey)),
                              
                              // ✅ เปลี่ยนจาก Text เป็น TextField เพื่อให้พิมพ์ได้
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(fontSize: 18, fontFamily: 'Poppins-SemiBold', color: AppColors.darkText),
                                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                ),
                              ),

                              IconButton(onPressed: onIncrease, icon: const Icon(Icons.add, size: 18, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        SizedBox(width: 60, child: Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 16, fontFamily: 'Poppins-Medium'))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(recommendedText, style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Poppins-Regular')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header, Quote, SaveButton, BackgroundOrbs คง UI เดิมเป๊ะตามโค้ดต้นฉบับ ---
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          const Text("Goals", style: TextStyle(color: AppColors.greyText, fontSize: 18, fontFamily: 'Poppins-Medium')),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildQuote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text("\"Good goals are the\nfoundation of good health.\"", textAlign: TextAlign.center, style: TextStyle(color: AppColors.darkText, fontSize: 18, fontFamily: 'Poppins-SemiBold', height: 1.4)),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GestureDetector(
        onTap: _saveGoals,
        child: Container(
          height: 55, width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryOrangeGradient, borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: AppColors.primaryOrangeGradient.colors.last.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: const Center(child: Text("Save", style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins-SemiBold'))),
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: -40, left: -60, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryOrangeGradient.scale(0.7)))),
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
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
        child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent))),
      ),
    );
  }
}