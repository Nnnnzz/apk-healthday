import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../widgets/background_wrapper.dart';
import '../screens/main_screen.dart';
import 'notification_page.dart';
import 'rewards_page.dart';
import 'points_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  // สร้างตัวแปรเก็บข้อมูล 3 ส่วน
  Map<String, dynamic>? userData;
  Map<String, dynamic>? userGoal;
  Map<String, dynamic>? dailyRecord;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // ฟังก์ชันดึงข้อมูลแบบครบวงจร
  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final String todayDate = DateTime.now().toIso8601String().split('T')[0];

        // ✅ เพิ่ม .limit(1) ทุกอัน เพื่อป้องกัน Error กรณี Database มีข้อมูลซ้ำ
        final responses = await Future.wait([
          supabase
              .from('users')
              .select()
              .eq('user_id', user.id)
              .limit(1)
              .maybeSingle(),
          supabase
              .from('user_goals')
              .select()
              .eq('user_id', user.id)
              .limit(1)
              .maybeSingle(),
          supabase
              .from('daily_records')
              .select()
              .eq('user_id', user.id)
              .eq('record_date', todayDate)
              .limit(1)
              .maybeSingle(),
        ]);

        // ❌ เอา Navigator ตรงนี้ออกไปแล้ว (ห้ามใส่ในหน้านี้เด็ดขาด)

        if (mounted) {
          setState(() {
            userData = responses[0];
            userGoal = responses[1];
            dailyRecord = responses[2];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrangeGradient.colors.first,
          ),
        ),
      );
    }
    // ==========================================
    // คำนวณข้อมูลที่จะแสดงบนหน้าจอ
    // ==========================================

    int currentSteps = dailyRecord?['steps'] ?? 0;
    int targetSteps = userGoal?['target_steps'] ?? 8000;
    double stepsProgress = targetSteps > 0
        ? (currentSteps / targetSteps).clamp(0.0, 1.0)
        : 0.0;

    int currentWater = dailyRecord?['water_glasses'] ?? 0;
    int targetWater = userGoal?['target_water'] ?? 8;
    double waterProgress = targetWater > 0
        ? (currentWater / targetWater).clamp(0.0, 1.0)
        : 0.0;

    int currentSleep = dailyRecord?['sleep_hours'] ?? 0;
    String currentMood = dailyRecord?['mood'] ?? 'none';
    String displayMood = currentMood == 'none'
        ? 'None'
        : currentMood[0].toUpperCase() + currentMood.substring(1);

    return BackgroundWrapper(
      child: RefreshIndicator(
        onRefresh: _fetchUserData,
        color: AppColors.primaryOrangeGradient.colors.first,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader3Layers(context),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Goals",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins-Medium',
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildGoalCard(
                          iconPath: 'assets/icons/activity_icon.png',
                          title: "$currentSteps",
                          total: "/$targetSteps Steps",
                          titleGradient: AppColors.stepsGradient,
                          progress: stepsProgress,
                          progressGradient: AppColors.stepsGradient,
                        ),
                        const SizedBox(width: 15),
                        _buildGoalCard(
                          iconPath: 'assets/icons/water_icon.png',
                          title: "$currentWater",
                          total: "/$targetWater Glasses",
                          titleGradient: AppColors.waterGradient,
                          progress: waterProgress,
                          progressGradient: AppColors.waterGradient,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Body Status",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins-Medium',
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            iconPath: 'assets/icons/sleep_icon.png',
                            text: "Sleep: $currentSleep hrs",
                            textColor: AppColors.sleepGradient.colors.last,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStatusCard(
                            iconPath: 'assets/icons/mood_icon.png',
                            text: "Mood: $displayMood",
                            textColor: AppColors.moodGradient.colors.first,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Points",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins-Medium',
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildActionButton(
                      iconPath: 'assets/icons/rewards_icon.png',
                      title: "Redeem rewards",
                      titleGradient: AppColors.primaryOrangeGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RewardsShopPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildActionButton(
                      iconPath: 'assets/icons/point_icon.png',
                      title: "Your points",
                      titleGradient: AppColors.primaryOrangeGradient,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PointPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader3Layers(BuildContext context) {
    // ✅ ดึงชื่อมาโชว์ ถ้ามีข้อมูลจะแสดงชื่อจริง ถ้าไม่มีแสดง Guest
    final username = userData?['username'] ?? "Guest";
    final fullName =
        "${userData?['first_name'] ?? ''} ${userData?['last_name'] ?? ''}"
            .trim();
    final displayName = fullName.isEmpty ? "Welcome!" : fullName;

    final height = userData?['height_cm']?.toString() ?? "-";
    final weight = userData?['weight_kg']?.toString() ?? "-";
    final points = userData?['points']?.toString() ?? "0";

    return Container(
      width: double.infinity,
      height: 250,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryOrangeGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 25, 
              right: 20,
              child: _blobHelper(125, AppColors.moodGradient),
            ),
            Positioned(
              top: -25, 
              left: -20, 
              child: _blobHelper(150,AppColors.moodGradient,), 
            ),
             Positioned(
              bottom: 0, 
              left: -10,
              child: _blobHelper(50,AppColors.moodGradient,),
            ),
             Positioned(
              bottom: 0, 
              right: -10, 
              child: _blobHelper(70,AppColors.moodGradient,),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.glassBorderColor,
                      width: 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                        Colors.white.withOpacity(0.03),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                left: 25,
                right: 25,
                bottom: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 80,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryBlueGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: FittedBox(
                          child: Text(
                            "$points Pts",
                            style: const TextStyle(
                              color: AppColors.lightText,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationPage(),
                          ),
                        ),
                        child: Image.asset(
                          'assets/icons/notifications_icon.png',
                          width: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        child: const Icon(
                          Icons.person_outline,
                          size: 55,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Height : $height cm   Weight : $weight kg",
                              style: const TextStyle(
                                color: AppColors.greyText,
                                fontSize: 14,
                              ),
                            ),
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
    return _buildGlassBox(
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
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
