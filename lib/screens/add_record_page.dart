import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _waterController = TextEditingController(
    text: "0",
  );
  final TextEditingController _sleepController = TextEditingController(
    text: "0",
  );
  final TextEditingController _detailController = TextEditingController();

  String _selectedMood = 'none';
  final List<String> _moods = [
    'none',
    'Happy 😊',
    'Calm 😌',
    'Tired 😫',
    'Sad 😥',
  ];

  late DateTime _today;
  late String _displayDate;
  late String _dbFormattedDate;

  bool _waterRewarded = false;
  bool _sleepRewarded = false;
  bool _moodRewarded = false;
  bool _stepRewarded = false;

  int _oldWater = 0;
  int _oldSleep = 0;
  int _oldSteps = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    _displayDate =
        "${_today.day.toString().padLeft(2, '0')} ${months[_today.month - 1]} ${_today.year}";
    _dbFormattedDate =
        "${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}";
    _loadExistingRecord();
  }

  Future<void> _loadExistingRecord() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('daily_records')
          .select()
          .eq('user_id', user.id)
          .eq('record_date', _dbFormattedDate)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _waterController.text = data['water_glasses']?.toString() ?? "0";
          _sleepController.text = data['sleep_hours']?.toString() ?? "0";
          _selectedMood = data['mood'] ?? 'none';
          _detailController.text = data['detail_note'] ?? "";
          _oldWater = data['water_glasses'] ?? 0;
          _oldSleep = data['sleep_hours'] ?? 0;
          _oldSteps = data['steps'] ?? 0;
          _waterRewarded = data['water_rewarded'] ?? false;
          _sleepRewarded = data['sleep_rewarded'] ?? false;
          _moodRewarded = data['mood_rewarded'] ?? false;
          _stepRewarded = data['step_rewarded'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error loading record: $e");
    }
  }

  @override
  void dispose() {
    _waterController.dispose();
    _sleepController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  int _getValue(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;

  Future<void> _saveRecord() async {
    if (_isLoading) return;
    int newWater = _getValue(_waterController);
    int newSleep = _getValue(_sleepController);

    if (newWater > 12) return _showError("ห้ามบันทึกน้ำเกิน 12 แก้วต่อวัน");
    if (newSleep > 12)
      return _showError("ห้ามบันทึกเวลานอนเกิน 12 ชั่วโมงต่อวัน");

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      int earnedPoints = 0;
      final responses = await Future.wait([
        supabase
            .from('user_goals')
            .select()
            .eq('user_id', user.id)
            .maybeSingle(),
        supabase
            .from('daily_records')
            .select('steps')
            .eq('user_id', user.id)
            .eq('record_date', _dbFormattedDate)
            .maybeSingle(),
      ]);

      final goalData = responses[0];
      final recordData = responses[1];

      int targetWater = goalData?['target_water'] ?? 8;
      int targetSleep = goalData?['target_sleep'] ?? 8;
      int targetSteps = goalData?['target_steps'] ?? 8000;
      int currentSteps = recordData?['steps'] ?? 0;

      earnedPoints += (newWater - _oldWater) * 5;
      earnedPoints += (newSleep - _oldSleep) * 10;
      earnedPoints += ((currentSteps ~/ 1000) - (_oldSteps ~/ 1000)) * 10;

      if (newWater >= targetWater && !_waterRewarded) {
        earnedPoints += 50;
        _waterRewarded = true;
      } else if (newWater < targetWater && _waterRewarded) {
        earnedPoints -= 50;
        _waterRewarded = false;
      }

      if (newSleep >= targetSleep && !_sleepRewarded) {
        earnedPoints += 50;
        _sleepRewarded = true;
      } else if (newSleep < targetSleep && _sleepRewarded) {
        earnedPoints -= 50;
        _sleepRewarded = false;
      }

      if (_selectedMood != 'none' && !_moodRewarded) {
        earnedPoints += 20;
        _moodRewarded = true;
      } else if (_selectedMood == 'none' && _moodRewarded) {
        earnedPoints -= 20;
        _moodRewarded = false;
      }

      if (currentSteps >= targetSteps && !_stepRewarded) {
        earnedPoints += 100;
        _stepRewarded = true;
      } else if (currentSteps < targetSteps && _stepRewarded) {
        earnedPoints -= 100;
        _stepRewarded = false;
      }

      if (earnedPoints != 0) {
        final userData = await supabase
            .from('users')
            .select('points')
            .eq('user_id', user.id)
            .single();
        int finalPoints = (userData['points'] ?? 0) + earnedPoints;
        await supabase
            .from('users')
            .update({'points': finalPoints < 0 ? 0 : finalPoints})
            .eq('user_id', user.id);
      }

      await supabase.from('daily_records').upsert({
        'user_id': user.id,
        'record_date': _dbFormattedDate,
        'water_glasses': newWater,
        'sleep_hours': newSleep,
        'mood': _selectedMood,
        'detail_note': _detailController.text,
        'water_rewarded': _waterRewarded,
        'sleep_rewarded': _sleepRewarded,
        'mood_rewarded': _moodRewarded,
        'step_rewarded': _stepRewarded,
      }, onConflict: 'user_id, record_date');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      resizeToAvoidBottomInset: true, // ✅ ป้องกันคีย์บอร์ดทับ UI
      body: Stack(
        children: [
          _buildBackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    // ✅ คลุมส่วนที่เหลือให้เลื่อนได้
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildBigHeartIcon(),
                        _buildMainRecordCard(),
                        const SizedBox(height: 30),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : _buildActionButtons(context),
                        const SizedBox(height: 30), // ✅ เผื่อช่องว่างด้านล่าง
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.greyText,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Text(
            "Add Record",
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Poppins-Medium',
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRecordCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryOrangeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.white.withOpacity(0.1),
            child: Column(
              children: [
                _buildDateHeader(),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _buildWaterActivity(),
                      const SizedBox(height: 15),
                      _buildSleepActivity(),
                      const SizedBox(height: 15),
                      _buildMoodActivity(),
                      const SizedBox(height: 20),
                      _buildDetailActivity(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFF2D7D9A),
      child: Center(
        child: Text(
          "Today, $_displayDate",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Poppins-SemiBold',
          ),
        ),
      ),
    );
  }

  Widget _buildWaterActivity() {
    return _buildHybridInputFieldRow(
      iconPath: 'assets/icons/water2_icon.png',
      title: "Water",
      gradient: AppColors.waterGradient,
      controller: _waterController,
      unit: "glasses",
      onDecrease: () => setState(
        () => _waterController.text =
            "${(_getValue(_waterController) - 1).clamp(0, 12)}",
      ),
      onIncrease: () => setState(
        () => _waterController.text =
            "${(_getValue(_waterController) + 1).clamp(0, 12)}",
      ),
    );
  }

  Widget _buildSleepActivity() {
    return _buildHybridInputFieldRow(
      iconPath: 'assets/icons/sleep2_icon.png',
      title: "Sleep",
      gradient: AppColors.sleepGradient,
      controller: _sleepController,
      unit: "hours",
      onDecrease: () => setState(
        () => _sleepController.text =
            "${(_getValue(_sleepController) - 1).clamp(0, 12)}",
      ),
      onIncrease: () => setState(
        () => _sleepController.text =
            "${(_getValue(_sleepController) + 1).clamp(0, 12)}",
      ),
    );
  }

  Widget _buildMoodActivity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              gradient: AppColors.moodGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          _buildGradientText(
            "Mood",
            AppColors.moodGradient,
            const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16),
          ),
          const Spacer(),
          Container(
            height: 36,
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMood,
                isExpanded: true,
                items: _moods
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: FittedBox(child: Text(m)),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedMood = val!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "detail:",
          style: TextStyle(
            fontFamily: 'Poppins-Medium',
            color: AppColors.darkText,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          constraints: const BoxConstraints(
            minHeight: 100,
            maxHeight: 150,
          ), // ✅ ป้องกันกล่องยืดจนล้น
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _detailController,
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "...",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHybridInputFieldRow({
    required String iconPath,
    required String title,
    required LinearGradient gradient,
    required TextEditingController controller,
    required String unit,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.circle, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 8),
          _buildGradientText(
            title,
            gradient,
            const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 14),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDecrease,
            child: const Icon(Icons.remove, size: 18),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 40,
            height: 30,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onIncrease,
            child: const Icon(Icons.add, size: 18),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: FittedBox(
              child: Text(unit, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildGradientButton(
            "Save",
            AppColors.stepsGradient,
            _saveRecord,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildGradientButton(
            "Cancel",
            AppColors.deleteGradient,
            () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(
    String text,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBigHeartIcon() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Icon(Icons.favorite, size: 60, color: Color(0xFF2D7D9A)),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(
          top: -20,
          left: -20,
          child: _orb(130, AppColors.primaryOrangeGradient),
        ),
        Positioned(
          bottom: -20,
          right: -30,
          child: _orb(220, AppColors.primaryOrangeGradient),
        ),
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
      ),
    );
  }

  Widget _buildGradientText(
    String text,
    LinearGradient gradient,
    TextStyle style,
  ) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
