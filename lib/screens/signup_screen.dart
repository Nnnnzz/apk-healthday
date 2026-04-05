import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

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
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstnameController.dispose();
    _lastnameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _signInAnimationController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIC
  // ==========================================
  void _onSignUpPressed() async {
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
      final String internalEmail = "$username@healthday.app";

      final AuthResponse res = await supabase.auth.signUp(
        email: internalEmail,
        password: _passwordController.text.trim(),
        data: {'username': username},
      );

      if (res.user != null) {
        await supabase.from('users').insert({
          'user_id': res.user!.id,
          'username': username,
          'email': internalEmail,
          'first_name': _firstnameController.text.trim(),
          'last_name': _lastnameController.text.trim(),
          'weight_kg': double.tryParse(_weightController.text) ?? 0.0,
          'height_cm': double.tryParse(_heightController.text) ?? 0.0,
          'points': 0,
        });

        await supabase.from('user_goals').insert({
          'user_id': res.user!.id,
          'target_steps': 8000,
          'target_water': 8,
          'target_sleep': 8,
        });

        if (!mounted) return;
        _showSnackBar('สมัครสมาชิกสำเร็จ! ✨', isError: false);
        Navigator.of(context).pop(); 
      }
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
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
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToLogin() {
    _signInAnimationController.forward().then((_) {
      Navigator.of(context).pop();
      _signInAnimationController.reverse();
    });
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ส่วนที่ 1: Header (ดันขึ้นไปด้านบนสุด)
            Expanded(
              child: SingleChildScrollView(
                child: _buildHeader(),
              ),
            ),
            
            // ส่วนที่ 2: ฟอร์มสมัครสมาชิก (วางไว้ล่างสุด)
            _buildSignUpForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SIGNUP',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF5C5454),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 15),
          Image.asset(
            'assets/images/Full_logo.png',
            width: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.health_and_safety, size: 80, color: Color(0xFF2D7D9A)),
          ),
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
          colors: [
            AppColors.primaryBlueGradient.colors.first,
            AppColors.primaryBlueGradient.colors.first.withOpacity(0.4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(controller: _usernameController, hint: 'username'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            hint: 'password',
            obscure: _obscurePassword,
            hasToggle: true,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'confirm password',
            obscure: _obscureConfirmPassword,
            hasToggle: true,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          const SizedBox(height: 12),
          _buildTextField(controller: _firstnameController, hint: 'firstname'),
          const SizedBox(height: 12),
          _buildTextField(controller: _lastnameController, hint: 'lastname'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  hint: 'weight(kg)',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  hint: 'height(cm)',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildRegisterButton(),
          const SizedBox(height: 20),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins-Medium',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account ? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkText.withOpacity(0.6),
            fontFamily: 'Poppins',
          ),
        ),
        ScaleTransition(
          scale: _signInScaleAnimation,
          child: GestureDetector(
            onTap: _navigateToLogin,
            child: Text(
              'Sign In',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlueGradient.colors.first,
                fontFamily: 'Poppins',
              ),
            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.darkText, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Poppins'),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          suffixIcon: hasToggle
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}