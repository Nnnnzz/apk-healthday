import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // เพิ่มการ import
import '../constants/app_colors.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชัน Login จริงที่เชื่อมกับ Supabase
  void _onLoginPressed() async {
  final username = _emailController.text.trim(); // รับค่า tt จากช่อง username
  final password = _passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    _showSnackBar('กรุณากรอก Username และ Password');
    return;
  }

  setState(() => _isLoading = true);

  try {
    // 🪄 เทคนิค: เติมหางให้อัตโนมัติในโค้ด
    final String internalEmail = "$username@healthday.app"; 

    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: internalEmail, // ส่งตัวที่เติมหางแล้วไปให้ Supabase
      password: password,
    );

    if (mounted && response.user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    }
  } on AuthException catch (error) {
    // ถ้าขึ้น Invalid login credentials แสดงว่า username หรือ password ผิด
    _showSnackBar('Username หรือ Password ไม่ถูกต้อง');
  } catch (error) {
    _showSnackBar('เกิดข้อผิดพลาด กรุณาลองใหม่');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    // โครงสร้าง UI เดิมของคุณ (ตัดมาเฉพาะส่วนที่มีการแก้ไข onTap)
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView( // เพิ่มป้องกันคีย์บอร์ดบังหน้าจอ
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                _buildHeader(),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ส่วนประกอบ UI (เหมือนเดิมแต่ใส่ Logic เข้าไป) ---

  Widget _buildHeader() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('LOGIN', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 40),
          Image.asset('assets/images/Full_logo.png', width: 250, height: 200, fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.health_and_safety, size: 80, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBlueGradient.colors.first, AppColors.primaryBlueGradient.colors.first.withOpacity(0.4)],
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
      ),
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
      child: Column(
        children: [
          _buildInputField(controller: _emailController, hintText: 'Username', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passwordController,
            hintText: 'Password',
            isPassword: true,
            obscureText: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 40),
          _buildLoginButton(),
          const SizedBox(height: 20),
          _buildSignUpLink(),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onLoginPressed,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: AppColors.primaryOrangeGradient,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account ? ", style: TextStyle(color: AppColors.darkText.withOpacity(0.6))),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
          child: Text('Sign Up', style: TextStyle(color: AppColors.primaryBlueGradient.colors.first, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility), onPressed: onToggle)
              : null,
        ),
      ),
    );
  }
}