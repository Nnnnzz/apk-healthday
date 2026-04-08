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

  final TextEditingController _waterController = TextEditingController(text: "0");
  final TextEditingController _sleepController = TextEditingController(text: "0");
  final TextEditingController _detailController = TextEditingController();

  String _selectedMood = 'none';
  final List<String> _moods = ['none', 'Happy 😊', 'Calm 😌', 'Tired 😫', 'Sad 😥'];

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
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    _displayDate = "${_today.day.toString().padLeft(2, '0')} ${months[_today.month - 1]} ${_today.year}";
    _dbFormattedDate = "${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}";
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

  int _getValue(TextEditingController controller) => int.tryParse(controller.text) ?? 0;

  // ✅ แก้ไขฟังก์ชันบันทึก: เพิ่มการตรวจสอบเงื่อนไขห้ามเกิน 12
  Future<void> _saveRecord() async {
    if (_isLoading) return;

    int newWater = _getValue(_waterController);
    int newSleep = _getValue(_sleepController);

    // 🛑 [Anti-Cheat Logic]
    if (newWater > 12) {
      _showError("ห้ามบันทึกน้ำเกิน 12 แก้วต่อวัน");
      return;
    }
    if (newSleep > 12) {
      _showError("ห้ามบันทึกเวลานอนเกิน 12 ชั่วโมงต่อวัน");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      int earnedPoints = 0;

      final responses = await Future.wait([
        supabase.from('user_goals').select().eq('user_id', user.id).maybeSingle(),
        supabase.from('daily_records').select('steps').eq('user_id', user.id).eq('record_date', _dbFormattedDate).maybeSingle(),
      ]);

      final goalData = responses[0];
      final recordData = responses[1];

      int targetWater = goalData?['target_water'] ?? 8;
      int targetSleep = goalData?['target_sleep'] ?? 8;
      int targetSteps = goalData?['target_steps'] ?? 8000;
      int currentSteps = recordData?['steps'] ?? 0;

      earnedPoints += (newWater - _oldWater) * 5; 
      earnedPoints += (newSleep - _oldSleep) * 10;

      int oldThousandGroup = _oldSteps ~/ 1000;
      int newThousandGroup = currentSteps ~/ 1000;
      earnedPoints += (newThousandGroup - oldThousandGroup) * 10;

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
        final userData = await supabase.from('users').select('points').eq('user_id', user.id).single();
        int currentTotal = userData['points'] ?? 0;
        int finalPoints = currentTotal + earnedPoints;
        if (finalPoints < 0) finalPoints = 0;

        await supabase.from('users').update({'points': finalPoints}).eq('user_id', user.id);
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
      
      String msg = earnedPoints >= 0 ? 'Saved! +$earnedPoints Pts ⭐' : 'Saved! $earnedPoints Pts 📉';
      if (earnedPoints == 0) msg = 'Saved Successfully! 🎉';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: earnedPoints >= 0 ? const Color(0xFF2D7D9A) : Colors.redAccent));
      
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
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
      body: Stack(
        children: [
          _buildBackgroundOrbs(), 
          SafeArea(child: Column(children: [
            const SizedBox(height: 10), 
            _buildHeader(context), 
            _buildBigHeartIcon(), 
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 25), child: Column(children: [
              _buildMainRecordCard(), 
              const SizedBox(height: 30), 
              _isLoading ? const CircularProgressIndicator() : _buildActionButtons(context), 
              const SizedBox(height: 40)
            ])))
          ]))
        ],
      ),
    );
  }

  // --- UI Components ---
  Widget _buildHeader(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), child: Row(children: [GestureDetector(onTap: () => Navigator.pop(context), child: const Row(children: [Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyText), SizedBox(width: 5), Text("Back", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium', fontSize: 16))])), const Expanded(child: Center(child: Text("Add Record", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText)))), const SizedBox(width: 60)]));
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(children: [Expanded(child: _buildGradientButton("Save", AppColors.stepsGradient, _saveRecord)), const SizedBox(width: 15), Expanded(child: _buildGradientButton("Cancel", AppColors.deleteGradient, () => Navigator.pop(context)))]);
  }

  Widget _buildBigHeartIcon() {
    return Padding(padding: const EdgeInsets.only(bottom: 25, top: 15), child: Image.asset('assets/icons/health_icon.png', width: 65, height: 65, errorBuilder: (c, e, s) => const Icon(Icons.favorite_border, size: 60, color: Color(0xFF2D7D9A))));
  }

  Widget _buildMainRecordCard() {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.primaryOrangeGradient, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(color: Colors.white.withOpacity(0.1)))),
          Column(children: [
            _buildDateHeader(), 
            Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              _buildWaterActivity(), 
              const SizedBox(height: 15), 
              _buildSleepActivity(), 
              const SizedBox(height: 15), 
              _buildMoodActivity(), 
              const SizedBox(height: 20), 
              _buildDetailActivity()
            ]))
          ])
        ]),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: const BoxDecoration(color: Color(0xFF2D7D9A)), child: Center(child: Text("Today, $_displayDate", style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins-SemiBold', letterSpacing: 1.2))));
  }

  // ✅ แก้ไขปุ่มกดใน Row: เช็คไม่ให้เกิน 12 ก่อนเพิ่มค่า
  Widget _buildWaterActivity() {
    return _buildHybridInputFieldRow(
      iconPath: 'assets/icons/water2_icon.png', 
      title: "Water", 
      gradient: AppColors.waterGradient, 
      controller: _waterController, 
      unit: "glasses", 
      onDecrease: () => setState(() => _waterController.text = "${_getValue(_waterController) > 0 ? _getValue(_waterController) - 1 : 0}"), 
      onIncrease: () {
        if (_getValue(_waterController) < 12) {
          setState(() => _waterController.text = "${_getValue(_waterController) + 1}");
        } else {
          _showError("น้ำสูงสุด 12 แก้วต่อวัน");
        }
      }
    );
  }

  Widget _buildSleepActivity() {
    return _buildHybridInputFieldRow(
      iconPath: 'assets/icons/sleep2_icon.png', 
      title: "Sleep", 
      gradient: AppColors.sleepGradient, 
      controller: _sleepController, 
      unit: "hours", 
      onDecrease: () => setState(() => _sleepController.text = "${_getValue(_sleepController) > 0 ? _getValue(_sleepController) - 1 : 0}"), 
      onIncrease: () {
        if (_getValue(_sleepController) < 12) {
          setState(() => _sleepController.text = "${_getValue(_sleepController) + 1}");
        } else {
          _showError("เวลานอนสูงสุด 12 ชั่วโมงต่อวัน");
        }
      }
    );
  }

  Widget _buildMoodActivity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(gradient: AppColors.moodGradient, shape: BoxShape.circle), child: Image.asset('assets/icons/mood2_icon.png', width: 22, height: 22, color: Colors.white, errorBuilder: (c, e, s) => const Icon(Icons.sentiment_satisfied_alt, color: Colors.white, size: 22))),
        const SizedBox(width: 12),
        _buildGradientText("Mood", AppColors.moodGradient, const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16)),
        const Spacer(),
        Container(height: 36, width: 130, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(10)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedMood, icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54), style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.black87, fontSize: 14), items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (val) => setState(() => _selectedMood = val!))))
      ]),
    );
  }

  Widget _buildDetailActivity() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("detail:", style: TextStyle(fontFamily: 'Poppins-Medium', color: AppColors.darkText, fontSize: 14)), const SizedBox(height: 5), Container(height: 100, padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(12)), child: TextField(controller: _detailController, maxLines: null, style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.black87, fontSize: 14), decoration: const InputDecoration(border: InputBorder.none, hintText: "...")))]);
  }

  Widget _buildHybridInputFieldRow({required String iconPath, required String title, required LinearGradient gradient, required TextEditingController controller, required String unit, required VoidCallback onDecrease, required VoidCallback onIncrease}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle), child: Image.asset(iconPath, width: 22, height: 22, color: Colors.white)),
        const SizedBox(width: 12),
        _buildGradientText(title, gradient, const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16)),
        const Spacer(),
        Row(children: [GestureDetector(onTap: onDecrease, child: const Icon(Icons.remove, size: 18, color: Colors.black54)), const SizedBox(width: 8), SizedBox(width: 60, height: 36, child: TextField(controller: controller, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.black87, fontSize: 15), decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF7F7F7), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 5)))), const SizedBox(width: 8), GestureDetector(onTap: onIncrease, child: const Icon(Icons.add, size: 18, color: Colors.black54))]),
        const SizedBox(width: 10),
        SizedBox(width: 60, child: Text(unit, style: const TextStyle(color: Colors.black87, fontSize: 13, fontFamily: 'Poppins-Medium')))
      ]),
    );
  }

  Widget _buildGradientButton(String text, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(height: 52, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: gradient.colors.last.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]), child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Poppins-SemiBold')))));
  }

  Widget _buildBackgroundOrbs() {
    return Stack(children: [Positioned(top: -20, left: -20, child: _orb(130, AppColors.primaryOrangeGradient)), Positioned(top: 80, right: -50, child: _orb(180, AppColors.primaryBlueGradient)), Positioned(bottom: 120, left: -50, child: _orb(180, AppColors.primaryBlueGradient)), Positioned(bottom: -20, right: -30, child: _orb(220, AppColors.primaryOrangeGradient))]);
  }

  Widget _orb(double size, LinearGradient gradient) {
    return Opacity(opacity: 0.5, child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient), child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), child: Container(color: Colors.transparent)))));
  }

  Widget _buildGradientText(String text, LinearGradient gradient, TextStyle style) {
    return ShaderMask(blendMode: BlendMode.srcIn, shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)), child: Text(text, style: style));
  }
}