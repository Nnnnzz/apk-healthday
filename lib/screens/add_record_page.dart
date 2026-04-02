import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. นำเข้า Supabase
import 'dart:convert';

class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  // สร้าง instance ของ supabase ไว้เรียกใช้
  final supabase = Supabase.instance.client;

  final TextEditingController _waterController = TextEditingController(text: "0");
  final TextEditingController _sleepController = TextEditingController(text: "0");
  final TextEditingController _detailController = TextEditingController();

  int _day = 13;
  String _month = 'Sep';
  int _year = 2025;
  String _selectedMood = 'none';

  final List<int> _days = List.generate(31, (index) => index + 1);
  final List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final List<int> _years = [2024, 2025, 2026, 2027];
  final List<String> _moods = ['none', 'Happy 😊', 'Calm 😌', 'Tired 😫', 'Sad 😥'];

  @override
  void dispose() {
    _waterController.dispose();
    _sleepController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  // ฟังก์ชันแปลงชื่อเดือนเป็นตัวเลข (เช่น Sep -> 09) เพื่อให้ SQL อ่านได้
  String _getMonthNumber(String monthName) {
    int index = _months.indexOf(monthName) + 1;
    return index.toString().padLeft(2, '0');
  }

  int _getValue(TextEditingController controller) {
    if (controller.text.isEmpty) return 0;
    return int.tryParse(controller.text) ?? 0;
  }

  // 2. ฟังก์ชันสำหรับบันทึกข้อมูลลง Supabase
  Future<void> _saveRecord() async {
  try {
    // 1. ตรวจสอบข้อมูลเบื้องต้น (Optional)
    String monthNum = _getMonthNumber(_month);
    String dayNum = _day.toString().padLeft(2, '0');
    String formattedDate = '$_year-$monthNum-$dayNum';

    // 2. ส่งข้อมูลไป Supabase
    await supabase.from('daily_records').insert({
      'record_date': formattedDate,
      'water_glasses': _getValue(_waterController),
      'sleep_hours': _getValue(_sleepController),
      'mood': _selectedMood,
      'detail_note': _detailController.text,
    });

    // --- จุดสำคัญที่ทำให้หน้าดำ ---
    // ตรวจสอบก่อนว่า Widget ยัง "มีตัวตน" อยู่ไหมก่อนสั่ง Navigator
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved Successfully! 🎉'),
        backgroundColor: Color(0xFF2D7D9A),
      ),
    );

    // ใช้คำสั่งนี้เพื่อกลับหน้าหลักอย่างปลอดภัย
    Navigator.of(context).pop();

  } catch (e) {
    print("❌ Supabase Error: $e");
    if (!mounted) return;
    
    // ถ้า Error ให้โชว์แจ้งเตือนแทนการปล่อยให้หน้าจอค้าง
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
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
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildHeader(context),
                _buildBigHeartIcon(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        _buildMainRecordCard(),
                        const SizedBox(height: 30),
                        _buildActionButtons(context),
                        const SizedBox(height: 40),
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

  // ====================================================================
  // MAIN COMPONENTS
  // ====================================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.greyText),
                SizedBox(width: 5),
                Text("Back", style: TextStyle(color: AppColors.greyText, fontFamily: 'Poppins-Medium', fontSize: 16)),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text("Add Record", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText)),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildGradientButton("Add", AppColors.stepsGradient, () {
            _saveRecord(); // เรียกฟังก์ชันบันทึกข้อมูล
          }),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildGradientButton("Cancel", AppColors.deleteGradient, () {
            Navigator.pop(context);
          }),
        ),
      ],
    );
  }

  // --- ส่วนอื่นๆ เหมือนเดิม ---
  Widget _buildBigHeartIcon() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, top: 15),
      child: Image.asset(
        'assets/icons/health_icon.png', 
        width: 65, height: 65, fit: BoxFit.contain,
        errorBuilder: (c, e, s) => const Icon(Icons.favorite_border, size: 60, color: Color(0xFF2D7D9A)),
      ),
    );
  }

  Widget _buildMainRecordCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryOrangeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), child: Container(color: Colors.white.withOpacity(0.1)))),
            Column(
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
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(color: Color(0xFF2D7D9A)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildDateDropdown(_days, _day, (val) => setState(() => _day = val!)),
          _buildDateDropdown(_months, _month, (val) => setState(() => _month = val!)),
          _buildDateDropdown(_years, _year, (val) => setState(() => _year = val!)),
        ],
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
      onDecrease: () {
        int val = _getValue(_waterController);
        setState(() => _waterController.text = "${val > 0 ? val - 1 : 0}");
      },
      onIncrease: () {
        int val = _getValue(_waterController);
        setState(() => _waterController.text = "${val + 1}");
      },
    );
  }

  Widget _buildSleepActivity() {
    return _buildHybridInputFieldRow(
      iconPath: 'assets/icons/sleep2_icon.png',
      title: "Sleep",
      gradient: AppColors.sleepGradient,
      controller: _sleepController,
      unit: "hours",
      onDecrease: () {
        int val = _getValue(_sleepController);
        setState(() => _sleepController.text = "${val > 0 ? val - 1 : 0}");
      },
      onIncrease: () {
        int val = _getValue(_sleepController);
        setState(() => _sleepController.text = "${val + 1}");
      },
    );
  }

  Widget _buildMoodActivity() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(gradient: AppColors.moodGradient, shape: BoxShape.circle),
            child: Image.asset('assets/icons/mood2_icon.png', width: 22, height: 22, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.sentiment_satisfied_alt, color: Colors.white, size: 22)),
          ),
          const SizedBox(width: 12),
          _buildGradientText("Mood", AppColors.moodGradient, const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16)),
          const Spacer(),
          Container(
            height: 36,
            width: 130,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMood,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.black87, fontSize: 14),
                items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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
        const Text("detail:", style: TextStyle(fontFamily: 'Poppins-Medium', color: AppColors.darkText, fontSize: 14)),
        const SizedBox(height: 5),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: _detailController,
            maxLines: null,
            style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.black87, fontSize: 14),
            decoration: const InputDecoration(border: InputBorder.none, hintText: "..."),
          ),
        ),
      ],
    );
  }

  Widget _buildHybridInputFieldRow({
    required String iconPath, required String title, required LinearGradient gradient,
    required TextEditingController controller, required String unit, 
    required VoidCallback onDecrease, required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
            child: Image.asset(iconPath, width: 22, height: 22, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.circle, color: Colors.white, size: 22)),
          ),
          const SizedBox(width: 12),
          _buildGradientText(title, gradient, const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 16)),
          const Spacer(),
          Row(
            children: [
              GestureDetector(onTap: onDecrease, child: const Icon(Icons.remove, size: 18, color: Colors.black54)),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                height: 36,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(onTap: onIncrease, child: const Icon(Icons.add, size: 18, color: Colors.black54)),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(width: 60, child: Text(unit, style: const TextStyle(color: Colors.black87, fontSize: 13, fontFamily: 'Poppins-Medium'))),
        ],
      ),
    );
  }

  Widget _buildDateDropdown<T>(List<T> items, T value, ValueChanged<T?> onChanged) {
    return Container(
      height: 35, padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), style: const TextStyle(fontSize: 13, fontFamily: 'Poppins-Medium')))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: gradient.colors.last.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Poppins-SemiBold'))),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: -20, left: -20, child: _orb(130, AppColors.primaryOrangeGradient)),
        Positioned(top: 80, right: -50, child: _orb(180, AppColors.primaryBlueGradient)),
        Positioned(bottom: 120, left: -50, child: _orb(180, AppColors.primaryBlueGradient)),
        Positioned(bottom: -20, right: -30, child: _orb(220, AppColors.primaryOrangeGradient)),
      ],
    );
  }

  Widget _orb(double size, LinearGradient gradient) {
    return Opacity(opacity: 0.5, child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient), child: ClipOval(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45), child: Container(color: Colors.transparent)))));
  }

  Widget _buildGradientText(String text, LinearGradient gradient, TextStyle style) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }
}