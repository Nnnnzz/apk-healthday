import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class HealthAdviceService {
  static final supabase = Supabase.instance.client;

  static Future<void> checkAndShowAdvice(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. เช็คก่อนว่าผู้ใช้เปิดหรือปิดรับคำแนะนำ (Default เป็น true)
    bool isEnabled = prefs.getBool('health_advice_enabled') ?? true;
    if (!isEnabled) return; // ถ้าปิดอยู่ ให้หยุดทำงานทันที

    final String today = DateTime.now().toIso8601String().split('T')[0];
    final String? lastDate = prefs.getString('last_health_tip_date');

    // 2. เช็คว่าวันนี้แสดงไปหรือยัง
    if (lastDate != today) {
      try {
        // ดึงคำแนะนำแบบสุ่มจากตารางที่เราสร้างไว้
        final List<dynamic> data = await supabase.from('health_tips').select('message');

        if (data.isNotEmpty) {
          data.shuffle();
          String randomTip = data[0]['message'];

          // 3. บันทึกลงตาราง Notifications ใน Database
          await _saveToNotification(randomTip);

          // 4. แสดง Pop-up (Dialog) และ Snackbar แจ้งเตือน
          if (context.mounted) {
            _showAdviceDialog(context, randomTip);
          }

          // 5. บันทึกวันที่ว่าวันนี้ทำงานแล้ว
          await prefs.setString('last_health_tip_date', today);
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  static Future<void> _saveToNotification(String msg) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('notifications').insert({
      'user_id': user.id,
      'message': "💡 เคล็ดลับสุขภาพ: $msg",
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ฟังก์ชันแสดง Pop-up (Dialog)
  static void _showAdviceDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.orange),
            SizedBox(width: 10),
            Text("เคล็ดลับวันนี้", style: TextStyle(fontFamily: 'Poppins-Medium')),
          ],
        ),
        content: Text(msg, style: const TextStyle(fontSize: 16, fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("รับทราบ", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}