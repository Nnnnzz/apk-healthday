import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. นำเข้า Supabase
import '../constants/app_colors.dart';
import '../widgets/background_wrapper.dart';
import 'notification_page.dart';
import 'rewards_page.dart';
import 'points_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 2. สร้างตัวแปรเก็บข้อมูล
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // 3. เรียกฟังก์ชันดึงข้อมูลเมื่อเปิดหน้า
  }

  // 4. ฟังก์ชันดึงข้อมูลจาก Supabase
  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // ดึงข้อมูลจากตาราง users โดยใช้ ID ของคนที่ login อยู่
        final data = await supabase
            .from('users')
            .select()
            .eq('user_id', user.id)
            .single();

        setState(() {
          userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // แสดง Loading ระหว่างรอข้อมูล
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BackgroundWrapper(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader3Layers(context),
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Goals", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.darkText)),
                  const SizedBox(height: 15),
                  // ส่วนนี้ยังใช้ Mock Data อยู่ (สามารถทำวิธีเดียวกันดึงจาก daily_records ได้)
                  Row(
                    children: [
                      _buildGoalCard(
                        iconPath: 'assets/icons/activity_icon.png',
                        title: "1000",
                        total: "/10000 Steps",
                        titleGradient: AppColors.stepsGradient,
                        progress: 0.1,
                        progressGradient: AppColors.stepsGradient,
                      ),
                      const SizedBox(width: 15),
                      _buildGoalCard(
                        iconPath: 'assets/icons/water_icon.png',
                        title: "5",
                        total: "/8 Glasses",
                        titleGradient: AppColors.waterGradient,
                        progress: 0.625,
                        progressGradient: AppColors.waterGradient,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text("Body Status", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.darkText)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildStatusCard(iconPath: 'assets/icons/sleep_icon.png', text: "Sleep: 8 hours", textColor: AppColors.sleepGradient.colors.last)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatusCard(iconPath: 'assets/icons/mood_icon.png', text: "Mood: Happy", textColor: AppColors.moodGradient.colors.first)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text("Points", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.darkText)),
                  const SizedBox(height: 15),
                  _buildActionButton(iconPath: 'assets/icons/rewards_icon.png', title: "Redeem rewards", titleGradient: AppColors.primaryOrangeGradient, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsShopPage()))),
                  const SizedBox(height: 15),
                  _buildActionButton(iconPath: 'assets/icons/point_icon.png', title: "Your points", titleGradient: AppColors.primaryOrangeGradient, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PointPage()))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader3Layers(BuildContext context) {
    // 5. นำข้อมูลมาใช้งานใน UI
    final username = userData?['username'] ?? "Guest";
    final fullName = "${userData?['first_name'] ?? 'Firstname'} ${userData?['last_name'] ?? 'Lastname'}";
    final height = userData?['height_cm']?.toString() ?? "-";
    final weight = userData?['weight_kg']?.toString() ?? "-";
    final points = userData?['points']?.toString() ?? "0";

    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryOrangeGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
        child: Stack(
          children: [
            // Blob Backgrounds...
            _blobHelper(180, AppColors.moodGradient), // ตย. blob 
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorderColor, width: 1.0),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white.withOpacity(0.1), Colors.transparent, Colors.white.withOpacity(0.03)],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 80, height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(20)),
                        child: FittedBox(
                          child: Text("$points Pts", style: const TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())),
                        child: Image.asset('assets/icons/notifications_icon.png', width: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundImage: AssetImage('assets/images/defaultprofile.png'),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: const TextStyle(color: AppColors.greyText, fontSize: 14)),
                            Text(fullName, style: const TextStyle(color: AppColors.greyText, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text("Height : $height cm   Weight : $weight kg", style: const TextStyle(color: AppColors.greyText, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blobHelper(double size, LinearGradient gradient) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
    );
  }

  Widget _buildGoalCard({
    required String iconPath,
    required String title,
    required String total,
    required LinearGradient titleGradient,
    required double progress,
    required LinearGradient progressGradient,
  }) {
    return Expanded(
      child: _buildGlassBox(
        height: 170,
        radius: 20,
        blur: 4.0,
        gradientColors: [Colors.white.withOpacity(0.2), Colors.transparent],
        backgroundLayer: Positioned.fill(
          child: Center(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    progressGradient.colors.first.withOpacity(0.25),
                    progressGradient.colors.first.withOpacity(0.0),
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(iconPath, width: 32),
              const Spacer(),
              Center(
                child: _buildGradientText(
                  title,
                  titleGradient,
                  const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins-Medium',
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  total,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText.withOpacity(0.5),
                    fontFamily: 'Poppins-Medium',
                  ),
                ),
              ),
              const Spacer(),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: progressGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String iconPath,
    required String text,
    required Color textColor,
  }) {
    return Expanded(
      child: _buildGlassBox(
        height: 75,
        stackAlignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Image.asset(iconPath, width: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Poppins-Medium',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String iconPath,
    required String title,
    required LinearGradient titleGradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _buildGlassBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 20,
          ),
          child: Row(
            children: [
              Image.asset(iconPath, width: 35),
              const SizedBox(width: 20),
              _buildGradientText(
                title,
                titleGradient,
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins-Medium',
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: titleGradient.colors.last,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // HELPER FUNCTIONS (ฟังก์ชันตัวช่วยที่แยกออกมาเพื่อลดโค้ดซ้ำ)

  // 1. ฟังก์ชันทำฟอนต์ไล่สี
  Widget _buildGradientText(String text, LinearGradient gradient, TextStyle style) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }

  // 2. ฟังก์ชันทำกล่องกระจก (ใช้ร่วมกันได้ทุกการ์ด)
  Widget _buildGlassBox({
    double? height,
    double radius = 15.0,
    double blur = 5.0,
    List<Color>? gradientColors,
    Alignment stackAlignment = Alignment.topLeft,
    Widget? backgroundLayer,
    required Widget child,
  }) {
    final colors = gradientColors ?? [AppColors.glassColor, Colors.transparent];
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: stackAlignment,
          children: [
            if (backgroundLayer != null) backgroundLayer,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.glassBorderColor,
                      width: 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}