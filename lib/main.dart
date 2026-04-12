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

  // 2. เริ่มต้น Supabase
  await Supabase.initialize(
    url: 'https://wuolkvypfqkajglvytvl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1b2xrdnlwZnFrYWpnbHZ5dHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMzI4OTMsImV4cCI6MjA5MDcwODg5M30.YWKIv-q8XollMD4ZGxMVWX-3RzIBsUhBQNdxGN4S20s',
  );

  runApp(const HealthDayApp());
}

// 3. สร้างตัวแปรลัดสำหรับเรียกใช้ Supabase Client
final supabase = Supabase.instance.client;

class HealthDayApp extends StatelessWidget {
  const HealthDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ดึง Session ปัจจุบันจาก Supabase
    final session = supabase.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthDay',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.backgroundColor,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB347)), 
      ),
      
      // ✅ แก้ไขเงื่อนไขหน้าแรก: 
      // ถ้า session ไม่เป็น null (ล็อกอินอยู่) ให้ไป MainScreen 
      // ถ้าเป็น null (ไม่ได้ล็อกอิน) ให้ไป SplashScreen ตามเดิม
      home: session != null ? const MainScreen() : const SplashScreen(),

      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}