import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import '../constants/app_colors.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;
  
  // เปลี่ยนมารับข้อมูล Dynamic จาก Database
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // 1. ดึงข้อมูลจากตาราง notifications ของ User คนนี้
  Future<void> _fetchNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false); // เรียงจากใหม่ไปเก่า

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. ฟังก์ชันปัดลบทีละอัน
  Future<void> _deleteNotification(dynamic id, int index) async {
    try {
      // เอาออกจากหน้าจอก่อนเพื่อความสมูท
      setState(() => _notifications.removeAt(index));
      // ลบจากฐานข้อมูลจริงๆ
      await supabase.from('notifications').delete().eq('notification_id', id);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // 3. ฟังก์ชันลบทั้งหมด (Clear All)
  Future<void> _clearAllNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      setState(() => _notifications.clear());
      await supabase.from('notifications').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeader(context),
            const SizedBox(height: 10),
            
            // แสดงปุ่ม Clear All ก็ต่อเมื่อมี Notification
            if (_notifications.isNotEmpty) _buildClearButton(), 

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryOrangeGradient.colors.first))
                  : _notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 5, bottom: 100),
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            return _buildDismissibleItem(item, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildGradientText(String text, LinearGradient gradient, TextStyle style) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style),
    );
  }

  // MAIN COMPONENTS
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
              child: Text("Notifications", style: TextStyle(fontSize: 20, fontFamily: 'Poppins-Medium', color: AppColors.greyText)),
            ),
          ),
          const SizedBox(width: 60), 
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _clearAllNotifications, // เรียกฟังก์ชันลบทั้งหมดจาก Database
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.deleteGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.deleteGradient.colors.last.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Poppins-Medium'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDismissibleItem(Map<String, dynamic> item, int index) {
    return Dismissible(
      key: Key(item['notification_id'].toString()), // ใช้ ID จาก Database เป็น Key
      direction: DismissDirection.endToStart, 
      onDismissed: (direction) => _deleteNotification(item['notification_id'], index), // สั่งลบ
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.only(right: 25),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          gradient: AppColors.deleteGradient,
          borderRadius: BorderRadius.circular(15), 
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
      ),
      child: _buildNotificationCard(item),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    // จัด Format เวลาที่ดึงมาจากฐานข้อมูล
    DateTime createdAt = DateTime.parse(item['created_at']).toLocal();
    String formattedTime = "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} - ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryBlueGradient, 
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['message'] ?? '', // ดึงข้อความจาก Database
                  style: const TextStyle(fontFamily: 'Poppins-Medium', fontSize: 15, color: AppColors.darkText),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedTime, // แสดงเวลาที่แปลงแล้ว
                  style: const TextStyle(fontFamily: 'Poppins-Medium', color: AppColors.greyText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, color: Colors.grey, size: 50),
          SizedBox(height: 10),
          Text(
            "No notifications",
            style: TextStyle(fontFamily: 'Poppins-Medium', color: AppColors.greyText, fontSize: 16),
          ),
        ],
      ),
    );
  }
}