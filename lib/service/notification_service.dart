import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones(); // สำคัญมากสำหรับการตั้งเวลา
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  // ✅ ฟังก์ชัน: ตั้งเวลาแจ้งเตือนล่วงหน้า (เช่น เตือนทุกๆ 1 ชม. ในช่วงเวลาที่กำหนด)
  static Future<void> scheduleWaterReminders() async {
    // ลบอันเก่าออกก่อนกันซ้ำ
    await _notifications.cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails('water_id', 'Water Reminder', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );

    // วนลูปตั้งเวลาล่วงหน้า 8 ครั้ง (เช่น ทุก 1 ชั่วโมง ตั้งแต่ตอนนี้)
    for (int i = 1; i <= 8; i++) {
      await _notifications.zonedSchedule(
        i, // id ของการแจ้งเตือน
        'ดื่มน้ำกันเถอะ! 💧',
        'อย่าลืมดื่มน้ำให้ครบตามเป้าหมายนะ',
        tz.TZDateTime.now(tz.local).add(Duration(hours: i)), // อีก i ชั่วโมงข้างหน้า
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // เตือนแม้ตอนประหยัดพลังงาน
      );
    }
  }

  // ✅ ฟังก์ชัน: ยกเลิกการเตือนทั้งหมด (ใช้ตอนกดปิดใน Setting)
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}