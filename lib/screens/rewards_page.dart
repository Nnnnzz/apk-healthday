import 'dart:ui'; // ต้อง import ตัวนี้สำหรับ ImageFilter (ทำเอฟเฟกต์กระจก)
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/background_wrapper.dart';

// ===== Model =====
class RewardItem {
  final String title;
  final int points;
  final String description;
  final String descriptionTh;
  final Color titleColor;
  final Color pointsColor; // เพิ่มสีของตัวหนังสือ Points
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

// ===== Page =====
class RewardsShopPage extends StatefulWidget {
  final int userPoints;

  const RewardsShopPage({super.key, this.userPoints = 0});

  @override
  State<RewardsShopPage> createState() => _RewardsShopPageState();
}

class _RewardsShopPageState extends State<RewardsShopPage> {
  int? _expandedIndex;
  int? _pressedIndex;

  // ปรับสีและข้อมูลให้ตรงกับในรูป
  final List<RewardItem> _rewards = const [
    RewardItem(
      title: 'AT 1 HOUR',
      points: 1000,
      description: 'you can redeem your AT by using 1000 pts.',
      descriptionTh: 'สามารถแลกชั่วโมง AT ได้จาก 1000 pts และได้จำกัดแค่ 1 ครั้ง.',
      titleColor: Color(0xFF151B25), // สีดำเข้ม
      pointsColor: Color(0xFF151B25), 
    ),
    RewardItem(
      title: 'AT 3 HOUR',
      points: 3000,
      description: 'you can redeem your AT by using 3000 pts.',
      descriptionTh: 'สามารถแลกชั่วโมง AT ได้จาก 3000 pts และได้จำกัดแค่ 1 ครั้ง.',
      titleColor: Color(0xFF00C2A8), // สีเขียวมิ้นต์
      pointsColor: Color(0xFF00C2A8),
    ),
    RewardItem(
      title: 'SPECIAL TITLES',
      points: 10000,
      description: 'Unlock this special title to display under your name. Show everyone your dedication!',
      descriptionTh: 'ปลดล็อคยศพิเศษได้ชื่อของคุณ ให้ทุกคนได้เห็นถึงความทุ่มเทของคุณ!',
      titleColor: Color(0xFFFFA726), // สีส้มตามรูป
      pointsColor: Color(0xFFFFA726),
      previewText: '( Legendary Healthy )',
      previewTextColor: Color(0xFFFFA726),
    ),
  ];

  void _onCardTap(int index) {
    setState(() {
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });
  }

  void _onPurchase(RewardItem reward) {
    if (widget.userPoints < reward.points) {
      // โชว์แจ้งเตือนแต้มไม่พอ
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Not enough points', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
          content: Text('You need ${reward.points} pts to redeem "${reward.title}".\nYou only have ${widget.userPoints} pts.', style: const TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFF00C2A8), fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // โชว์แจ้งเตือนยืนยันการซื้อ
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Redeem "${reward.title}"?', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text('This will use ${reward.points} pts from your balance.', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C2A8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${reward.title}" redeemed successfully!', style: const TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: const Color(0xFF00C2A8),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirm', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent, // ให้ทะลุเห็น BackgroundWrapper
        body: SafeArea(
          child: Column(
            children: [
              // ===== Custom App Bar (Back & Rewards) =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.grey),
                          const SizedBox(width: 5),
                          Text(
                            'Back',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Rewards',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF8D7B7B), fontFamily: 'Poppins'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 60), // บาลานซ์ช่องว่างฝั่งขวา
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ===== Reward Cards List =====
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: _rewards.length,
                  itemBuilder: (context, index) {
                    final reward = _rewards[index];
                    final isExpanded = _expandedIndex == index;
                    return _buildGlassRewardCard(reward, index, isExpanded);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // สร้าง Widget แบบกระจกฝ้า (Glassmorphism)
  Widget _buildGlassRewardCard(RewardItem reward, int index, bool isExpanded) {
    final isPressed = _pressedIndex == index;

    return GestureDetector(
      onTap: () => _onCardTap(index),
      onTapDown: (_) => setState(() => _pressedIndex = index),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => _pressedIndex = null);
      },
      onTapCancel: () => setState(() => _pressedIndex = null),
      child: AnimatedScale(
        scale: isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // เงาบางๆ นอกกล่องกระจก
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // ความเบลอของกระจก
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65), // ความใสของสีขาว
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5), // ขอบเงาสะท้อนกระจก
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ===== Title =====
                        Center(
                          child: Text(
                            reward.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32, // ฟอนต์ใหญ่เหมือนในรูป
                              fontWeight: FontWeight.w900, // หนาพิเศษ
                              color: reward.titleColor,
                              fontFamily: 'Poppins',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        // ===== ถ้ากดขยาย (Expanded) จะโชว์ส่วนนี้ =====
                        if (isExpanded) ...[
                          const SizedBox(height: 25),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.black87, height: 1.5),
                                    children: [
                                      TextSpan(text: '${reward.description}\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: '( ${reward.descriptionTh} )'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],

                        // ===== ถ้าไม่ได้ขยาย (Collapsed) จะมีระยะห่างให้ Points ลงไปอยู่ล่างๆ =====
                        if (!isExpanded) const SizedBox(height: 10),

                        // ===== Points =====
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${reward.points} pts',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: reward.pointsColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),

                        // ===== ปุ่ม Purchase (จะโชว์ตอนขยาย) =====
                        if (isExpanded) ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _onPurchase(reward),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C2A8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Purchase',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}