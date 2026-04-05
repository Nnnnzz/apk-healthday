import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../screens/main_screen.dart';

// ===== Model =====
class RewardItem {
  final String title;
  final int points;
  final String description;
  final String descriptionTh;
  final Color titleColor;
  final Color pointsColor;
  final String? previewText;
  final Color? previewTextColor;

  const RewardItem({
    required this.title,
    required this.points,
    required this.description,
    required this.descriptionTh,
    required this.titleColor,
    required this.pointsColor,
    this.previewText,
    this.previewTextColor,
  });
}

class RewardsShopPage extends StatefulWidget {
  final int userPoints;
  const RewardsShopPage({super.key, this.userPoints = 0});

  @override
  State<RewardsShopPage> createState() => _RewardsShopPageState();
}

class _RewardsShopPageState extends State<RewardsShopPage> {
  int? _expandedIndex;
  int? _pressedIndex;

  final List<RewardItem> _rewards = const [
    RewardItem(
      title: 'AT 1 HOUR',
      points: 1000,
      description: 'You can redeem your AT by using 1000 pts.',
      descriptionTh: 'สามารถแลกชั่วโมง AT ได้จาก 1000 pts และได้จำกัดแค่ 1 ครั้ง',
      titleColor: Color(0xFF151B25), 
      pointsColor: Color(0xFF151B25), 
    ),
    RewardItem(
      title: 'AT 3 HOUR',
      points: 3000,
      description: 'You can redeem your AT by using 3000 pts.',
      descriptionTh: 'สามารถแลกชั่วโมง AT ได้จาก 3000 pts และได้จำกัดแค่ 1 ครั้ง',
      titleColor: Color(0xFF00C2A8), 
      pointsColor: Color(0xFF00C2A8),
    ),
    RewardItem(
      title: 'SPECIAL TITLES',
      points: 10000,
      description: 'Unlock this special title to display under your name. Show everyone your dedication!',
      descriptionTh: 'ปลดล็อคยศพิเศษใต้ชื่อของคุณ ให้ทุกคนได้เห็นถึงความทุ่มเทของคุณ!',
      titleColor: Color(0xFFFFA726), 
      pointsColor: Color(0xFFFFA726),
      previewText: '( Legendary Healthy )',
      previewTextColor: Color(0xFFFFA726),
    ),
  ];

  void _onCardTap(int index) {
    setState(() => _expandedIndex = (_expandedIndex == index) ? null : index);
  }

  void _backToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  // ✅ ระบบแจ้งเตือนและการแลกของรางวัลจากโค้ดเดิม
  void _onPurchase(RewardItem reward) {
    if (widget.userPoints < reward.points) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Not enough points', 
            style: TextStyle(fontFamily: 'Poppins-Medium', fontWeight: FontWeight.bold)),
          content: Text(
            'You need ${reward.points} pts to redeem "${reward.title}".\nYou only have ${widget.userPoints} pts.', 
            style: const TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: reward.titleColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Redeem "${reward.title}"?', 
          style: const TextStyle(fontFamily: 'Poppins-Medium', fontWeight: FontWeight.bold)),
        content: Text('This will use ${reward.points} pts from your balance.', 
          style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: reward.titleColor, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context); // ปิด Dialog
              // แสดง SnackBar แจ้งเตือนสำเร็จ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${reward.title}" redeemed successfully!', 
                    style: const TextStyle(fontFamily: 'Poppins-Medium', color: Colors.white)),
                  backgroundColor: reward.titleColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Confirm', style: TextStyle(fontFamily: 'Poppins-Medium', fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildPointsCardDesign(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: List.generate(_rewards.length, (index) {
                    final reward = _rewards[index];
                    final isExpanded = _expandedIndex == index;
                    return _buildGlassRewardCard(reward, index, isExpanded);
                  }),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
            child: Center(
              child: Text("Rewards", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText)),
            ),
          ),
          const SizedBox(width: 60), 
        ],
      ),
    );
  }

  Widget _buildPointsCardDesign() {
    return Container(
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
                child: Text('${widget.userPoints} Pts', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.lightText, fontFamily: 'Poppins-Medium')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassRewardCard(RewardItem reward, int index, bool isExpanded) {
    final isPressed = _pressedIndex == index;
    return GestureDetector(
      onTap: () => _onCardTap(index),
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) => setState(() => _pressedIndex = null),
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.4), Colors.white.withOpacity(0.1)],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      Text(reward.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: reward.titleColor, fontFamily: 'Poppins-Medium')),
                      if (isExpanded) ...[
                        const SizedBox(height: 20),
                        Text(reward.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                        Text(reward.descriptionTh, style: const TextStyle(color: AppColors.greyText, fontSize: 13, fontFamily: 'Poppins')),
                        if (reward.previewText != null) ...[
                          const SizedBox(height: 15),
                          Text(reward.previewText!, style: TextStyle(color: reward.previewTextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: reward.titleColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            // ✅ เรียกใช้ฟังก์ชันแลกของรางวัล
                            onPressed: () => _onPurchase(reward),
                            child: const Text('Redeem Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins-Medium')),
                          ),
                        ),
                      ],
                      if (!isExpanded) ...[
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('${reward.points} pts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: reward.pointsColor, fontFamily: 'Poppins-Medium')),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryOrangeGradient, boxShadow: [BoxShadow(color: AppColors.primaryOrangeGradient.colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
      child: const Icon(Icons.add, color: Colors.white, size: 35),
    );
  }
}