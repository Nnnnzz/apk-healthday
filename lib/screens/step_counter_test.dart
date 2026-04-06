import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterTest extends StatefulWidget {
  const StepCounterTest({super.key});

  @override
  State<StepCounterTest> createState() => _StepCounterTestState();
}

class _StepCounterTestState extends State<StepCounterTest> {
  late Stream<StepCount> _stepCountStream;
  String _stepsToday = '0';
  String _status = 'กำลังรอข้อมูล...';

  int _savedBaselineSteps = 0; // ก้าวตั้งต้นของวัน
  String _savedDate = ""; // วันที่บันทึกก้าวตั้งต้นล่าสุด

  @override
  void initState() {
    super.initState();
    initPedometer();
  }

  Future<void> initPedometer() async {
    // 1. เด้ง Pop-up ขออนุญาตผู้ใช้ (ถ้าเคยอนุญาตแล้วมันจะไม่เด้งซ้ำ)
    if (await Permission.activityRecognition.request().isGranted) {
      
      // 2. โหลดข้อมูล "ก้าวตั้งต้น" และ "วันที่" จากความจำของเครื่อง (SharedPreferences)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _savedBaselineSteps = prefs.getInt('baseline_steps') ?? 0;
      _savedDate = prefs.getString('saved_date') ?? "";

      // 3. เริ่มดึงข้อมูลจากเซ็นเซอร์มือถือแบบ Real-time
      _stepCountStream = Pedometer.stepCountStream;
      _stepCountStream.listen(onStepCount).onError(onStepCountError);
      
      setState(() => _status = 'เซ็นเซอร์กำลังทำงาน 🏃‍♂️');
    } else {
      setState(() => _status = 'ผู้ใช้ไม่อนุญาตให้เข้าถึงข้อมูล ❌');
    }
  }

  // ฟังก์ชันนี้จะถูกเรียกซ้ำๆ อัตโนมัติ ทุกครั้งที่เราก้าวเดิน
  void onStepCount(StepCount event) async {
    int currentTotalSteps = event.steps; // เลขก้าวรวมทั้งหมดในมือถือ (เช่น 150,000)
    String todayStr = DateTime.now().toIso8601String().split('T')[0]; // วันที่วันนี้ YYYY-MM-DD

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // เช็คว่า วันที่บันทึกไว้ ตรงกับ วันนี้หรือไม่?
    if (_savedDate != todayStr) {
      // ถ้าย้อนกลับมาเปิดแอปในวันใหม่! ให้เซฟ "ก้าวตั้งต้น" ของวันใหม่
      _savedBaselineSteps = currentTotalSteps;
      _savedDate = todayStr;
      await prefs.setInt('baseline_steps', _savedBaselineSteps);
      await prefs.setString('saved_date', _savedDate);
    }

    // คำนวณก้าวของวันนี้ = ก้าวปัจจุบัน - ก้าวตั้งต้น
    int stepsToday = currentTotalSteps - _savedBaselineSteps;

    // ถ้าค่าติดลบ (มือถืออาจจะรีสตาร์ทเครื่อง) ให้รีเซ็ต baseline ใหม่
    if (stepsToday < 0) {
      _savedBaselineSteps = currentTotalSteps;
      await prefs.setInt('baseline_steps', _savedBaselineSteps);
      stepsToday = 0;
    }

    setState(() {
      _stepsToday = stepsToday.toString();
    });
  }

  void onStepCountError(error) {
    setState(() {
      _status = 'เซ็นเซอร์มีปัญหา: $error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบระบบนับก้าว'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            const Text('วันนี้คุณเดินไปแล้ว', style: TextStyle(fontSize: 20)),
            Text(
              _stepsToday,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Text('ก้าว', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}