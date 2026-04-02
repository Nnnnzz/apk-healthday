import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // 1. ตรวจสอบให้แน่ใจว่า Binding ของ Flutter พร้อมทำงาน
  WidgetsFlutterBinding.ensureInitialized();

  // 2. เริ่มต้น Supabase (แก้ไข URL ให้เป็นรูปแบบที่ถูกต้อง)
  await Supabase.initialize(
    url: 'https://wuolkvypfqkajglvytvl.supabase.co', // ใส่ https:// และ .supabase.co เพิ่มเข้าไป
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1b2xrdnlwZnFrYWpnbHZ5dHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzI4OTMsImV4cCI6MjA5MDcwODg5M30.YWKIv-q8XollMD4ZGxMVWX-3RzIBsUhBQNdxGN4S20s',
  );

  runApp(const HealthDayApp());
}

// 3. สร้างตัวแปรลัดสำหรับเรียกใช้ Supabase Client ได้จากทุกที่ในแอป
final supabase = Supabase.instance.client;

class HealthDayApp extends StatelessWidget {
  const HealthDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthDay',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.backgroundColor,
        useMaterial3: true,
        // กำหนดสีพื้นฐานให้เข้ากับธีมแอป
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB347)), 
      ),
      // กำหนดหน้าแรก
      home: const SplashScreen(),
      // ลงทะเบียนเส้นทาง (Routes) เพื่อให้ใช้ Navigator.pushNamed ได้ง่าย
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}