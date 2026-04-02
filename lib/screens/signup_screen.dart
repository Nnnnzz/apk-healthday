import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late AnimationController _signInAnimationController;
  late Animation<double> _signInScaleAnimation;

  @override
  void initState() {
    super.initState();
    _signInAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _signInScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _signInAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // ล้าง Controller ทั้งหมดเพื่อคืน Memory
    for (var controller in [
      _usernameController, _passwordController, _confirmPasswordController,
      _firstnameController, _lastnameController, _weightController, _heightController
    ]) {
      controller.dispose();
    }
    _signInAnimationController.dispose();
    super.dispose();
  }

  void _onSignUpPressed() async {
    // 1. Validation เบื้องต้น
    if (_isAnyFieldEmpty()) {
      _showSnackBar('กรุณากรอกข้อมูลให้ครบทุกช่อง', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('รหัสผ่านไม่ตรงกัน', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      // สร้างอีเมลจำลองจาก username สำหรับ Supabase Auth
      final String internalEmail = "$username@healthday.app";

      // 2. ขั้นตอนการ Auth (สมัครสมาชิก)
      final AuthResponse res = await supabase.auth.signUp(
        email: internalEmail,
        password: _passwordController.text.trim(),
        data: {'username': username}, // เก็บ username ไว้ใน metadata
      );

      if (res.user != null) {
        // 3. บันทึกข้อมูลลงตาราง public.users 
        // หมายเหตุ: ตรงนี้ต้องรอให้ Auth สำเร็จก่อนเพื่อให้ได้ user_id (UUID)
        await supabase.from('users').insert({
          'user_id': res.user!.id, // สำคัญมาก: เชื่อม UUID จาก Auth
          'username': username,
          'email': internalEmail,
          'first_name': _firstnameController.text.trim(),
          'last_name': _lastnameController.text.trim(),
          'weight_kg': double.tryParse(_weightController.text) ?? 0.0,
          'height_cm': double.tryParse(_heightController.text) ?? 0.0,
          'points': 0, // ค่าเริ่มต้น
        });

        // 4. สร้างเป้าหมายเริ่มต้น (Optional - ตามตาราง user_goals ที่คุณมี)
        await supabase.from('user_goals').insert({
          'user_id': res.user!.id,
          'target_steps': 8000,
          'target_water': 8,
          'target_sleep': 8,
        });

        if (!mounted) return;
        _showSnackBar('สมัครสมาชิกสำเร็จ! ✨', isError: false);
        
        // กลับไปหน้า Login
        Navigator.of(context).pop(); 
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } on PostgrestException catch (e) {
      _showSnackBar('Database Error: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isAnyFieldEmpty() {
    return _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstnameController.text.isEmpty ||
        _lastnameController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI ส่วนที่เหลือ (เหมือนเดิมตามดีไซน์ของคุณ) ---
  
  void _navigateToLogin() {
    _signInAnimationController.forward().then((_) {
      Navigator.of(context).pop();
      _signInAnimationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildSignUpForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text('SIGNUP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF5C5454))),
          const SizedBox(height: 20),
          Image.asset('assets/images/Full_logo.png', width: 250, height: 180, fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.health_and_safety, size: 80, color: Color(0xFF2D7D9A))),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
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
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 40),
      child: Column(
        children: [
          _buildTextField(controller: _usernameController, hint: 'username'),
          const SizedBox(height: 15),
          _buildTextField(controller: _passwordController, hint: 'password', obscure: _obscurePassword, hasToggle: true, 
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
          const SizedBox(height: 15),
          _buildTextField(controller: _confirmPasswordController, hint: 'confirm password', obscure: _obscureConfirmPassword, hasToggle: true,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
          const SizedBox(height: 15),
          _buildTextField(controller: _firstnameController, hint: 'firstname'),
          const SizedBox(height: 15),
          _buildTextField(controller: _lastnameController, hint: 'lastname'),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _weightController, hint: 'weight(kg)', keyboardType: TextInputType.number)),
              const SizedBox(width: 15),
              Expanded(child: _buildTextField(controller: _heightController, hint: 'height(cm)', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 40),
          _buildRegisterButton(),
          const SizedBox(height: 25),
          _buildLoginLink(),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _onSignUpPressed,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          gradient: AppColors.primaryOrangeGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Register', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Already have an account ? ', style: TextStyle(fontSize: 14, color: AppColors.darkText.withOpacity(0.6))),
        ScaleTransition(
          scale: _signInScaleAnimation,
          child: GestureDetector(
            onTap: _navigateToLogin,
            child: Text('Sign In', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlueGradient.colors.first)),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool hasToggle = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.darkText, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          suffixIcon: hasToggle
              ? IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey, size: 20), onPressed: onToggle)
              : null,
        ),
      ),
    );
  }
}